#!/usr/bin/env bash
[[ ! ${WARDEN_COMMAND} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

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
    eval "$(grep "^WARDEN_" "${WARDEN_ENV_PATH}/.env")"

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
            >&2 printf "\e[01;31mERROR\033[0m: Unsupported OSTYPE '${OSTYPE:-undefined}'\n"
            exit 1
        ;;
    esac

    assertValidEnvType
}

function renderEnvNetworkName() {
    echo "${WARDEN_ENV_NAME}_default" | tr '[:upper:]' '[:lower:]'
}

function assertValidEnvType () {
    if [[ ! -f "${WARDEN_DIR}/environments/${WARDEN_ENV_TYPE}/${WARDEN_ENV_TYPE}.base.yml" ]]; then
        >&2 echo -e "\033[31mInvalid environment type \"${WARDEN_ENV_TYPE}\" specified.\033[0m"
        return 1
    fi
}

function appendEnvPartialIfExists () {
    local PARTIAL_NAME="${1}"
    local PARTIAL_PATH=""

    for PARTIAL_PATH in \
        "${WARDEN_DIR}/environments/${WARDEN_ENV_TYPE}/${PARTIAL_NAME}.base.yml" \
        "${WARDEN_DIR}/environments/${WARDEN_ENV_TYPE}/${PARTIAL_NAME}.${WARDEN_ENV_SUBT}.yml" \
        "${WARDEN_DIR}/environments/includes/${PARTIAL_NAME}.base.yml" \
        "${WARDEN_DIR}/environments/includes/${PARTIAL_NAME}.${WARDEN_ENV_SUBT}.yml"
    do
        if [[ -f "${PARTIAL_PATH}" ]]; then
            DOCKER_COMPOSE_ARGS+=("-f" "${PARTIAL_PATH}")
        fi
    done
}
