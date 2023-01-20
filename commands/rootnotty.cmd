#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

WARDEN_ENV_PATH="$(locateEnvPath)" || exit $?
loadEnvConfig "${WARDEN_ENV_PATH}" || exit $?

## set defaults for this command which can be overridden either using exports in the user
## profile or setting them in the .env.warden configuration on a per-project basis
WARDEN_ENV_SHELL_CONTAINER=${WARDEN_ENV_SHELL_CONTAINER:-php-fpm}

## allow return codes from sub-process to bubble up normally
trap '' ERR

"${WARDEN_DIR}/bin/warden" env exec -u root -T "${WARDEN_ENV_SHELL_CONTAINER}" \
     "${WARDEN_PARAMS[@]}" "$@"
