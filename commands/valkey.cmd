#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

WARDEN_ENV_PATH="$(locateEnvPath)" || exit $?
loadEnvConfig "${WARDEN_ENV_PATH}" || exit $?
assertDockerRunning

if [[ ${WARDEN_VALKEY:-1} -eq 0 ]]; then
  fatal "Valkey environment is not used (WARDEN_VALKEY=0)."
fi

if [[ "${WARDEN_PARAMS[0]}" == "help" ]]; then
  $WARDEN_BIN valkey --help || exit $? && exit $?
fi

## load connection information for the Valkey service
VALKEY_CONTAINER=$($WARDEN_BIN env ps -q valkey)
if [[ ! ${VALKEY_CONTAINER} ]]; then
    fatal "No container found for Valkey service."
fi

"$WARDEN_BIN" env exec valkey valkey-cli "${WARDEN_PARAMS[@]}" "$@"
