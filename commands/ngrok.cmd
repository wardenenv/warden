#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

WARDEN_ENV_PATH="$(locateEnvPath)" || exit $?
loadEnvConfig "${WARDEN_ENV_PATH}" || exit $?
assertDockerRunning

if [[ ${WARDEN_NGROK:-0} -eq 0 ]]; then
  fatal "Ngrok environment is not used (WARDEN_NGROK=0)."
fi

source "${WARDEN_DIR}/utils/ngrok.sh"

if (( ${#WARDEN_PARAMS[@]} == 0 )) || [[ "${WARDEN_PARAMS[0]}" == "help" ]]; then
  warden ngrok --help || exit $? && exit $?
fi

## load connection information for the mysql service

## sub-command execution
case "${WARDEN_PARAMS[0]}" in
    init)
        if [[ "${WARDEN_PARAMS[1]}" == "" ]]; then
          domain="$TRAEFIK_DOMAIN";
          if [[ ${TRAEFIK_SUBDOMAIN} != "" ]]; then
            domain="${TRAEFIK_SUBDOMAIN}.${domain}"
          fi
          mkdir -p ${WARDEN_ENV_PATH}/.warden; #create directoy if does not exists
          generateNgrokConfigurationFile "${WARDEN_ENV_PATH}/.warden/ngrok.yml" "$domain"
        else
          mkdir -p ${WARDEN_ENV_PATH}/.warden; #create directoy if does not exists
          generateNgrokConfigurationFile "${WARDEN_ENV_PATH}/.warden/ngrok.yml" ${WARDEN_PARAMS[@]:1}
        fi
        if [ ! -f ${WARDEN_ENV_PATH}/.warden/ngrok.caddy  ]; then
            touch ${WARDEN_ENV_PATH}/.warden/ngrok.caddy
            $WARDEN_DIR/bin/warden ngrok refresh-config
        fi

        warning "You have to run the command \"warden ngrok refresh-config\" after every ngrok container start. It will generate the config for the reverse proxy allowing correct url rewrites and mapping."

        ;;
    refresh-config)
        if [[ ${CADDY_NGROK_TARGET_SERVICE} == "" ]]; then
           if [[  ${WARDEN_VARNISH} == "1" ]]; then
              CADDY_NGROK_TARGET_SERVICE=varnish;
           else
              CADDY_NGROK_TARGET_SERVICE=nginx;
           fi
        fi
        if [[ ${CADDY_NGROK_TARGET_PORT} == "" ]]; then
            CADDY_NGROK_TARGET_PORT=80;
        fi
        mkdir -p ${WARDEN_ENV_PATH}/.warden; #create directoy if does not exists
        generateCaddyConfigurationFile "${WARDEN_ENV_PATH}/.warden/ngrok.caddy" "$CADDY_NGROK_TARGET_SERVICE" "$CADDY_NGROK_TARGET_PORT"
        displayNgrokUrls
        ;;
    ls)
        displayNgrokUrls
        ;;
    *)
        fatal "The command \"${WARDEN_PARAMS[0]}\" does not exist. Please use --help for usage."
        ;;
esac
