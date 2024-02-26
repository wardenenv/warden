#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

WARDEN_ENV_PATH="$(locateEnvPath)" || exit $?
loadEnvConfig "${WARDEN_ENV_PATH}" || exit $?
assertDockerRunning

#if [[ ${WARDEN_DB:-1} -eq 0 ]]; then
#  fatal "Database environment is not used (WARDEN_DB=0)."
#fi

if (( ${#WARDEN_PARAMS[@]} == 0 )) || [[ "${WARDEN_PARAMS[0]}" == "help" ]]; then
  $WARDEN_BIN db --help || exit $? && exit $?
fi

## load connection information for the database service
DB_CONTAINER=$($WARDEN_BIN env ps -q db)
if [[ ! ${DB_CONTAINER} ]]; then
    fatal "No container found for db service."
fi

DB_CMD="mysql"
case ${WARDEN_DB_SYSTEM:-mysql} in
    pgsql|postgres|postgresql)
        DB_CMD="postgres"
        ;;
esac

source "${WARDEN_DIR}/commands/db.${DB_CMD}.cmd"
