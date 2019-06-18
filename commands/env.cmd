#!/usr/bin/env bash
[[ ! ${WARDEN_COMMAND} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!" && exit 1

source "${WARDEN_DIR}/utils/env.sh"
WARDEN_ENV_PATH="$(locateEnvPath)" || exit $?
loadEnvConfig "${WARDEN_ENV_PATH}" || exit $?

if (( ${#WARDEN_PARAMS[@]} == 0 )); then
    echo -e "\033[33mThis command has required params which are passed through to docker-compose, please use --help for details."
    exit 1
fi

## anything not caught above is simply passed through to docker-compose to orchestrate
docker-compose \
    --project-directory "${WARDEN_ENV_PATH}" \
    -p "${WARDEN_ENV_NAME}" \
    -f "${WARDEN_DIR}/environments/${WARDEN_ENV_TYPE}.yml" \
    "${WARDEN_PARAMS[@]}" "$@"
