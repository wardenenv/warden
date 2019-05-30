#!/usr/bin/env bash
[[ ! ${WARDEN_COMMAND} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!" && exit 1

pushd "${WARDEN_DIR}" >/dev/null
docker-compose -p warden -f docker/docker-compose.yml stop ${WARDEN_PARAMS[@]}
