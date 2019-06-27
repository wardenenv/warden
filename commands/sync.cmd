#!/usr/bin/env bash
[[ ! ${WARDEN_COMMAND} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!" && exit 1

source "${WARDEN_DIR}/utils/env.sh"
WARDEN_ENV_PATH="$(locateEnvPath)" || exit $?
loadEnvConfig "${WARDEN_ENV_PATH}" || exit $?

if (( ${#WARDEN_PARAMS[@]} == 0 )); then
    echo -e "\033[33mThis command has required params, please use --help for details."
    exit 1
fi

## attempt to install mutagen if not already present
if ! which mutagen >/dev/null; then
    echo -e "\033[33mMutagen could not be found; attempting install via brew.\033[0m"
    brew install havoc-io/mutagen/mutagen
fi

## if no mutagen configuration file exists for the environment type, exit with error
[[ ! -f "${WARDEN_DIR}/environments/${WARDEN_ENV_TYPE}.mutagen.toml" ]] \
    && >&2 echo -e "\033[31mMutagen configuration does not exist for environment type \"${WARDEN_ENV_TYPE}\"" && exit 1

## sub-command execution
case "${WARDEN_PARAMS[0]}" in
    start)
        ## start mutagen daemon if not already running
        mutagen daemon start

        ## terminate any existing sessions with matching env label
        mutagen terminate --label-selector "warden-sync=${WARDEN_ENV_NAME}"

        ## create sync session based on environment type configuration
        mutagen create -c "${WARDEN_DIR}/environments/${WARDEN_ENV_TYPE}.toml" \
            --label "warden-sync=${WARDEN_ENV_NAME}" \
            "${WARDEN_ENV_PATH}${WARDEN_WEB_ROOT:-}" "docker://$(warden env ps -q php-fpm)/var/www/html"
        
        ## wait for sync session to complete initial sync before exiting
        echo "Waiting for initial synchronization to complete"
        while !  mutagen list --label-selector "warden-sync=${WARDEN_ENV_NAME}" \
            | grep -i 'watching for changes'>/dev/null; do printf .; sleep 1; done; echo
        ;;
    stop)
        ## terminate only sessions labeled with this env name
        mutagen terminate --label-selector "warden-sync=${WARDEN_ENV_NAME}"
        ;;
    list)
        ## list only sessions labeled with this env name
        [[ ${WARDEN_VERBOSE} ]] && MUTAGEN_ARGS=" -l " || MUTAGEN_ARGS=
        mutagen list ${MUTAGEN_ARGS} --label-selector "warden-sync=${WARDEN_ENV_NAME}"
        ;;
    *)
        echo -e "\033[33mThe command \"${WARDEN_PARAMS[0]}\" does not exist. Please use --help for usage."
        exit 1
        ;;
esac
