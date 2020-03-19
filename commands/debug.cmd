#!/usr/bin/env bash
[[ ! ${WARDEN_COMMAND} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

source "${WARDEN_DIR}/utils/env.sh"
WARDEN_ENV_PATH="$(locateEnvPath)" || exit $?
loadEnvConfig "${WARDEN_ENV_PATH}" || exit $?

## set defaults for this command which can be overriden either using exports in the user
## profile or setting them in the .env configuration on a per-project basis
WARDEN_ENV_DEBUG_COMMAND=${WARDEN_ENV_DEBUG_COMMAND:-bash}
WARDEN_ENV_DEBUG_CONTAINER=${WARDEN_ENV_DEBUG_CONTAINER:-php-debug}
WARDEN_ENV_DEBUG_HOST=${WARDEN_ENV_DEBUG_HOST:-}

if [[ ${WARDEN_ENV_DEBUG_HOST} == "" ]]; then
    if [[ $OSTYPE =~ ^darwin ]]; then
        WARDEN_ENV_DEBUG_HOST=host.docker.internal
    else
        WARDEN_ENV_DEBUG_HOST=$(
            docker container inspect $(warden env ps -q php-debug) \
                --format '{{range .NetworkSettings.Networks}}{{println .Gateway}}{{end}}' | head -n1
        )
    fi
fi

## simply allow the return code from sub-command to bubble up per normal
trap '' ERR

"${WARDEN_DIR}/bin/warden" env exec -e "XDEBUG_REMOTE_HOST=${WARDEN_ENV_DEBUG_HOST}" \
    "${WARDEN_ENV_DEBUG_CONTAINER}" "${WARDEN_ENV_DEBUG_COMMAND}" "${WARDEN_PARAMS[@]}" "$@"
