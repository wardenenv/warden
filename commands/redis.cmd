#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

WARDEN_ENV_PATH="$(locateEnvPath)" || exit $?
loadEnvConfig "${WARDEN_ENV_PATH}" || exit $?
assertDockerRunning

if [[ ${WARDEN_REDIS:-1} -eq 0 ]]; then
  fatal "Redis environment is not used (WARDEN_REDIS=0)."
fi

if [[ "${WARDEN_PARAMS[0]}" == "help" ]]; then
  $WARDEN_BIN redis --help || exit $? && exit $?
fi

## load connection information for the redis service
REDIS_CONTAINER=$($WARDEN_BIN env ps -q redis)
if [[ ! ${REDIS_CONTAINER} ]]; then
    fatal "No container found for redis service."
fi

"$WARDEN_BIN" env exec redis redis-cli "${WARDEN_PARAMS[@]}" "$@"
