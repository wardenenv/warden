#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

WARDEN_ENV_PATH="$(locateEnvPath)" || exit $?
loadEnvConfig "${WARDEN_ENV_PATH}" || exit $?
assertDockerRunning

if [[ "${WARDEN_ENV_TYPE}" != "magento2" ]]; then
		warning "This command is only working for Magento 2 projects" && exit 1
fi

## allow return codes from sub-process to bubble up normally
trap '' ERR

echo "Fixing filesystem permissions..."

if [ -z  "${WARDEN_PARAMS[@]}" ]; then
  "${WARDEN_DIR}/bin/warden" clinotty find var vendor pub/static pub/media app/etc \( -type f -or -type d \) -exec chmod u+w {} +;
  "${WARDEN_DIR}/bin/warden" clinotty chmod u+x bin/magento
else
  "${WARDEN_DIR}/bin/warden" clinotty find "${WARDEN_PARAMS[@]}" \( -type f -or -type d \) -exec chmod u+w {} +;
fi

echo "Filesystem permissions fixed."
