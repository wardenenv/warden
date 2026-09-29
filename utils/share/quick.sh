#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

# shellcheck disable=SC2034  # read by shareProviderScope from the file, never sourced
SHARE_PROVIDER_SCOPE=project

function shareProviderUrl() {
  local url
  url="$("${WARDEN_BIN}" env logs share 2>/dev/null \
    | grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' \
    | tail -1)"

  [[ -z "${url}" ]] && return 1

  echo "${url}"
}

function shareProviderStatus() {
  echo "Upstream: http://${WARDEN_SHARE_UPSTREAM:-nginx}:80"

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
