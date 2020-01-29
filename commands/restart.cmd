#!/usr/bin/env bash
[[ ! ${WARDEN_COMMAND} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!" && exit 1

source "${WARDEN_DIR}/utils/install.sh"
assertWardenInstall

pushd "${WARDEN_DIR}" >/dev/null
docker-compose -p warden --env-file "${WARDEN_HOME_DIR}/.env" \
  -f docker/docker-compose.yml restart "${WARDEN_PARAMS[@]}" "$@"
