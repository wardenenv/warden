#!/usr/bin/env bash
[[ ! ${WARDEN_COMMAND} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!" && exit 1

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
DOCKER_COMPOSE_ARGS+=("-f")
DOCKER_COMPOSE_ARGS+=("${WARDEN_DIR}/environments/${WARDEN_ENV_TYPE}.base.yml")

if [[ -f "${WARDEN_DIR}/environments/${WARDEN_ENV_TYPE}.${WARDEN_ENV_SUBT}.yml" ]]; then
    DOCKER_COMPOSE_ARGS+=("-f")
    DOCKER_COMPOSE_ARGS+=("${WARDEN_DIR}/environments/${WARDEN_ENV_TYPE}.${WARDEN_ENV_SUBT}.yml")
fi

if [[ ${WARDEN_SPLIT_SALES} -eq 1 && -f "${WARDEN_DIR}/environments/${WARDEN_ENV_TYPE}.splitdb.sales.yml" ]]; then
    DOCKER_COMPOSE_ARGS+=("-f")
    DOCKER_COMPOSE_ARGS+=("${WARDEN_DIR}/environments/${WARDEN_ENV_TYPE}.splitdb.sales.yml")
fi

if [[ ${WARDEN_SPLIT_CHECKOUT} -eq 1 && -f "${WARDEN_DIR}/environments/${WARDEN_ENV_TYPE}.splitdb.checkout.yml" ]]; then
    DOCKER_COMPOSE_ARGS+=("-f")
    DOCKER_COMPOSE_ARGS+=("${WARDEN_DIR}/environments/${WARDEN_ENV_TYPE}.splitdb.checkout.yml")
fi

if [[ ${WARDEN_BLACKFIRE} -eq 1 && -f "${WARDEN_DIR}/environments/${WARDEN_ENV_TYPE}.blackfire.base.yml" ]]; then
    DOCKER_COMPOSE_ARGS+=("-f")
    DOCKER_COMPOSE_ARGS+=("${WARDEN_DIR}/environments/${WARDEN_ENV_TYPE}.blackfire.base.yml")
fi

if [[ ${WARDEN_BLACKFIRE} -eq 1 && -f "${WARDEN_DIR}/environments/${WARDEN_ENV_TYPE}.blackfire.${WARDEN_ENV_SUBT}.yml" ]]; then
    DOCKER_COMPOSE_ARGS+=("-f")
    DOCKER_COMPOSE_ARGS+=("${WARDEN_DIR}/environments/${WARDEN_ENV_TYPE}.blackfire.${WARDEN_ENV_SUBT}.yml")
fi

if [[ -f "${WARDEN_ENV_PATH}/.warden/warden-env.yml" ]]; then
    DOCKER_COMPOSE_ARGS+=("-f")
    DOCKER_COMPOSE_ARGS+=("${WARDEN_ENV_PATH}/.warden/warden-env.yml")
fi

if [[ -f "${WARDEN_ENV_PATH}/.warden/warden-env.${WARDEN_ENV_SUBT}.yml" ]]; then
    DOCKER_COMPOSE_ARGS+=("-f")
    DOCKER_COMPOSE_ARGS+=("${WARDEN_ENV_PATH}/.warden/warden-env.${WARDEN_ENV_SUBT}.yml")
fi

if [[ ${WARDEN_SELENIUM} -eq 1 && -f "${WARDEN_DIR}/environments/${WARDEN_ENV_TYPE}.selenium.base.yml" ]]; then
    DOCKER_COMPOSE_ARGS+=("-f")
    DOCKER_COMPOSE_ARGS+=("${WARDEN_DIR}/environments/${WARDEN_ENV_TYPE}.selenium.base.yml")
fi

if [[ ${WARDEN_SELENIUM_DEBUG} -eq 1 ]]; then
    export WARDEN_SELENIUM_DEBUG="-debug"
else
    export WARDEN_SELENIUM_DEBUG=
fi

## disconnect peered service containers from environment network
if [[ "${WARDEN_PARAMS[0]}" == "down" ]]; then
    disconnectPeeredServices "${WARDEN_ENV_NAME}_default"
fi

## connect peered service containers to environment network
if [[ "${WARDEN_PARAMS[0]}" == "up" ]]; then
    ## create environment network for attachments if it does not already exist
    if [[ $(docker network ls -f "name=${WARDEN_ENV_NAME}_default" -q) == "" ]]; then
        docker-compose \
            --project-directory "${WARDEN_ENV_PATH}" -p "${WARDEN_ENV_NAME}" \
            "${DOCKER_COMPOSE_ARGS[@]}" up --no-start
    fi

    ## connect globally peered services to the environment network
    connectPeeredServices "${WARDEN_ENV_NAME}_default"
fi

## lookup address of traefik container on environment network
export TRAEFIK_ADDRESS="$(docker container inspect traefik \
    --format "{{if .NetworkSettings.Networks.${WARDEN_ENV_NAME}_default}} \
        {{.NetworkSettings.Networks.${WARDEN_ENV_NAME}_default.IPAddress}} \
    {{end}}" 2>/dev/null || true \
)"

## anything not caught above is simply passed through to docker-compose to orchestrate
docker-compose \
    --project-directory "${WARDEN_ENV_PATH}" -p "${WARDEN_ENV_NAME}" \
    "${DOCKER_COMPOSE_ARGS[@]}" "${WARDEN_PARAMS[@]}" "$@"
