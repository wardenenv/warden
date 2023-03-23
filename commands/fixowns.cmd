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

echo "Fixing filesystem ownerships..."

if [ -z  "${WARDEN_PARAMS[@]}" ]; then
  "${WARDEN_DIR}/bin/warden" rootnotty chown -R www-data:www-data /var/www
else
  "${WARDEN_DIR}/bin/warden" rootnotty chown -R www-data:www-data /var/www/html/"${WARDEN_PARAMS[@]}"
fi

echo "Filesystem ownerships fixed."
