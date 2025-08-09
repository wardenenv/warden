#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

function locateEnvPath () {
    local WARDEN_ENV_PATH="$(pwd -P)"
    while [[ "${WARDEN_ENV_PATH}" != "/" ]]; do
        if [[ -f "${WARDEN_ENV_PATH}/.env" ]] \
            && grep "^WARDEN_ENV_NAME" "${WARDEN_ENV_PATH}/.env" >/dev/null \
            && grep "^WARDEN_ENV_TYPE" "${WARDEN_ENV_PATH}/.env" >/dev/null
        then
            break
        fi
        WARDEN_ENV_PATH="$(dirname "${WARDEN_ENV_PATH}")"
    done

    if [[ "${WARDEN_ENV_PATH}" = "/" ]]; then
        >&2 echo -e "\033[31mEnvironment config could not be found. Please run \"warden env-init\" and try again!\033[0m"
        return 1
    fi

    ## Resolve .env symlink should it exist in project sub-directory allowing sub-stacks to use relative link to parent
    WARDEN_ENV_PATH="$(
        cd "$(
            dirname "$(
                (readlink "${WARDEN_ENV_PATH}/.env" || echo "${WARDEN_ENV_PATH}/.env")
            )"
        )" >/dev/null \
        && pwd
    )"

    echo "${WARDEN_ENV_PATH}"
}

function loadEnvConfig () {
    local WARDEN_ENV_PATH="${1}"
    eval "$(cat "${WARDEN_ENV_PATH}/.env" | sed 's/\r$//g' | grep "^WARDEN_")"
    eval "$(cat "${WARDEN_ENV_PATH}/.env" | sed 's/\r$//g' | grep "^TRAEFIK_")"
    eval "$(cat "${WARDEN_ENV_PATH}/.env" | sed 's/\r$//g' | grep "^PHP_")"

    WARDEN_ENV_NAME="${WARDEN_ENV_NAME:-}"
    WARDEN_ENV_TYPE="${WARDEN_ENV_TYPE:-}"
    WARDEN_ENV_SUBT=""

    case "${OSTYPE:-undefined}" in
        darwin*)
            WARDEN_ENV_SUBT=darwin
        ;;
        linux*)
            WARDEN_ENV_SUBT=linux
        ;;
        *)
            fatal "Unsupported OSTYPE '${OSTYPE:-undefined}'"
        ;;
    esac

    assertValidEnvType
}

function renderEnvNetworkName() {
    echo "${WARDEN_ENV_NAME}_default" | tr '[:upper:]' '[:lower:]'
}

function fetchEnvInitFile () {
    local envInitPath=""

    for ENV_INIT_PATH in \
        "${WARDEN_DIR}/environments/${WARDEN_ENV_TYPE}/init.env" \
        "${WARDEN_HOME_DIR}/environments/${WARDEN_ENV_TYPE}/init.env" \
        "${WARDEN_ENV_PATH}/.warden/environments/${WARDEN_ENV_TYPE}/init.env"
    do
        if [[ -f "${ENV_INIT_PATH}" ]]; then
            envInitPath="${ENV_INIT_PATH}"
        fi
    done

    echo $envInitPath
}

function fetchValidEnvTypes () {
    local lsPaths="${WARDEN_DIR}/environments/"*/*".base.yml"

    if [[ -d "${WARDEN_HOME_DIR}/environments" ]]; then
       lsPaths="${lsPaths} ${WARDEN_HOME_DIR}/environments/"*/*".base.yml"
    fi

    if [[ -d "${WARDEN_ENV_PATH}/.warden/environments" ]]; then
       lsPaths="${lsPaths} ${WARDEN_ENV_PATH}/.warden/environments/"*/*".base.yml"
    fi

    echo $(
        ls -1 $lsPaths \
            | sed -E "s#^${WARDEN_DIR}/environments/##" \
            | sed -E "s#^${WARDEN_HOME_DIR}/environments/##" \
            | sed -E "s#^${WARDEN_ENV_PATH}/.warden/environments/##" \
            | cut -d/ -f1 | sort | uniq | grep -v includes
    )
}

function assertValidEnvType () {
    if [[ -f "${WARDEN_DIR}/environments/${WARDEN_ENV_TYPE}/${WARDEN_ENV_TYPE}.base.yml" ]]; then
        return 0
    fi

    if [[ -f "${WARDEN_HOME_DIR}/environments/${WARDEN_ENV_TYPE}/${WARDEN_ENV_TYPE}.base.yml" ]]; then
        return 0
    fi

    if [[ -f "${WARDEN_ENV_PATH}/.warden/environments/${WARDEN_ENV_TYPE}/${WARDEN_ENV_TYPE}.base.yml" ]]; then
        return 0
    fi

    >&2 echo -e "\033[31mInvalid environment type \"${WARDEN_ENV_TYPE}\" specified.\033[0m"

    return 1
}

function appendEnvPartialIfExists () {
    local PARTIAL_NAME="${1}"
    local PARTIAL_PATH=""

    for PARTIAL_PATH in \
        "${WARDEN_DIR}/environments/includes/${PARTIAL_NAME}.base.yml" \
        "${WARDEN_DIR}/environments/includes/${PARTIAL_NAME}.${WARDEN_ENV_SUBT}.yml" \
        "${WARDEN_DIR}/environments/${WARDEN_ENV_TYPE}/${PARTIAL_NAME}.base.yml" \
        "${WARDEN_DIR}/environments/${WARDEN_ENV_TYPE}/${PARTIAL_NAME}.${WARDEN_ENV_SUBT}.yml" \
        "${WARDEN_HOME_DIR}/environments/includes/${PARTIAL_NAME}.base.yml" \
        "${WARDEN_HOME_DIR}/environments/includes/${PARTIAL_NAME}.${WARDEN_ENV_SUBT}.yml" \
        "${WARDEN_HOME_DIR}/environments/${WARDEN_ENV_TYPE}/${PARTIAL_NAME}.base.yml" \
        "${WARDEN_HOME_DIR}/environments/${WARDEN_ENV_TYPE}/${PARTIAL_NAME}.${WARDEN_ENV_SUBT}.yml" \
        "${WARDEN_ENV_PATH}/.warden/environments/includes/${PARTIAL_NAME}.base.yml" \
        "${WARDEN_ENV_PATH}/.warden/environments/includes/${PARTIAL_NAME}.${WARDEN_ENV_SUBT}.yml" \
        "${WARDEN_ENV_PATH}/.warden/environments/${WARDEN_ENV_TYPE}/${PARTIAL_NAME}.base.yml" \
        "${WARDEN_ENV_PATH}/.warden/environments/${WARDEN_ENV_TYPE}/${PARTIAL_NAME}.${WARDEN_ENV_SUBT}.yml"
    do
        if [[ -f "${PARTIAL_PATH}" ]]; then
            DOCKER_COMPOSE_ARGS+=("-f" "${PARTIAL_PATH}")
        fi
    done
}
