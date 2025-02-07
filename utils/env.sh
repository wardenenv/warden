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

    # Load mutagen settings if available
    if [[ -f "${WARDEN_HOME_DIR}/.env" ]]; then
      eval "$(sed 's/\r$//g' < "${WARDEN_HOME_DIR}/.env" | grep "^WARDEN_MUTAGEN_ENABLE")"
    fi

    ## configure mutagen enable by default for MacOs
    if [[ $OSTYPE =~ ^darwin ]]; then
      export WARDEN_MUTAGEN_ENABLE=${WARDEN_MUTAGEN_ENABLE:-1}
    else
      # Disable mutagen for non-MacOS systems
      export WARDEN_MUTAGEN_ENABLE=0
    fi

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

    local BASE_PATHS=(
        "${WARDEN_DIR}/environments/includes"
        "${WARDEN_DIR}/environments/${WARDEN_ENV_TYPE}"
        "${WARDEN_HOME_DIR}/environments/includes"
        "${WARDEN_HOME_DIR}/environments/${WARDEN_ENV_TYPE}"
        "${WARDEN_ENV_PATH}/.warden/environments/includes"
        "${WARDEN_ENV_PATH}/.warden/environments/${WARDEN_ENV_TYPE}"
    )

    if [[ ${WARDEN_MUTAGEN_ENABLE} -eq 0 ]]; then
        local FILE_SUFFIXES=(".base.yml" ".${WARDEN_ENV_SUBT}.yml")
    else
        # Suffix .mutagen.yml is used for mutagen sync configuration
        # so using .mutagen_compose.yml for docker-compose configurations
        local FILE_SUFFIXES=(".base.yml" ".${WARDEN_ENV_SUBT}.yml" ".mutagen_compose.yml")
    fi

    for BASE_PATH in "${BASE_PATHS[@]}"; do
        for SUFFIX in "${FILE_SUFFIXES[@]}"; do
            PARTIAL_PATH="${BASE_PATH}/${PARTIAL_NAME}${SUFFIX}"
            if [[ -f "${PARTIAL_PATH}" ]]; then
                DOCKER_COMPOSE_ARGS+=("-f" "${PARTIAL_PATH}")
            fi
        done
    done
}
