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

function assertHostname() {
  local value="${1}" varname="${2}"
  local hostnameRegex='^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)+$'

  if [[ ! "${value}" =~ $hostnameRegex ]]; then
    fatal "${varname} must be a valid hostname (got '${value}')."
  fi
}

## reads the scope declaration without sourcing the provider, so an unusable
## provider can still be listed in an error message
function shareProviderScope() {
  local providerFile="${1}" declaration=""

  declaration="$(grep -m1 -E '^SHARE_PROVIDER_SCOPE=' "${providerFile}" 2>/dev/null || true)"
  declaration="${declaration%$'\r'}"
  declaration="${declaration#SHARE_PROVIDER_SCOPE=}"
  declaration="${declaration%%[[:space:]]*}"
  declaration="${declaration%%#*}"
  declaration="${declaration%\"}"
  declaration="${declaration#\"}"
  declaration="${declaration%\'}"
  declaration="${declaration#\'}"

  echo "${declaration:-global}"
}

## provider-owned project variables; empty when the provider has none
function shareProviderEnvPrefix() {
  local providerFile="${1}" declaration=""

  declaration="$(grep -m1 -E '^SHARE_PROVIDER_ENV_PREFIX=' "${providerFile}" 2>/dev/null || true)"
  declaration="${declaration%$'\r'}"
  declaration="${declaration#SHARE_PROVIDER_ENV_PREFIX=}"
  declaration="${declaration%%[[:space:]]*}"
  declaration="${declaration%%#*}"
  declaration="${declaration%\"}"
  declaration="${declaration#\"}"
  declaration="${declaration%\'}"
  declaration="${declaration#\'}"

  if [[ ! "${declaration}" =~ ^[A-Z0-9_]*$ ]]; then
    fatal "SHARE_PROVIDER_ENV_PREFIX in ${providerFile} must be an uppercase identifier prefix (got '${declaration}')."
  fi

  echo "${declaration}"
}

function shareAvailableProviders() {
  local scope="${1:-}" providers="" candidate name
  for candidate in "${WARDEN_DIR}"/utils/share/*.sh; do
    [[ -f "${candidate}" ]] || continue

    name="${candidate##*/}"
    name="${name%.sh}"

    if [[ -n "${scope}" ]] && [[ "$(shareProviderScope "${candidate}")" != "${scope}" ]]; then
      continue
    fi

    providers="${providers}${name} "
  done

  echo "${providers% }"
}

function assertShareProviderName() {
  local name="${1}" selector="${2}" scope="${3}"

  if [[ ! "${name}" =~ ^[a-z0-9-]+$ ]] || [[ ! -f "${WARDEN_DIR}/utils/share/${name}.sh" ]]; then
    fatal "Unknown share provider '${name}' in ${selector}. Available ${scope}-scope providers: $(shareAvailableProviders "${scope}")"
  fi

  if [[ "$(shareProviderScope "${WARDEN_DIR}/utils/share/${name}.sh")" != "${scope}" ]]; then
    local other="global" otherSelector="WARDEN_SHARE_PROVIDER in ${WARDEN_HOME_DIR}/.env"
    if [[ "${scope}" == "global" ]]; then
      other="project"
      otherSelector="WARDEN_SHARE in the project .env"
    fi

    fatal "Share provider '${name}' is ${other}-scope and cannot be selected with ${selector}. Select it with ${otherSelector}. Available ${scope}-scope providers: $(shareAvailableProviders "${scope}")"
  fi
}

function loadShareConfig() {
  unset WARDEN_SHARE_PROVIDER
  loadEnvFile "${WARDEN_HOME_DIR}/.env" "WARDEN_SHARE_"
  WARDEN_SHARE_PROVIDER="${WARDEN_SHARE_PROVIDER:-}"
  export WARDEN_SHARE_PROVIDER

  if [[ -n "${WARDEN_SHARE_PROVIDER}" ]]; then
    assertShareProviderName "${WARDEN_SHARE_PROVIDER}" "WARDEN_SHARE_PROVIDER" "global"

    # shellcheck source=/dev/null
    source "${WARDEN_DIR}/utils/share/${WARDEN_SHARE_PROVIDER}.sh"
  fi
}

## mirrors the WARDEN_VARNISH default commands/env.cmd applies per environment
## type, so share.cmd and env.cmd agree on where the agent forwards
function resolveShareUpstream() {
  local varnish="${WARDEN_VARNISH:-}"

  if [[ -z "${varnish}" ]] && [[ "${WARDEN_ENV_TYPE:-}" == "magento2" ]]; then
    varnish=1
  fi

  if [[ "${varnish}" == "1" ]]; then
    echo "varnish"
    return 0
  fi

  echo "nginx"
}

function loadProjectShareConfig() {
  WARDEN_SHARE="${WARDEN_SHARE:-}"
  [[ -z "${WARDEN_SHARE}" ]] && return 0

  assertShareProviderName "${WARDEN_SHARE}" "WARDEN_SHARE" "project"

  WARDEN_SHARE_UPSTREAM="$(resolveShareUpstream)"

  if [[ "${WARDEN_SHARE_UPSTREAM}" == "nginx" ]] && [[ "${WARDEN_NGINX:-1}" == "0" ]]; then
    fatal "WARDEN_SHARE needs nginx or varnish enabled in the project (WARDEN_NGINX=1 or WARDEN_VARNISH=1)."
  fi

  export WARDEN_SHARE WARDEN_SHARE_UPSTREAM

  # shellcheck source=/dev/null
  source "${WARDEN_DIR}/utils/share/${WARDEN_SHARE}.sh"
}

function shareProviderPrepare() {
  return 0
}

function shareProviderRequireConfig() {
  return 0
}

function shareProviderUrl() {
  return 1
}

function shareProviderStatus() {
  return 0
}

function shareProviderCommand() {
  return 64
}

function shareDomains() {
  docker ps --filter "label=dev.warden.share.domain" --format '{{.Label "dev.warden.share.domain"}}' 2>/dev/null | sort -u
}

function regenerateShareConfig() {
  if [[ -n "${WARDEN_SHARE_PROVIDER:-}" ]]; then
    shareProviderRegenerateConfig
  fi
}
