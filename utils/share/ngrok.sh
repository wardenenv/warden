#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

# shellcheck disable=SC2034  # read by shareProviderScope from the file, never sourced
SHARE_PROVIDER_SCOPE=project
# shellcheck disable=SC2034  # read by shareProviderEnvPrefix from the file, never sourced
SHARE_PROVIDER_ENV_PREFIX=WARDEN_NGROK_

unset WARDEN_NGROK_AUTHTOKEN
loadEnvFile "${WARDEN_HOME_DIR}/.env" "WARDEN_NGROK_"
export WARDEN_NGROK_AUTHTOKEN="${WARDEN_NGROK_AUTHTOKEN:-}"

function shareProviderRequireConfig() {
  if [[ -z "${WARDEN_NGROK_AUTHTOKEN}" ]]; then
    fatal "WARDEN_NGROK_AUTHTOKEN is not set. Get a token at https://dashboard.ngrok.com/get-started/your-authtoken and set WARDEN_NGROK_AUTHTOKEN in ${WARDEN_HOME_DIR}/.env."
  fi
}

function shareProviderPrepare() {
  WARDEN_SHARE_NGROK_URL_ARG=""
  if [[ -n "${WARDEN_NGROK_DOMAIN:-}" ]]; then
    assertHostname "${WARDEN_NGROK_DOMAIN}" "WARDEN_NGROK_DOMAIN"
    WARDEN_SHARE_NGROK_URL_ARG="--url=${WARDEN_NGROK_DOMAIN}"
  fi

  export WARDEN_SHARE_NGROK_URL_ARG
}

function shareProviderUrl() {
  if [[ -n "${WARDEN_NGROK_DOMAIN:-}" ]]; then
    assertHostname "${WARDEN_NGROK_DOMAIN}" "WARDEN_NGROK_DOMAIN"
    echo "https://${WARDEN_NGROK_DOMAIN}"
    return 0
  fi

  local url
  url="$("${WARDEN_BIN}" env logs share 2>/dev/null \
    | grep -oE 'https://[a-z0-9.-]+\.ngrok(-free)?\.(app|dev|io)' \
    | tail -1)"

  [[ -z "${url}" ]] && return 1

  echo "${url}"
}

function shareProviderStatus() {
  echo "Upstream: http://${WARDEN_SHARE_UPSTREAM:-nginx}:80"

  if [[ -n "${WARDEN_NGROK_AUTHTOKEN}" ]]; then
    echo "Credential: present"
  else
    echo "Credential: missing"
  fi

  local container_id container_status=""
  container_id="$("${WARDEN_BIN}" env ps -q share 2>/dev/null | head -1)"
  if [[ -n "${container_id}" ]]; then
    container_status="$(docker inspect --format '{{.State.Status}}' "${container_id}" 2>/dev/null)" || container_status=""
  fi

  echo "Container: ${container_status:-not running}"
}

function shareProviderCommand() {
  return 64
}
