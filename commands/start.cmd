#!/usr/bin/env bash
[[ ! ${WARDEN_COMMAND} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

source "${WARDEN_DIR}/utils/install.sh"
assertWardenInstall

pushd "${WARDEN_HOME_DIR}" >/dev/null
docker-compose -p warden -f "${WARDEN_DIR}/docker/docker-compose.yml" start "${WARDEN_PARAMS[@]}" "$@"
