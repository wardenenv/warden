#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

WARDEN_ENV_PATH="$(locateEnvPath)" || exit $?
loadEnvConfig "${WARDEN_ENV_PATH}" || exit $?
assertDockerRunning

if [[ ${WARDEN_REIDS:-1} -eq 0 ]]; then
  fatal "Redis environment is not used (WARDEN_REDIS=1)."
fi

if [[ "${WARDEN_PARAMS[0]}" == "help" ]]; then
  warden redis --help || exit $? && exit $?
fi

## load connection information for the mysql service
REDIS_CONTAINER=$(warden env ps -q redis)
if [[ ! ${REDIS_CONTAINER} ]]; then
    fatal "No container found for db service."
fi

if (( ${#WARDEN_PARAMS[@]} == 0 )); then
    "${WARDEN_DIR}/bin/warden" env exec redis sh -c "redis-cli"
else
    "${WARDEN_DIR}/bin/warden" env exec -T redis sh -c "redis-cli ${WARDEN_PARAMS}"
fi