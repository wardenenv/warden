#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

# shellcheck disable=SC2034  # read by shareProviderScope from the file, never sourced
SHARE_PROVIDER_SCOPE=project
# shellcheck disable=SC2034  # read by shareProviderEnvPrefix from the file, never sourced
SHARE_PROVIDER_ENV_PREFIX=WARDEN_TAILSCALE_

unset WARDEN_TAILSCALE_AUTHKEY
loadEnvFile "${WARDEN_HOME_DIR}/.env" "WARDEN_TAILSCALE_"
export WARDEN_TAILSCALE_AUTHKEY="${WARDEN_TAILSCALE_AUTHKEY:-}"

function shareProviderRequireConfig() {
  if [[ -z "${WARDEN_TAILSCALE_AUTHKEY}" ]]; then
    fatal "WARDEN_TAILSCALE_AUTHKEY is not set. Create a reusable auth key at https://login.tailscale.com/admin/settings/keys and set WARDEN_TAILSCALE_AUTHKEY in ${WARDEN_HOME_DIR}/.env."
  fi
}

function shareProviderPrepare() {
  WARDEN_TAILSCALE_FUNNEL="${WARDEN_TAILSCALE_FUNNEL:-0}"
  if [[ "${WARDEN_TAILSCALE_FUNNEL}" != "0" ]] && [[ "${WARDEN_TAILSCALE_FUNNEL}" != "1" ]]; then
    fatal "WARDEN_TAILSCALE_FUNNEL must be 0 or 1 (got '${WARDEN_TAILSCALE_FUNNEL}')."
  fi

  ## WARDEN_ENV_NAME is never validated by Warden, so the derived default is
  ## sanitized into a DNS label rather than rejected
  if [[ -n "${WARDEN_TAILSCALE_HOSTNAME:-}" ]]; then
    assertDnsLabel "${WARDEN_TAILSCALE_HOSTNAME}" "WARDEN_TAILSCALE_HOSTNAME"
  else
    WARDEN_TAILSCALE_HOSTNAME="$(echo "${WARDEN_ENV_NAME}" \
      | tr '[:upper:]' '[:lower:]' \
      | sed -E 's/[^a-z0-9-]+/-/g; s/^-+//; s/-+$//' \
      | cut -c1-63 \
      | sed -E 's/-+$//')"
    [[ -z "${WARDEN_TAILSCALE_HOSTNAME}" ]] && WARDEN_TAILSCALE_HOSTNAME="warden"
  fi

  WARDEN_SHARE_TAILSCALE_HOSTNAME="${WARDEN_TAILSCALE_HOSTNAME}"
  export WARDEN_SHARE_TAILSCALE_HOSTNAME

  local allow_funnel="false"
  [[ "${WARDEN_TAILSCALE_FUNNEL}" == "1" ]] && allow_funnel="true"

  local warden_dir="${WARDEN_ENV_PATH}/.warden"
  mkdir -p "${warden_dir}"

  local rendered
  rendered="$(mktemp "${warden_dir}/share-tailscale.json.XXXXXX")"
  chmod 644 "${rendered}"
  printf '{"TCP":{"443":{"HTTPS":true}},"Web":{"${TS_CERT_DOMAIN}:443":{"Handlers":{"/":{"Proxy":"http://%s:80"}}}},"AllowFunnel":{"${TS_CERT_DOMAIN}:443":%s}}' \
    "${WARDEN_SHARE_UPSTREAM}" "${allow_funnel}" > "${rendered}"

  if cmp -s "${rendered}" "${warden_dir}/share-tailscale.json"; then
    rm -f "${rendered}"
    return 0
  fi

  mv "${rendered}" "${warden_dir}/share-tailscale.json"
}

function shareProviderUrl() {
  local dnsname
  dnsname="$("${WARDEN_BIN}" env exec -T share tailscale status --json 2>/dev/null \
    | grep -oE '"DNSName": *"[^"]+"' | head -1 | sed -E 's/.*"DNSName": *"//; s/"$//; s/\.$//')"

  [[ -z "${dnsname}" ]] && return 1

  echo "https://${dnsname}"
}

function shareProviderStatus() {
  echo "Upstream: http://${WARDEN_SHARE_UPSTREAM:-nginx}:80"

  if [[ -n "${WARDEN_TAILSCALE_AUTHKEY}" ]]; then
    echo "Credential: present"
  else
    echo "Credential: missing"
  fi

  local funnel_state="off"
  [[ "${WARDEN_TAILSCALE_FUNNEL:-0}" == "1" ]] && funnel_state="on"
  echo "Funnel: ${funnel_state}"

  local container_id container_status=""
  container_id="$("${WARDEN_BIN}" env ps -q share 2>/dev/null | head -1)"
  if [[ -n "${container_id}" ]]; then
    container_status="$(docker inspect --format '{{.State.Status}}' "${container_id}" 2>/dev/null)" || container_status=""
  fi

  echo "Container: ${container_status:-not running}"

  if [[ "${funnel_state}" == "on" ]]; then
    echo "Funnel needs the 'funnel' node attribute in your tailnet policy (ports 443, 8443, 10000)."
  fi
}

function shareProviderCommand() {
  return 64
}
