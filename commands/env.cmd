#!/usr/bin/env bash
[[ ! ${WARDEN_COMMAND} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

source "${WARDEN_DIR}/utils/core.sh"
source "${WARDEN_DIR}/utils/env.sh"

WARDEN_ENV_PATH="$(locateEnvPath)" || exit $?
loadEnvConfig "${WARDEN_ENV_PATH}" || exit $?

if (( ${#WARDEN_PARAMS[@]} == 0 )); then
    echo -e "\033[33mThis command has required params which are passed through to docker-compose, please use --help for details.\033[0m"
    exit 1
fi

## simply allow the return code from docker-compose to bubble up per normal
trap '' ERR

## configure docker-compose files
DOCKER_COMPOSE_ARGS=()

appendEnvPartialIfExists "base"
appendEnvPartialIfExists "${WARDEN_ENV_SUBT}"

[[ ${WARDEN_TEST_DB} -eq 1 ]] \
    && appendEnvPartialIfExists "tests"

[[ ${WARDEN_SPLIT_SALES} -eq 1 ]] \
    && appendEnvPartialIfExists "splitdb.sales"

[[ ${WARDEN_SPLIT_CHECKOUT} -eq 1 ]] \
    && appendEnvPartialIfExists "splitdb.checkout"

if [[ ${WARDEN_BLACKFIRE} -eq 1 ]]; then
    appendEnvPartialIfExists "blackfire.base"
    appendEnvPartialIfExists "blackfire.${WARDEN_ENV_SUBT}"
fi

[[ ${WARDEN_ALLURE} -eq 1 ]] \
    && appendEnvPartialIfExists "allure"

[[ ${WARDEN_SELENIUM} -eq 1 ]] \
    && appendEnvPartialIfExists "selenium.base"

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
fi

## lookup address of traefik container on environment network
export TRAEFIK_ADDRESS="$(docker container inspect traefik \
    --format '
        {{- $network := index .NetworkSettings.Networks "'"$(renderEnvNetworkName)"'" -}}
        {{- if $network }}{{ $network.IPAddress }}{{ end -}}
    ' 2>/dev/null || true
)"

## anything not caught above is simply passed through to docker-compose to orchestrate
docker-compose \
    --project-directory "${WARDEN_ENV_PATH}" -p "${WARDEN_ENV_NAME}" \
    "${DOCKER_COMPOSE_ARGS[@]}" "${WARDEN_PARAMS[@]}" "$@"

## start mutagen sync if needed
if ([[ "${WARDEN_PARAMS[0]}" == "up" ]] || [[ "${WARDEN_PARAMS[0]}" == "start" ]]) \
    && [[ $OSTYPE =~ ^darwin ]] && [[ -f "${WARDEN_DIR}/environments/${WARDEN_ENV_TYPE}/${WARDEN_ENV_TYPE}.mutagen.yml" ]] \
    && [[ $(warden sync list | grep -i 'Connection state: Connected' | wc -l | awk '{print $1}') != "2" ]] \
    && [[ $(warden env ps -q php-fpm) ]] \
    && [[ $(docker container inspect $(warden env ps -q php-fpm) --format '{{ .State.Status }}') = "running" ]]
then
    warden sync start
fi

## stop mutagen sync if needed
if ([[ "${WARDEN_PARAMS[0]}" == "down" ]] || [[ "${WARDEN_PARAMS[0]}" == "stop" ]]) \
    && [[ $OSTYPE =~ ^darwin ]] && [[ -f "${WARDEN_DIR}/environments/${WARDEN_ENV_TYPE}/${WARDEN_ENV_TYPE}.mutagen.yml" ]]
then
    warden sync stop
fi
