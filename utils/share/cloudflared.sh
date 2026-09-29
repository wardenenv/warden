#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

# shellcheck disable=SC2034  # read by shareProviderScope from the file, never sourced
SHARE_PROVIDER_SCOPE=global
# shellcheck disable=SC2034  # read by shareProviderEnvPrefix from the file, never sourced
SHARE_PROVIDER_ENV_PREFIX=WARDEN_CLOUDFLARED_

unset WARDEN_CLOUDFLARED_TUNNEL_ID
loadEnvFile "${WARDEN_HOME_DIR}/.env" "WARDEN_IMAGE_REPOSITORY|WARDEN_CLOUDFLARED_"

CLOUDFLARED_DIR="${WARDEN_HOME_DIR}/etc/cloudflared"
CLOUDFLARED_IMAGE="${WARDEN_IMAGE_REPOSITORY:-docker.io/wardenenv}/cloudflared:latest"

function shareProviderIsConfigured() {
  if [[ -z "${WARDEN_CLOUDFLARED_TUNNEL_ID:-}" ]]; then
    return 1
  fi

  if [[ ! -f "${CLOUDFLARED_DIR}/${WARDEN_CLOUDFLARED_TUNNEL_ID}.json" ]] \
    && [[ ! -f "${CLOUDFLARED_DIR}/credentials.json" ]]
  then
    return 1
  fi

  return 0
}

function shareProviderComposeFile() {
  if shareProviderIsConfigured; then
    echo "${WARDEN_DIR}/docker/docker-compose.share-cloudflared.yml"
  fi
}

function shareProviderPreflight() {
  if ! shareProviderIsConfigured; then
    warning "Share provider is 'cloudflared' but no tunnel is configured."
    warning "Run 'warden share login' and 'warden share create' to set one up."
  elif [[ ! -f "${CLOUDFLARED_DIR}/config.yml" ]]; then
    warning "Cloudflared tunnel ID is set but config.yml is missing."
    warning "Run 'warden share create' or 'warden share update' to generate configuration."
  fi

  return 0
}

function shareProviderRegenerateConfig() {
  loadEnvFile "${WARDEN_HOME_DIR}/.env" "WARDEN_CLOUDFLARED_"

  if [[ -z "${WARDEN_CLOUDFLARED_TUNNEL_ID:-}" ]]; then
    return 0
  fi

  ## credentials are written either as <uuid>.json or credentials.json depending
  ## on the cloudflared version that created the tunnel
  local credentials_file=""
  if [[ -f "${CLOUDFLARED_DIR}/${WARDEN_CLOUDFLARED_TUNNEL_ID}.json" ]]; then
    credentials_file="/home/nonroot/.cloudflared/${WARDEN_CLOUDFLARED_TUNNEL_ID}.json"
  elif [[ -f "${CLOUDFLARED_DIR}/credentials.json" ]]; then
    credentials_file="/home/nonroot/.cloudflared/credentials.json"
  else
    warning "Cloudflared credentials file not found. Run 'warden share create' first."
    return 0
  fi

  mkdir -p "${CLOUDFLARED_DIR}"

  local rendered
  rendered="$(mktemp "${CLOUDFLARED_DIR}/config.yml.XXXXXX")"
  chmod 644 "${rendered}"
  {
    echo "tunnel: ${WARDEN_CLOUDFLARED_TUNNEL_ID}"
    echo "credentials-file: ${credentials_file}"
    echo ""
    echo "ingress:"

    shareDomains | while IFS= read -r domain; do
      echo "  - hostname: ${domain}"
      echo "    service: https://traefik"
      echo "    originRequest:"
      echo "      noTLSVerify: true"
      echo "  - hostname: \"*.${domain}\""
      echo "    service: https://traefik"
      echo "    originRequest:"
      echo "      noTLSVerify: true"
    done

    echo "  - service: http_status:404"
  } > "${rendered}"

  ## every project's `env up|down|start|stop` lands here; restarting the shared
  ## agent when nothing changed would drop the tunnel for unrelated projects
  if cmp -s "${rendered}" "${CLOUDFLARED_DIR}/config.yml"; then
    rm -f "${rendered}"
    return 0
  fi

  >&2 echo "Regenerating cloudflared configuration..."
  mv "${rendered}" "${CLOUDFLARED_DIR}/config.yml"
  >&2 echo "Cloudflared configuration regenerated."

  docker restart cloudflared 2>/dev/null || true
}

function shareProviderStatus() {
  if [[ -n "${WARDEN_CLOUDFLARED_TUNNEL_ID:-}" ]]; then
    echo "Tunnel ID: ${WARDEN_CLOUDFLARED_TUNNEL_ID}"
  else
    echo "Tunnel ID: (not configured)"
  fi

  local container_status
  container_status="$(docker inspect --format '{{.State.Status}}' cloudflared 2>/dev/null)" || container_status=""
  echo "Container: ${container_status:-not running}"
}

function shareProviderCommand() {
  local subcommand="${1:-}"
  shift || true

  case "${subcommand}" in
    login)
      mkdir -p "${CLOUDFLARED_DIR}"
      echo "Opening browser for Cloudflare authentication..."
      docker run --rm -it \
        -v "${CLOUDFLARED_DIR}:/home/nonroot/.cloudflared" \
        "${CLOUDFLARED_IMAGE}" \
        tunnel login

      if [[ ! -f "${CLOUDFLARED_DIR}/cert.pem" ]]; then
        error "Login failed. No cert.pem found."
        return 1
      fi

      echo "Login successful. cert.pem saved to ${CLOUDFLARED_DIR}/"
      echo "Next step: run 'warden share create' to create a tunnel."
      ;;
    create)
      if [[ ! -f "${CLOUDFLARED_DIR}/cert.pem" ]]; then
        fatal "Not authenticated. Run 'warden share login' first."
      fi

      local tunnel_name="${1:-warden}"
      echo "Creating tunnel '${tunnel_name}'..."

      local create_output
      create_output=$(docker run --rm \
        -v "${CLOUDFLARED_DIR}:/home/nonroot/.cloudflared" \
        "${CLOUDFLARED_IMAGE}" \
        tunnel create "${tunnel_name}" 2>&1)

      echo "${create_output}"

      ## a UUID is [0-9a-f-] only, which is safe to use unescaped in the sed below
      local tunnel_id
      tunnel_id=$(echo "${create_output}" | grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | head -1)

      if [[ -z "${tunnel_id}" ]]; then
        fatal "Failed to extract tunnel ID from output."
      fi

      if [[ -f "${WARDEN_HOME_DIR}/.env" ]] && grep -q "^WARDEN_CLOUDFLARED_TUNNEL_ID" "${WARDEN_HOME_DIR}/.env"; then
        sed -i.bak "s/^WARDEN_CLOUDFLARED_TUNNEL_ID=.*/WARDEN_CLOUDFLARED_TUNNEL_ID=${tunnel_id}/" "${WARDEN_HOME_DIR}/.env"
        rm -f "${WARDEN_HOME_DIR}/.env.bak"
      else
        echo "WARDEN_CLOUDFLARED_TUNNEL_ID=${tunnel_id}" >> "${WARDEN_HOME_DIR}/.env"
      fi

      if ! grep -q "^WARDEN_SHARE_PROVIDER" "${WARDEN_HOME_DIR}/.env" 2>/dev/null; then
        echo "WARDEN_SHARE_PROVIDER=cloudflared" >> "${WARDEN_HOME_DIR}/.env"
      fi

      regenerateShareConfig

      echo ""
      echo "Tunnel '${tunnel_name}' created with ID: ${tunnel_id}"
      echo "Run 'warden svc up' to start the tunnel."
      ;;
    delete)
      if [[ ! -f "${CLOUDFLARED_DIR}/cert.pem" ]]; then
        fatal "Not authenticated. Run 'warden share login' first."
      fi

      if [[ -z "${WARDEN_CLOUDFLARED_TUNNEL_ID:-}" ]]; then
        fatal "No tunnel configured. Nothing to delete."
      fi

      echo "Deleting tunnel ${WARDEN_CLOUDFLARED_TUNNEL_ID}..."

      docker stop cloudflared 2>/dev/null || true

      docker run --rm \
        -v "${CLOUDFLARED_DIR}:/home/nonroot/.cloudflared" \
        "${CLOUDFLARED_IMAGE}" \
        tunnel delete "${WARDEN_CLOUDFLARED_TUNNEL_ID}" || true

      if [[ -f "${WARDEN_HOME_DIR}/.env" ]]; then
        sed -i.bak '/^WARDEN_CLOUDFLARED_TUNNEL_ID/d' "${WARDEN_HOME_DIR}/.env"
        rm -f "${WARDEN_HOME_DIR}/.env.bak"
      fi

      ## cert.pem is the Cloudflare account credential, not the tunnel's; keep it
      rm -f "${CLOUDFLARED_DIR}/${WARDEN_CLOUDFLARED_TUNNEL_ID}.json"
      rm -f "${CLOUDFLARED_DIR}/credentials.json"
      rm -f "${CLOUDFLARED_DIR}/config.yml"

      echo "Tunnel deleted. cert.pem preserved for future use."
      ;;
    logout)
      if [[ -n "${WARDEN_CLOUDFLARED_TUNNEL_ID:-}" ]]; then
        warning "A tunnel is still configured (ID: ${WARDEN_CLOUDFLARED_TUNNEL_ID})."
        warning "Run 'warden share delete' first to remove it from Cloudflare,"
        warning "or the tunnel will become orphaned."
        echo ""
        local confirm
        read -r -p "Continue with logout anyway? [y/N] " confirm
        [[ "${confirm}" != [yY]* ]] && return 0
      fi

      echo "Cleaning up cloudflared configuration..."

      docker stop cloudflared 2>/dev/null || true

      if [[ -f "${WARDEN_HOME_DIR}/.env" ]]; then
        sed -i.bak '/^WARDEN_CLOUDFLARED_TUNNEL_ID/d' "${WARDEN_HOME_DIR}/.env"
        rm -f "${WARDEN_HOME_DIR}/.env.bak"
      fi

      rm -rf "${CLOUDFLARED_DIR}"

      echo "Cloudflared configuration removed."
      ;;
    *)
      return 64
      ;;
  esac
}
