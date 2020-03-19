#!/usr/bin/env bash
[[ ! ${WARDEN_COMMAND} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

source "${WARDEN_DIR}/utils/env.sh"
WARDEN_ENV_PATH="$(locateEnvPath)" || exit $?
loadEnvConfig "${WARDEN_ENV_PATH}" || exit $?

## set defaults for this command which can be overriden either using exports in the user
## profile or setting them in the .env configuration on a per-project basis
WARDEN_ENV_SHELL_COMMAND=${WARDEN_ENV_SHELL_COMMAND:-bash}
WARDEN_ENV_SHELL_CONTAINER=${WARDEN_ENV_SHELL_CONTAINER:-php-fpm}

## simply allow the return code from sub-command to bubble up per normal
trap '' ERR

"${WARDEN_DIR}/bin/warden" env exec "${WARDEN_ENV_SHELL_CONTAINER}" \
    "${WARDEN_ENV_SHELL_COMMAND}" "${WARDEN_PARAMS[@]}" "$@"
