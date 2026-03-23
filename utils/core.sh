#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

## global service containers to be connected with the project docker network
## Only non-disablable services should be listed here. Optioanl services should be handled in getPeeredServices
DOCKER_PEERED_SERVICES=("traefik" "tunnel" "mailhog")

## messaging functions
function warning {
  >&2 printf "\033[33mWARNING\033[0m: $@\n"
}

function error {
  >&2 printf "\033[31mERROR\033[0m: $@\n"
}

function fatal {
  error "$@"
  exit -1
}

function version {
  echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }';
}

## determines if value is present in an array; returns 0 if element is present
## in array, otherwise returns 1
##
## usage: containsElement <needle> <haystack>
##
function containsElement {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

## verify docker is running
function assertDockerRunning {
  if ! docker system info >/dev/null 2>&1; then
    fatal "Docker does not appear to be running. Please start Docker."
  fi
}

## use this to add services that can be opted in/out of
function getPeeredServices {
  local services=("${DOCKER_PEERED_SERVICES[@]}")

  if [[ "${WARDEN_PHPMYADMIN_ENABLE}" == 1 ]]; then
    services+=("phpmyadmin")
  fi

  echo "${services[@]}"
}

## methods to peer global services requiring network connectivity with project networks
function connectPeeredServices {
  enabledServices=($(getPeeredServices))
  for svc in ${enabledServices[@]}; do
    echo "Connecting ${svc} to $1 network"
    (docker network connect "$1" ${svc} 2>&1| grep -v 'already exists in network') || true
  done
}

function disconnectPeeredServices {
  enabledServices=($(getPeeredServices))
  for svc in ${enabledServices[@]}; do
    echo "Disconnecting ${svc} from $1 network"
    (docker network disconnect "$1" ${svc} 2>&1| grep -v 'is not connected') || true
  done
}
function regeneratePMAConfig() {
  if [[ -f "${WARDEN_HOME_DIR}/.env" ]]; then
    # Recheck PMA since old versions of .env may not have WARDEN_PHPMYADMIN_ENABLE setting
    eval "$(grep "^WARDEN_PHPMYADMIN_ENABLE" "${WARDEN_HOME_DIR}/.env")"
    WARDEN_PHPMYADMIN_ENABLE="${WARDEN_PHPMYADMIN_ENABLE:-1}"
  fi
  if [[ "${WARDEN_PHPMYADMIN_ENABLE}" == 1 ]]; then
    >&2 echo "Regenerating phpMyAdmin configuration..."
    pma_config_file="${WARDEN_HOME_DIR}/etc/phpmyadmin/config.user.inc.php"
    mkdir -p "$(dirname "$pma_config_file")"
    {
      echo "<?php"
      echo "\$i = 1;"
      for container_id in $(docker ps -q --filter "name=mysql" --filter "name=mariadb" --filter "name=db"); do
        container_name=$(docker inspect --format '{{.Name}}' "${container_id}" | sed 's#^/##')
        container_ip=$(docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "${container_id}")
        MYSQL_ROOT_PASSWORD=$(docker exec "${container_id}" printenv | grep MYSQL_ROOT_PASSWORD | awk -F '=' '{print $2}')
        echo "\$cfg['Servers'][\$i]['host'] = '${container_ip}';"
        echo "\$cfg['Servers'][\$i]['auth_type'] = 'config';"
        echo "\$cfg['Servers'][\$i]['user'] = 'root';"
        echo "\$cfg['Servers'][\$i]['password'] = '${MYSQL_ROOT_PASSWORD}';"
        echo "\$cfg['Servers'][\$i]['AllowNoPassword'] = true;"
        echo "\$cfg['Servers'][\$i]['hide_db'] = '(information_schema|performance_schema|mysql|sys)';"
        echo "\$cfg['Servers'][\$i]['verbose'] = '${container_name}';"
        echo "\$i++;"
      done
    } > "${pma_config_file}"
    >&2 echo "phpMyAdmin configuration regenerated."
  fi
}

function regenerateCloudflaredConfig() {
  if [[ -f "${WARDEN_HOME_DIR}/.env" ]]; then
    eval "$(grep "^WARDEN_CLOUDFLARED_TUNNEL_ID" "${WARDEN_HOME_DIR}/.env" | tr -d '\r')"
  fi

  if [[ -z "${WARDEN_CLOUDFLARED_TUNNEL_ID:-}" ]]; then
    return 0
  fi

  ## find credentials file (either credentials.json or <uuid>.json)
  local credentials_file=""
  if [[ -f "${WARDEN_HOME_DIR}/etc/cloudflared/${WARDEN_CLOUDFLARED_TUNNEL_ID}.json" ]]; then
    credentials_file="/home/nonroot/.cloudflared/${WARDEN_CLOUDFLARED_TUNNEL_ID}.json"
  elif [[ -f "${WARDEN_HOME_DIR}/etc/cloudflared/credentials.json" ]]; then
    credentials_file="/home/nonroot/.cloudflared/credentials.json"
  else
    warning "Cloudflared credentials file not found. Run 'warden cf create' first."
    return 0
  fi

  >&2 echo "Regenerating cloudflared configuration..."
  local config_dir="${WARDEN_HOME_DIR}/etc/cloudflared"
  mkdir -p "${config_dir}"

  local config_file="${config_dir}/config.yml"
  {
    echo "tunnel: ${WARDEN_CLOUDFLARED_TUNNEL_ID}"
    echo "credentials-file: ${credentials_file}"
    echo ""
    echo "ingress:"

    for domain in $(docker ps --filter "label=dev.warden.cf.domain" --format '{{.Label "dev.warden.cf.domain"}}' 2>/dev/null | sort -u); do
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
  } > "${config_file}"

  >&2 echo "Cloudflared configuration regenerated."

  ## restart (or start if stopped) the cloudflared container if it exists
  docker restart cloudflared 2>/dev/null || true
}
