#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

if [[ -f "${WARDEN_HOME_DIR}/.env" ]]; then
    eval "$(cat "${WARDEN_HOME_DIR}/.env" | sed 's/\r$//g' | grep "^WARDEN_ENV_SHELL_COMMAND")"
fi

WARDEN_ENV_PATH="$(locateEnvPath)" || exit $?
loadEnvConfig "${WARDEN_ENV_PATH}" || exit $?

## set defaults for this command which can be overridden either using exports in the user
## profile or setting them in the .env.warden configuration on a per-project basis
WARDEN_ENV_SHELL_COMMAND=${USE_SHELL:-${WARDEN_ENV_SHELL_COMMAND:-bash}}
WARDEN_ENV_SHELL_CONTAINER=${WARDEN_ENV_SHELL_CONTAINER:-php-fpm}

## allow return codes from sub-process to bubble up normally
trap '' ERR

"${WARDEN_DIR}/bin/warden" env exec -u root "${WARDEN_ENV_SHELL_CONTAINER}" \
    "${WARDEN_ENV_SHELL_COMMAND}" "${WARDEN_PARAMS[@]}" "$@"
