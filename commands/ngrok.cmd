#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

NGROK_AUTHTOKEN_PARAM=${WARDEN_PARAMS[0]}

# ~/.warden/.env
eval "$(cat "${WARDEN_HOME_DIR}/.env" | sed 's/\r$//g' | grep "^WARDEN_")" || exit $?

#
WARDEN_ENV_PATH="$(locateEnvPath)" || exit $?
loadEnvConfig "${WARDEN_ENV_PATH}" || exit $?

if [ -n "$NGROK_AUTHTOKEN_PARAM" ]; then
    NGROK_AUTHTOKEN=${NGROK_AUTHTOKEN_PARAM}
else
    if [ -n "$WARDEN_NGROK_AUTHTOKEN" ]; then
        NGROK_AUTHTOKEN=${WARDEN_NGROK_AUTHTOKEN}
    fi
fi

assertDockerRunning

if [[ "${WARDEN_PARAMS[0]}" == "help" ]]; then
  $WARDEN_BIN ngrok --help || exit $? && exit $?
fi

if [[ -z "$NGROK_AUTHTOKEN" ]]; then
  fatal "Ngrok auth-token is not set (WARDEN_NGROK_AUTHTOKEN=) in '.env' file. Can be also pass as parameter: 'warden ngrok [auth-token]'"
fi

NGINX_CONTAINER_ID=$($WARDEN_BIN env ps -q nginx)
if [[ -z "$NGINX_CONTAINER_ID" ]]; then
    fatal "No container found for nginx service."
else
    NGINX_CONTAINER=$(docker inspect -f '{{ index (split .Name "/") 1 }}' "${NGINX_CONTAINER_ID}")
fi

NETWORK_NAME=$(docker container inspect ${NGINX_CONTAINER} --format '{{range $key, $value := .NetworkSettings.Networks}}{{printf "%s\n" $key}}{{end}}')
if [[ -z "$NETWORK_NAME" ]]; then
    fatal "No networks found for nginx service."
fi

docker run --rm -it --link ${NGINX_CONTAINER} --net ${NETWORK_NAME} -e NGROK_AUTHTOKEN=${NGROK_AUTHTOKEN} ngrok/ngrok:latest http ${NGINX_CONTAINER}:80
