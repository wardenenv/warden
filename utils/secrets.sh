#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

## variables managed by Warden itself; a secrets provider must not take these
## over, as doing so would silently change how the stack is built
WARDEN_SECRETS_RESERVED_VARS=(
    CHOWN_DIR_LIST
    COMPOSER_MEMORY_LIMIT
    COMPOSER_VERSION
    HISTFILE
    NODE_VERSION
    SSH_AUTH_SOCK
    SSH_AUTH_SOCK_PATH_ENV
    XDEBUG_VERSION
)

## names that would change the host process which runs docker compose
WARDEN_SECRETS_HOST_VARS=(
    PATH
    HOME
    USER
    LOGNAME
    SHELL
    PWD
    OLDPWD
    IFS
    TMPDIR
    ENV
    BASH_ENV
    SHELLOPTS
    BASHOPTS
    PS4
    CDPATH
    GLOBIGNORE
    TERM
    LANG
)

function secretsAvailableProviders {
    local providers="" candidate
    for candidate in "${WARDEN_DIR}"/utils/secrets/*.sh; do
        [[ -e "${candidate}" ]] || continue
        candidate="${candidate##*/}"
        providers="${providers}${candidate%.sh} "
    done

    echo "${providers% }"
}

function loadSecretsProvider {
    local name="${1}"
    local providerFile="${WARDEN_DIR}/utils/secrets/${name}.sh"

    if [[ ! "${name}" =~ ^[a-z0-9-]+$ ]]; then
        warning "WARDEN_SECRETS must be a provider name (lowercase letters, digits, dashes). Available providers: $(secretsAvailableProviders); skipping secret injection."
        return 1
    fi

    if [[ ! -f "${providerFile}" ]]; then
        warning "Unknown secrets provider '${name}' in WARDEN_SECRETS. Available providers: $(secretsAvailableProviders); skipping secret injection."
        return 1
    fi

    # shellcheck source=/dev/null
    source "${providerFile}"
}

## provider contract; a provider overrides these once it is sourced
## on invalid configuration the provider prints its own warning and returns 1
function secretsProviderRequireConfig {
    return 0
}

## prints the secrets as dotenv KEY=VALUE lines on stdout, the VALUE raw up to
## the end of the line; on failure the provider prints its own warning and
## returns 1
function secretsProviderRead {
    return 1
}

## exports the accepted secrets into the current shell; call inside a subshell so
## values never reach the parent process
function exportSecrets {
    local WARDEN_SECRETS_PAIR
    for WARDEN_SECRETS_PAIR in "${SECRETS_EXPORTS[@]}"; do
        export "${WARDEN_SECRETS_PAIR?}"
    done
}

## true when the named partial was appended to DOCKER_COMPOSE_ARGS, so the
## override never names a service the stack does not define
function secretsPartialIncluded {
    local partialName="${1}"
    local arg base expectPath=0
    for arg in "${DOCKER_COMPOSE_ARGS[@]}"; do
        if [[ "${expectPath}" == 1 ]]; then
            expectPath=0
            base="${arg##*/}"
            [[ "${base}" == "${partialName}."*.yml ]] && return 0
            continue
        fi

        [[ "${arg}" == "-f" ]] && expectPath=1
    done

    return 1
}

## sets SECRETS_EXPORTS (KEY=VALUE pairs) and SECRETS_COMPOSE_FILE (names-only compose override)
function loadSecrets {
    local provider="${WARDEN_SECRETS:-}"
    local output line key value pair service
    local skipped=()
    local parsed=0
    local -a services=(php-fpm php-debug)

    SECRETS_EXPORTS=()
    SECRETS_COMPOSE_FILE=

    secretsProviderRequireConfig || return 1

    output="$(secretsProviderRead)" || return 1

    while IFS= read -r line || [[ -n "${line}" ]]; do
        line="${line%$'\r'}"
        [[ -z "${line}" ]] && continue
        [[ "${line}" =~ ^[[:space:]]*# ]] && continue
        [[ "${line}" != *=* ]] && continue

        key="${line%%=*}"
        value="${line#*=}"

        [[ ! "${key}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] && continue
        parsed=$(( parsed + 1 ))

        if containsElement "${key}" "${WARDEN_SECRETS_RESERVED_VARS[@]}" \
            || containsElement "${key}" "${WARDEN_SECRETS_HOST_VARS[@]}" \
            || [[ "${key}" =~ ^(WARDEN|TRAEFIK|PHP|DOCKER|COMPOSE|BUILDKIT|BUILDX|LD|DYLD|BASH_FUNC|LC|OP|VAULT|MUTAGEN)_ ]]
        then
            skipped+=("${key}")
            continue
        fi

        SECRETS_EXPORTS+=("${key}=${value}")
    done <<< "${output}"

    if (( ${#skipped[@]} > 0 )); then
        warning "Variables reserved by Warden were not injected: ${skipped[*]}"
    fi

    if (( parsed == 0 )); then
        warning "Secrets provider '${provider}' returned no variables; skipping secret injection."
        return 1
    fi

    if (( ${#SECRETS_EXPORTS[@]} == 0 )); then
        warning "Secrets provider '${provider}' defines only variables reserved by Warden; skipping secret injection."
        return 1
    fi

    if [[ ${WARDEN_PHP_SPX:-0} -eq 1 ]] && secretsPartialIncluded "php-spx"; then
        services+=(php-spx)
    fi

    if [[ ${WARDEN_BLACKFIRE:-0} -eq 1 ]] && secretsPartialIncluded "blackfire"; then
        services+=(php-blackfire)
    fi

    if [[ ${WARDEN_MAGENTO2_GRAPHQL_SERVER:-0} -eq 1 ]] && secretsPartialIncluded "${WARDEN_ENV_TYPE}.graphql"; then
        services+=(php-graphql)
    fi

    if ! SECRETS_COMPOSE_FILE="$(mktemp "${TMPDIR:-/tmp}/warden-secrets.XXXXXXXX")"; then
        SECRETS_EXPORTS=()
        warning "Could not create the compose override for secrets provider '${provider}'; skipping secret injection."
        return 1
    fi

    {
        echo "x-warden-secrets: &warden_secrets"
        for pair in "${SECRETS_EXPORTS[@]}"; do
            echo "  - ${pair%%=*}"
        done
        echo "services:"
        for service in "${services[@]}"; do
            echo "  ${service}:"
            echo "    environment: *warden_secrets"
        done
    } > "${SECRETS_COMPOSE_FILE}"
}
