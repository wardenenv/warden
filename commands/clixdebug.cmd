#!/usr/bin/env bash
[[ ! ${WARDEN_COMMAND} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!" && exit 1

source "${WARDEN_DIR}/utils/env.sh"
WARDEN_ENV_PATH="$(locateEnvPath)" || exit $?
loadEnvConfig "${WARDEN_ENV_PATH}" || exit $?
pushd "${WARDEN_DIR}" >/dev/null

# docker exec -ti <CONTAINER_ID> php -d xdebug.remote_autostart=on -d xdebug.remote_host=host.docker.internal
containerid=$(docker ps -qf "name=debug")
#echo $containerid;
if [[ $containerid != "" ]]; then
	echo "xDebug executing on container ... ${WARDEN_PARAMS[0]}";
	docker exec -ti $containerid php -d xdebug.remote_autostart=on -d xdebug.remote_host=host.docker.internal "${WARDEN_PARAMS[@]}" "$@"
else
	echo "A container image named 'debug' was not found.";
fi