#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

WARDEN_ENV_PATH="$(locateEnvPath)" || exit $?
loadEnvConfig "${WARDEN_ENV_PATH}" || exit $?

if (( ${#WARDEN_PARAMS[@]} == 0 )); then
  fatal "This command has required params; use --help for details."
fi

## disable sync command when WARDEN_MUTAGEN_ENABLE is set to 0
if [[ ${WARDEN_MUTAGEN_ENABLE} -eq 0 ]]; then
  fatal "Mutagen sync is disabled in the config file."
fi

## disable sync command on non-darwin environments where it should not be used
if [[ ${WARDEN_ENV_SUBT} != "darwin" ]]; then
  fatal "Mutagen sync sessions are not used on \"${WARDEN_ENV_SUBT}\" host environments."
fi

## attempt to install mutagen if not already present
if ! which mutagen >/dev/null; then
  echo -e "\033[33mMutagen could not be found; attempting install via brew.\033[0m"
  brew install havoc-io/mutagen/mutagen
fi

## verify mutagen version constraint
MUTAGEN_VERSION=$(mutagen version 2>/dev/null) || true
MUTAGEN_REQUIRE=0.11.8
if [[ $OSTYPE =~ ^darwin ]] && ! test $(version ${MUTAGEN_VERSION}) -ge $(version ${MUTAGEN_REQUIRE}); then
  error "Mutagen version ${MUTAGEN_REQUIRE} or greater is required (version ${MUTAGEN_VERSION} is installed)."
  >&2 printf "\nPlease update Mutagen:\n\n  brew upgrade havoc-io/mutagen/mutagen\n\n"
  exit 1
fi

if [[ $OSTYPE =~ ^darwin && -z "${MUTAGEN_SYNC_FILE}" ]]; then
    export MUTAGEN_SYNC_FILE="${WARDEN_DIR}/environments/${WARDEN_ENV_TYPE}/${WARDEN_ENV_TYPE}.mutagen.yml"

    if [[ -f "${WARDEN_HOME_DIR}/environments/${WARDEN_ENV_TYPE}/${WARDEN_ENV_TYPE}.mutagen.yml" ]]; then
        export MUTAGEN_SYNC_FILE="${WARDEN_HOME_DIR}/environments/${WARDEN_ENV_TYPE}/${WARDEN_ENV_TYPE}.mutagen.yml"
    fi

    if [[ -f "${WARDEN_ENV_PATH}/.warden/environments/${WARDEN_ENV_TYPE}/${WARDEN_ENV_TYPE}.mutagen.yml" ]]; then
        export MUTAGEN_SYNC_FILE="${WARDEN_ENV_PATH}/.warden/environments/${WARDEN_ENV_TYPE}/${WARDEN_ENV_TYPE}.mutagen.yml"
    fi

    if [[ -f "${WARDEN_ENV_PATH}/.warden/mutagen.yml" ]]; then
        export MUTAGEN_SYNC_FILE="${WARDEN_ENV_PATH}/.warden/mutagen.yml"
    fi
fi

## if no mutagen configuration file exists for the environment type, exit with error
if [[ ! -f "${MUTAGEN_SYNC_FILE}" ]]; then
  fatal "Mutagen configuration does not exist for environment type \"${WARDEN_ENV_TYPE}\""
fi

## sub-command execution
case "${WARDEN_PARAMS[0]}" in
    start)
        ## terminate any existing sessions with matching env label
        mutagen sync terminate --label-selector "warden-sync=${WARDEN_ENV_NAME}"

        ## create sync session based on environment type configuration
        mutagen sync create -c "${MUTAGEN_SYNC_FILE}" \
            --label "warden-sync=${WARDEN_ENV_NAME}" --ignore "${WARDEN_SYNC_IGNORE:-}" \
            "${WARDEN_ENV_PATH}${WARDEN_WEB_ROOT:-}" "docker://$($WARDEN_BIN env ps -q php-fpm)/var/www/html"

        ## wait for sync session to complete initial sync before exiting
        echo "Waiting for initial synchronization to complete"
        while ! mutagen sync list --label-selector "warden-sync=${WARDEN_ENV_NAME}" \
            | grep -i 'watching for changes'>/dev/null;
                do
                    if mutagen sync list --label-selector "warden-sync=${WARDEN_ENV_NAME}" \
                        | grep -i 'Last error' > /dev/null; then
                        MUTAGEN_ERROR=$(mutagen sync list --label-selector "warden-sync=${WARDEN_ENV_NAME}" \
                            | sed -n 's/Last error: \(.*\)/\1/p')
                        fatal "Mutagen encountered an error during sync: ${MUTAGEN_ERROR}"
                    fi
                    printf .; sleep 1; done; echo
        ;;
    stop)
        mutagen sync terminate --label-selector "warden-sync=${WARDEN_ENV_NAME}"
        ;;
    list|flush|monitor|pause|reset|resume)
        mutagen sync "${WARDEN_PARAMS[@]}" "${@}" --label-selector "warden-sync=${WARDEN_ENV_NAME}"
        ;;
    *)
        fatal "The command \"${WARDEN_PARAMS[0]}\" does not exist. Please use --help for usage."
        ;;
esac
