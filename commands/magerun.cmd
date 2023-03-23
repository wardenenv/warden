#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

WARDEN_ENV_PATH="$(locateEnvPath)" || exit $?
loadEnvConfig "${WARDEN_ENV_PATH}" || exit $?
assertDockerRunning

if [[ "${WARDEN_ENV_TYPE}" != "magento2" && "${WARDEN_ENV_TYPE}" != "magento1" ]]; then
		warning "This command is only working for Magento 2 or Magento 1 projects" && exit 1
fi

## allow return codes from sub-process to bubble up normally
trap '' ERR

"${WARDEN_DIR}/bin/warden" cli mr "${WARDEN_PARAMS[@]}" "$@"
