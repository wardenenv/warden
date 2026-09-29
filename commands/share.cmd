#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

source "${WARDEN_DIR}/utils/install.sh"
assertDockerRunning

if (( ${#WARDEN_PARAMS[@]} == 0 )) || [[ "${WARDEN_PARAMS[0]}" == "help" ]]; then
  $WARDEN_BIN share --help || exit $? && exit $?
fi

## allow return codes from sub-process to bubble up normally
trap '' ERR

loadShareConfig

if [[ -z "${WARDEN_SHARE_PROVIDER}" ]]; then
    fatal "No share provider configured. Set WARDEN_SHARE_PROVIDER in ${WARDEN_HOME_DIR}/.env (available: $(shareAvailableProviders))"
fi

case "${WARDEN_PARAMS[0]}" in
    status)
        echo ""
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
        ;;
    update)
        if ! shareProviderIsConfigured; then
            fatal "No tunnel configured. Run 'warden share create' first."
        fi

        regenerateShareConfig
        echo "Share configuration updated."
        ;;
    *)
        SHARE_PROVIDER_STATUS=0
        shareProviderCommand "${WARDEN_PARAMS[@]}" || SHARE_PROVIDER_STATUS=$?

        if (( SHARE_PROVIDER_STATUS == 64 )); then
            fatal "Unknown subcommand '${WARDEN_PARAMS[0]}'. Run 'warden share help' for usage."
        fi

        exit ${SHARE_PROVIDER_STATUS}
        ;;
esac
