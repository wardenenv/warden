#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

source "${WARDEN_DIR}/utils/install.sh"
assertDockerRunning

if (( ${#WARDEN_PARAMS[@]} == 0 )) || [[ "${WARDEN_PARAMS[0]}" == "help" ]]; then
  $WARDEN_BIN share --help || exit $? && exit $?
fi

## allow return codes from sub-process to bubble up normally
trap '' ERR

SHARE_SCOPE=

if [[ -n "${WARDEN_ENV_PATH:-}" ]]; then
    SHARE_ENV_KEYS="(WARDEN_SHARE|WARDEN_VARNISH|WARDEN_ENV_TYPE|TRAEFIK_PUBLIC_DOMAIN)$"
    loadEnvFile "${WARDEN_ENV_PATH}/.env" "${SHARE_ENV_KEYS}"
    loadEnvFile "${WARDEN_ENV_PATH}/.env.local" "${SHARE_ENV_KEYS}"

    if [[ -n "${WARDEN_SHARE:-}" ]]; then
        ## provider-owned project variables load before the provider file, which
        ## clears and re-reads its credentials from the global .env afterwards
        SHARE_PROVIDER_FILE="${WARDEN_DIR}/utils/share/${WARDEN_SHARE}.sh"
        if [[ "${WARDEN_SHARE}" =~ ^[a-z0-9-]+$ ]] && [[ -f "${SHARE_PROVIDER_FILE}" ]]; then
            SHARE_PROVIDER_PREFIX="$(shareProviderEnvPrefix "${SHARE_PROVIDER_FILE}")"
            if [[ -n "${SHARE_PROVIDER_PREFIX}" ]]; then
                loadEnvFile "${WARDEN_ENV_PATH}/.env" "${SHARE_PROVIDER_PREFIX}"
                loadEnvFile "${WARDEN_ENV_PATH}/.env.local" "${SHARE_PROVIDER_PREFIX}"
            fi
        fi

        loadProjectShareConfig
        SHARE_SCOPE=project
    fi
fi

if [[ -z "${SHARE_SCOPE}" ]]; then
    loadShareConfig

    if [[ -n "${WARDEN_SHARE_PROVIDER}" ]]; then
        SHARE_SCOPE=global
    fi
fi

if [[ -z "${SHARE_SCOPE}" ]]; then
    fatal "No share provider configured. Set WARDEN_SHARE in the project .env (project scope, available: $(shareAvailableProviders project)) or WARDEN_SHARE_PROVIDER in ${WARDEN_HOME_DIR}/.env (global scope, available: $(shareAvailableProviders global))."
fi

if [[ "${SHARE_SCOPE}" == "project" ]] && [[ "${WARDEN_PARAMS[0]}" != "status" ]]; then
    shareProviderRequireConfig
fi

case "${WARDEN_PARAMS[0]}" in
    status)
        echo ""
        if [[ "${SHARE_SCOPE}" == "project" ]]; then
            echo "Provider: ${WARDEN_SHARE} (project)"
            shareProviderStatus

            SHARE_URL="$(shareProviderUrl)" || SHARE_URL=""
            if [[ -n "${SHARE_URL}" ]]; then
                echo "URL: ${SHARE_URL}"
            else
                echo "URL: (not available yet)"
            fi
            echo ""
        else
            echo "Provider: ${WARDEN_SHARE_PROVIDER}"
            shareProviderStatus

            echo ""
            echo "Connected domains:"
            SHARE_DOMAINS="$(shareDomains)"
            if [[ -n "${SHARE_DOMAINS}" ]]; then
                echo "${SHARE_DOMAINS}" | sed 's/^/  /'
            else
                echo "  (none)"
            fi
            echo ""
        fi
        ;;
    url)
        if [[ "${SHARE_SCOPE}" == "project" ]]; then
            SHARE_URL="$(shareProviderUrl)" || SHARE_URL=""
            if [[ -z "${SHARE_URL}" ]]; then
                >&2 echo "Public URL not available yet. Is the environment running? Try again in a few seconds."
                exit 1
            fi

            echo "${SHARE_URL}"
        else
            if [[ -z "${TRAEFIK_PUBLIC_DOMAIN:-}" ]]; then
                fatal "No public URL for this project. Set TRAEFIK_PUBLIC_DOMAIN in the project .env."
            fi

            echo "https://${TRAEFIK_PUBLIC_DOMAIN}"
        fi
        ;;
    update)
        if [[ "${SHARE_SCOPE}" != "global" ]]; then
            fatal "'warden share update' applies to the global share provider only."
        fi

        if ! shareProviderIsConfigured; then
            fatal "No tunnel configured. Run 'warden share create' first."
        fi

        regenerateShareConfig
        echo "Share configuration updated."
        ;;
    *)
        SHARE_PROVIDER_STATUS=0
        shareProviderCommand "${WARDEN_PARAMS[@]}" || SHARE_PROVIDER_STATUS=$?

        ## global setup subcommands stay reachable from inside a project that
        ## selects a project provider; the global file is sourced only here, so
        ## no project hook runs after it replaces the shared function names
        if (( SHARE_PROVIDER_STATUS == 64 )) && [[ "${SHARE_SCOPE}" == "project" ]]; then
            loadShareConfig

            if [[ -n "${WARDEN_SHARE_PROVIDER}" ]]; then
                SHARE_PROVIDER_STATUS=0
                shareProviderCommand "${WARDEN_PARAMS[@]}" || SHARE_PROVIDER_STATUS=$?
            fi
        fi

        if (( SHARE_PROVIDER_STATUS == 64 )); then
            fatal "Unknown subcommand '${WARDEN_PARAMS[0]}'. Run 'warden share help' for usage."
        fi

        exit ${SHARE_PROVIDER_STATUS}
        ;;
esac
