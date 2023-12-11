#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

WARDEN_ENV_PATH="$(locateEnvPath)" || exit $?
loadEnvConfig "${WARDEN_ENV_PATH}" || exit $?
assertDockerRunning

if [[ "${WARDEN_PARAMS[0]}" == "help" ]]; then
  $WARDEN_BIN ngrok --help || exit $? && exit $?
fi

NGINX_CONTAINER=$(docker inspect -f '{{ index (split .Name "/") 1 }}' "$($WARDEN_BIN env ps -q nginx)")
if [[ ! ${NGINX_CONTAINER} ]]; then
    fatal "No container found for nginx service."
fi

NETWORK_NAME=$(docker container inspect ${NGINX_CONTAINER} --format '{{range $key, $value := .NetworkSettings.Networks}}{{printf "%s\n" $key}}{{end}}')
if [[ ! ${NETWORK_NAME} ]]; then
    fatal "No networks found for nginx service."
fi

docker run --rm -it --link ${NGINX_CONTAINER} --net ${NETWORK_NAME} -e NGROK_AUTHTOKEN=${WARDEN_NGROK_TOKEN} ngrok/ngrok:latest http ${NGINX_CONTAINER}:80
