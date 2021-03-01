#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

WARDEN_ENV_PATH="$(locateEnvPath)" || exit $?
loadEnvConfig "${WARDEN_ENV_PATH}" || exit $?
assertDockerRunning

if (( ${#WARDEN_PARAMS[@]} == 0 )) || [[ "${WARDEN_PARAMS[0]}" == "help" ]]; then
  warden env --help || exit $? && exit $?
fi

## allow return codes from sub-process to bubble up normally
trap '' ERR

## configure environment type defaults
if [[ ${WARDEN_ENV_TYPE} =~ ^magento ]]; then
    export WARDEN_SVC_PHP_VARIANT=-${WARDEN_ENV_TYPE}
fi

## configure xdebug version
export XDEBUG_VERSION="debug" # xdebug2 image
if [[ ${PHP_XDEBUG_3} -eq 1 ]]; then
    export XDEBUG_VERSION="xdebug3"
fi

if [[ ${WARDEN_ENV_TYPE} != local ]]; then
    WARDEN_NGINX=${WARDEN_NGINX:-1}
    WARDEN_DB=${WARDEN_DB:-1}
    WARDEN_REDIS=${WARDEN_REDIS:-1}

    # define bash history folder for changing permissions
    WARDEN_CHOWN_DIR_LIST="/bash_history ${WARDEN_CHOWN_DIR_LIST:-}"
fi
export CHOWN_DIR_LIST=${WARDEN_CHOWN_DIR_LIST:-}

if [[ ${WARDEN_ENV_TYPE} == "magento1" && -f "${WARDEN_ENV_PATH}/.modman/.basedir" ]]; then
  export NGINX_PUBLIC='/'$(cat "${WARDEN_ENV_PATH}/.modman/.basedir")
fi

if [[ ${WARDEN_ENV_TYPE} == "magento2" ]]; then
    WARDEN_VARNISH=${WARDEN_VARNISH:-1}
    WARDEN_ELASTICSEARCH=${WARDEN_ELASTICSEARCH:-1}
    WARDEN_RABBITMQ=${WARDEN_RABBITMQ:-1}
fi

## WSL1/WSL2 are GNU/Linux env type but still run Docker Desktop
if [[ ${XDEBUG_CONNECT_BACK_HOST} == '' ]] && grep -sqi microsoft /proc/sys/kernel/osrelease; then
    export XDEBUG_CONNECT_BACK_HOST=host.docker.internal
fi

## configure docker-compose files
DOCKER_COMPOSE_ARGS=()

appendEnvPartialIfExists "networks"

if [[ ${WARDEN_ENV_TYPE} != local ]]; then
    appendEnvPartialIfExists "php-fpm"
fi

[[ ${WARDEN_NGINX} -eq 1 ]] \
    && appendEnvPartialIfExists "nginx"

[[ ${WARDEN_DB} -eq 1 ]] \
    && appendEnvPartialIfExists "db"

[[ ${WARDEN_ELASTICSEARCH} -eq 1 ]] \
    && appendEnvPartialIfExists "elasticsearch"

[[ ${WARDEN_VARNISH} -eq 1 ]] \
    && appendEnvPartialIfExists "varnish"

[[ ${WARDEN_RABBITMQ} -eq 1 ]] \
    && appendEnvPartialIfExists "rabbitmq"

[[ ${WARDEN_REDIS} -eq 1 ]] \
    && appendEnvPartialIfExists "redis"

appendEnvPartialIfExists "${WARDEN_ENV_TYPE}"

[[ ${WARDEN_TEST_DB} -eq 1 ]] \
    && appendEnvPartialIfExists "${WARDEN_ENV_TYPE}.tests"

[[ ${WARDEN_SPLIT_SALES} -eq 1 ]] \
    && appendEnvPartialIfExists "${WARDEN_ENV_TYPE}.splitdb.sales"

[[ ${WARDEN_SPLIT_CHECKOUT} -eq 1 ]] \
    && appendEnvPartialIfExists "${WARDEN_ENV_TYPE}.splitdb.checkout"

if [[ ${WARDEN_BLACKFIRE} -eq 1 ]]; then
    appendEnvPartialIfExists "blackfire"
    appendEnvPartialIfExists "${WARDEN_ENV_TYPE}.blackfire"
fi

[[ ${WARDEN_ALLURE} -eq 1 ]] \
    && appendEnvPartialIfExists "allure"

[[ ${WARDEN_SELENIUM} -eq 1 ]] \
    && appendEnvPartialIfExists "selenium"

[[ ${WARDEN_MAGEPACK} -eq 1 ]] \
    && appendEnvPartialIfExists "${WARDEN_ENV_TYPE}.magepack"

if [[ -f "${WARDEN_ENV_PATH}/.warden/warden-env.yml" ]]; then
    DOCKER_COMPOSE_ARGS+=("-f")
    DOCKER_COMPOSE_ARGS+=("${WARDEN_ENV_PATH}/.warden/warden-env.yml")
fi

if [[ -f "${WARDEN_ENV_PATH}/.warden/warden-env.${WARDEN_ENV_SUBT}.yml" ]]; then
    DOCKER_COMPOSE_ARGS+=("-f")
    DOCKER_COMPOSE_ARGS+=("${WARDEN_ENV_PATH}/.warden/warden-env.${WARDEN_ENV_SUBT}.yml")
fi

if [[ ${WARDEN_SELENIUM_DEBUG} -eq 1 ]]; then
    export WARDEN_SELENIUM_DEBUG="-debug"
else
    export WARDEN_SELENIUM_DEBUG=
fi

## disconnect peered service containers from environment network
if [[ "${WARDEN_PARAMS[0]}" == "down" ]]; then
    disconnectPeeredServices "$(renderEnvNetworkName)"
fi

## connect peered service containers to environment network
if [[ "${WARDEN_PARAMS[0]}" == "up" ]]; then
    ## create environment network for attachments if it does not already exist
    if [[ $(docker network ls -f "name=$(renderEnvNetworkName)" -q) == "" ]]; then
        docker-compose \
            --project-directory "${WARDEN_ENV_PATH}" -p "${WARDEN_ENV_NAME}" \
            "${DOCKER_COMPOSE_ARGS[@]}" up --no-start
    fi

    ## connect globally peered services to the environment network
    connectPeeredServices "$(renderEnvNetworkName)"

    ## always execute env up using --detach mode
    if ! (containsElement "-d" "$@" || containsElement "--detach" "$@"); then
        WARDEN_PARAMS=("${WARDEN_PARAMS[@]:1}")
        WARDEN_PARAMS=(up -d "${WARDEN_PARAMS[@]}")
    fi
fi

## lookup address of traefik container on environment network
export TRAEFIK_ADDRESS="$(docker container inspect traefik \
    --format '
        {{- $network := index .NetworkSettings.Networks "'"$(renderEnvNetworkName)"'" -}}
        {{- if $network }}{{ $network.IPAddress }}{{ end -}}
    ' 2>/dev/null || true
)"

if [[ $OSTYPE =~ ^darwin ]]; then
    export MUTAGEN_SYNC_FILE="${WARDEN_DIR}/environments/${WARDEN_ENV_TYPE}/${WARDEN_ENV_TYPE}.mutagen.yml"

    if [[ -f "${WARDEN_ENV_PATH}/.warden/mutagen.yml" ]]; then
        export MUTAGEN_SYNC_FILE="${WARDEN_ENV_PATH}/.warden/mutagen.yml"
    fi
fi

## pause mutagen sync if needed
if [[ "${WARDEN_PARAMS[0]}" == "stop" ]] \
    && [[ $OSTYPE =~ ^darwin ]] && [[ -f "${MUTAGEN_SYNC_FILE}" ]]
then
    warden sync pause
fi

## pass ochestration through to docker-compose
docker-compose \
    --project-directory "${WARDEN_ENV_PATH}" -p "${WARDEN_ENV_NAME}" \
    "${DOCKER_COMPOSE_ARGS[@]}" "${WARDEN_PARAMS[@]}" "$@"

## resume mutagen sync if available and php-fpm container id hasn't changed
if ([[ "${WARDEN_PARAMS[0]}" == "up" ]] || [[ "${WARDEN_PARAMS[0]}" == "start" ]]) \
    && [[ $OSTYPE =~ ^darwin ]] && [[ -f "${MUTAGEN_SYNC_FILE}" ]] \
    && [[ $(warden sync list | grep -i 'Status: \[Paused\]' | wc -l | awk '{print $1}') == "1" ]] \
    && [[ $(warden env ps -q php-fpm) ]] \
    && [[ $(docker container inspect $(warden env ps -q php-fpm) --format '{{ .State.Status }}') = "running" ]] \
    && [[ $(warden env ps -q php-fpm) = $(warden sync list | grep -i 'URL: docker' | awk -F'/' '{print $3}') ]]
then
    warden sync resume
fi

## start mutagen sync if needed
if ([[ "${WARDEN_PARAMS[0]}" == "up" ]] || [[ "${WARDEN_PARAMS[0]}" == "start" ]]) \
    && [[ $OSTYPE =~ ^darwin ]] && [[ -f "${MUTAGEN_SYNC_FILE}" ]] \
    && [[ $(warden sync list | grep -i 'Connection state: Connected' | wc -l | awk '{print $1}') != "2" ]] \
    && [[ $(warden env ps -q php-fpm) ]] \
    && [[ $(docker container inspect $(warden env ps -q php-fpm) --format '{{ .State.Status }}') = "running" ]]
then
    warden sync start
fi

## stop mutagen sync if needed
if [[ "${WARDEN_PARAMS[0]}" == "down" ]] \
    && [[ $OSTYPE =~ ^darwin ]] && [[ -f "${MUTAGEN_SYNC_FILE}" ]]
then
    warden sync stop
fi
