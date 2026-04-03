#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

WARDEN_ENV_PATH="$(locateEnvPath)" || exit $?
loadEnvConfig "${WARDEN_ENV_PATH}" || exit $?
assertDockerRunning

## warn if global services are not running
if [[ "${WARDEN_PARAMS[0]}" == "up" ]]; then
    assertSvcRunning
fi

HOST_UID=$(id -u)
HOST_GID=$(id -g)

if (( ${#WARDEN_PARAMS[@]} == 0 )) || [[ "${WARDEN_PARAMS[0]}" == "help" ]]; then
  # shellcheck disable=SC2153
  $WARDEN_BIN env --help || exit $? && exit $?
fi

## allow return codes from sub-process to bubble up normally
trap '' ERR

## define source repository
if [[ -f "${WARDEN_HOME_DIR}/.env" ]]; then
  eval "$(sed 's/\r$//g' < "${WARDEN_HOME_DIR}/.env" | grep "^WARDEN_")"
fi
export WARDEN_IMAGE_REPOSITORY="${WARDEN_IMAGE_REPOSITORY:-"docker.io/wardenenv"}"

export WARDEN_DOCKER_USERNS_MODE="${WARDEN_DOCKER_USERNS_MODE:-host}"

## configure environment type defaults
if [[ ${WARDEN_ENV_TYPE} =~ ^magento ]]; then
    export WARDEN_SVC_PHP_VARIANT=-${WARDEN_ENV_TYPE}
fi
if [[ ${WARDEN_NIGHTLY} -eq 1 ]]; then
    export WARDEN_SVC_PHP_IMAGE_SUFFIX="-indev"
fi

## configure xdebug version
export XDEBUG_VERSION="debug" # xdebug2 image
if [[ ${PHP_XDEBUG_3} -eq 1 ]]; then
    export XDEBUG_VERSION="xdebug3"
fi

if [[ ${WARDEN_ENV_TYPE} != local ]]; then
    WARDEN_NGINX=${WARDEN_NGINX:-1}
    WARDEN_DB=${WARDEN_DB:-1}
    WARDEN_REDIS=${WARDEN_REDIS:-1}

    # define bash history folder for changing permissions
    WARDEN_CHOWN_DIR_LIST="/bash_history /home/www-data/.ssh ${WARDEN_CHOWN_DIR_LIST:-}"
fi
export CHOWN_DIR_LIST=${WARDEN_CHOWN_DIR_LIST:-}

if [[ ${WARDEN_ENV_TYPE} == "magento1" && -f "${WARDEN_ENV_PATH}/.modman/.basedir" ]]; then
  NGINX_PUBLIC='/'$(cat "${WARDEN_ENV_PATH}/.modman/.basedir")
  export NGINX_PUBLIC
fi

if [[ ${WARDEN_ENV_TYPE} == "magento2" ]]; then
    WARDEN_VARNISH=${WARDEN_VARNISH:-1}
    WARDEN_ELASTICSEARCH=${WARDEN_ELASTICSEARCH:-1}
    WARDEN_RABBITMQ=${WARDEN_RABBITMQ:-1}
    WARDEN_MAGENTO2_GRAPHQL_SERVER=${WARDEN_MAGENTO2_GRAPHQL_SERVER:-0}
    WARDEN_MAGENTO2_GRAPHQL_SERVER_DEBUG=${WARDEN_MAGENTO2_GRAPHQL_SERVER_DEBUG:-0}
fi

## WSL1/WSL2 are GNU/Linux env type but still run Docker Desktop
if [[ ${XDEBUG_CONNECT_BACK_HOST} == '' ]] && grep -sqi microsoft /proc/sys/kernel/osrelease; then
    export XDEBUG_CONNECT_BACK_HOST=host.docker.internal
fi

## For linux, if UID is 1000, there is no need to use the socat proxy.
if [[ ${WARDEN_ENV_SUBT} == "linux" && $UID == 1000 ]]; then
    export SSH_AUTH_SOCK_PATH_ENV=/run/host-services/ssh-auth.sock
fi

## configure docker compose files
DOCKER_COMPOSE_ARGS=()

appendEnvPartialIfExists "networks"

if [[ ${WARDEN_ENV_TYPE} != local ]]; then
    appendEnvPartialIfExists "php-fpm"
fi

[[ ${WARDEN_NGINX} -eq 1 ]] \
    && appendEnvPartialIfExists "nginx"

[[ ${WARDEN_DB} -eq 1 ]] \
    && appendEnvPartialIfExists "db"

[[ ${WARDEN_ELASTICSEARCH} -eq 1 ]] \
    && appendEnvPartialIfExists "elasticsearch"

[[ ${WARDEN_ELASTICHQ:=1} -eq 1 ]] \
    && appendEnvPartialIfExists "elastichq"

[[ ${WARDEN_OPENSEARCH} -eq 1 ]] \
    && appendEnvPartialIfExists "opensearch"

[[ ${WARDEN_VARNISH} -eq 1 ]] \
    && appendEnvPartialIfExists "varnish"

[[ ${WARDEN_RABBITMQ} -eq 1 ]] \
    && appendEnvPartialIfExists "rabbitmq"

[[ ${WARDEN_REDIS} -eq 1 ]] \
    && appendEnvPartialIfExists "redis"

[[ ${WARDEN_VALKEY:=0} -eq 1 ]] \
    && appendEnvPartialIfExists "valkey"

appendEnvPartialIfExists "${WARDEN_ENV_TYPE}"

[[ ${WARDEN_TEST_DB} -eq 1 ]] \
    && appendEnvPartialIfExists "${WARDEN_ENV_TYPE}.tests"

[[ ${WARDEN_SPLIT_SALES} -eq 1 ]] \
    && appendEnvPartialIfExists "${WARDEN_ENV_TYPE}.splitdb.sales"

[[ ${WARDEN_SPLIT_CHECKOUT} -eq 1 ]] \
    && appendEnvPartialIfExists "${WARDEN_ENV_TYPE}.splitdb.checkout"

if [[ ${WARDEN_BLACKFIRE} -eq 1 ]]; then
    appendEnvPartialIfExists "blackfire"
    appendEnvPartialIfExists "${WARDEN_ENV_TYPE}.blackfire"
fi

[[ ${WARDEN_ALLURE} -eq 1 ]] \
    && appendEnvPartialIfExists "allure"

[[ ${WARDEN_SELENIUM} -eq 1 ]] \
    && appendEnvPartialIfExists "selenium"

[[ ${WARDEN_MAGEPACK} -eq 1 ]] \
    && appendEnvPartialIfExists "${WARDEN_ENV_TYPE}.magepack"

[[ ${WARDEN_MAGENTO2_GRAPHQL_SERVER} -eq 1 ]] \
    && appendEnvPartialIfExists "${WARDEN_ENV_TYPE}.graphql"
[[ ${WARDEN_MAGENTO2_GRAPHQL_SERVER_DEBUG} -eq 1 ]] \
    && appendEnvPartialIfExists "${WARDEN_ENV_TYPE}.graphql-debug"

[[ ${WARDEN_PHP_SPX} -eq 1 ]] \
    && appendEnvPartialIfExists "php-spx"

if [[ -f "${WARDEN_ENV_PATH}/.warden/warden-env.yml" ]]; then
    DOCKER_COMPOSE_ARGS+=("-f")
    DOCKER_COMPOSE_ARGS+=("${WARDEN_ENV_PATH}/.warden/warden-env.yml")
fi

if [[ -f "${WARDEN_ENV_PATH}/.warden/warden-env.${WARDEN_ENV_SUBT}.yml" ]]; then
    DOCKER_COMPOSE_ARGS+=("-f")
    DOCKER_COMPOSE_ARGS+=("${WARDEN_ENV_PATH}/.warden/warden-env.${WARDEN_ENV_SUBT}.yml")
fi

if [[ ${WARDEN_SELENIUM_DEBUG} -eq 1 ]]; then
    export WARDEN_SELENIUM_DEBUG="-debug"
else
    export WARDEN_SELENIUM_DEBUG=
fi

## disconnect peered service containers from environment network
if [[ "${WARDEN_PARAMS[0]}" == "down" ]]; then
    disconnectPeeredServices "$(renderEnvNetworkName)"

    ## regenerate PMA config on each env changing
    regeneratePMAConfig
fi

## connect peered service containers to environment network
if [[ "${WARDEN_PARAMS[0]}" == "up" ]]; then
    ## create environment network for attachments if it does not already exist
    if [[ $(docker network ls -f "name=$(renderEnvNetworkName)" -q) == "" ]]; then
        ${DOCKER_COMPOSE_COMMAND} \
            --project-directory "${WARDEN_ENV_PATH}" -p "${WARDEN_ENV_NAME}" \
            "${DOCKER_COMPOSE_ARGS[@]}" up --no-start
    fi

    ## connect globally peered services to the environment network
    connectPeeredServices "$(renderEnvNetworkName)"

    ## always execute env up using --detach mode
    if ! (containsElement "-d" "$@" || containsElement "--detach" "$@"); then
        WARDEN_PARAMS=("${WARDEN_PARAMS[@]:1}")
        WARDEN_PARAMS=(up -d "${WARDEN_PARAMS[@]}")
    fi

    ## regenerate PMA config on each env changing
    regeneratePMAConfig
fi

## lookup address of traefik container on environment network
TRAEFIK_ADDRESS="$(docker container inspect traefik \
    --format '
        {{- $network := index .NetworkSettings.Networks "'"$(renderEnvNetworkName)"'" -}}
        {{- if $network }}{{ $network.IPAddress }}{{ end -}}
    ' 2>/dev/null || true
)"
export TRAEFIK_ADDRESS;

if [[ ${WARDEN_MUTAGEN_ENABLE} -eq 1 ]]; then
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

## pause mutagen sync if needed
if [[ "${WARDEN_PARAMS[0]}" == "stop" ]] \
    && [[ ${WARDEN_MUTAGEN_ENABLE} -eq 1 ]] && [[ -f "${MUTAGEN_SYNC_FILE}" ]]
then
    $WARDEN_BIN sync pause
fi

## pass orchestration through to docker compose
${DOCKER_COMPOSE_COMMAND} \
    --project-directory "${WARDEN_ENV_PATH}" -p "${WARDEN_ENV_NAME}" \
    "${DOCKER_COMPOSE_ARGS[@]}" "${WARDEN_PARAMS[@]}" "$@"


if [[ "${WARDEN_PARAMS[0]}" == "stop" || "${WARDEN_PARAMS[0]}" == "down" || \
      "${WARDEN_PARAMS[0]}" == "up" || "${WARDEN_PARAMS[0]}" == "start" ]]; then
    regeneratePMAConfig
fi


##
# Categorize Mutagen sync sessions by container match status
#
# Analyzes sync sessions and categorizes them as MATCH or MISMATCH based on
# whether their container ID matches the current running container.
#
# @param $1 sync_list_output - The raw output from 'warden sync list' command
# @param $2 ref_container_id - The ID of the currently running container
# @param $3 status - Optional status to filter by (e.g., "Status: Paused", "Connected: Yes", or "0" for all)
#
# @output Lines in format: "MATCH:session_id" or "MISMATCH:session_id"
# @return 0 on success
##
categorizeSyncSessions() {
    local sync_list_output="$1"
    local ref_container_id="$2"
    local status="${3:-0}"

    # AWK Pattern: Capture session identifier
    local capture_identifier_awk='
        /Identifier: / {
            id=$2
            has_id=1
            has_docker=0
        }
    '

    # AWK Pattern: Extract container ID from docker URL
    local extract_container_id_awk='
        /URL: docker:/ {
            container_id=$0
            sub(/.*docker:\/\//, "", container_id)
            sub(/\/.*/, "", container_id)
            has_docker=1
        }
    '

    # AWK Pattern: Categorize sessions by container match with optional status filter
    local categorize_by_container_awk='
        (!status_filter || $0 ~ status_filter) && has_id && has_docker {
            if (has_id && has_docker) {
                if (container_id == container_filter) {
                    print "MATCH:" id
                } else {
                    print "MISMATCH:" id
                }
                has_id=0
                has_docker=0
            }
        }
    '

    echo "$sync_list_output" | awk \
        -v container_filter="$ref_container_id" \
        -v status_filter="$status" \
        "$capture_identifier_awk $extract_container_id_awk $categorize_by_container_awk"
}

## If we're using Mutagen
if [[ ${WARDEN_MUTAGEN_ENABLE} -eq 1 ]] && [[ -f "${MUTAGEN_SYNC_FILE}" ]]
then
    MUTAGEN_VERSION=$(mutagen version)
    CONNECTION_STATE_STRING='Connected state: Connected'
    if [[ $((10#$(version "${MUTAGEN_VERSION}"))) -ge $((10#$(version '0.15.0'))) ]]; 
    then
        CONNECTION_STATE_STRING='Connected: Yes'
    fi

    CURRENT_CONTAINER_ID=$($WARDEN_BIN env ps -q php-fpm)

    if { [[ "${WARDEN_PARAMS[0]}" == "up" ]] || [[ "${WARDEN_PARAMS[0]}" == "start" ]]; } \
        && [[ $CURRENT_CONTAINER_ID ]] \
        && [[ $(docker container inspect "${CURRENT_CONTAINER_ID}" --format '{{ .State.Status }}') = "running" ]]
    then
        # Get all mutagen sessions for this environment: separate matching and mismatched containers
        SYNC_LIST_OUTPUT=$($WARDEN_BIN sync list)

        ALL_SESSIONS=$(categorizeSyncSessions "$SYNC_LIST_OUTPUT" "$CURRENT_CONTAINER_ID")

        # Terminate sessions with mismatched containers
        MISMATCHED_SESSIONS=$(echo "${ALL_SESSIONS}" | grep "^MISMATCH:" | cut -d: -f2)
        if [[ -n ${MISMATCHED_SESSIONS} ]]; 
        then
            echo "Terminating sync sessions with outdated container references"
            while IFS= read -r session_id; do
                echo "  - Terminating ${session_id}"
                mutagen sync terminate "${session_id}"
            done <<< "${MISMATCHED_SESSIONS}"
        fi

        ## == mutagen sync resume ==

        # Match paused sessions
        PAUSED_MATCHED_SESSIONS=$(categorizeSyncSessions "$SYNC_LIST_OUTPUT" "$CURRENT_CONTAINER_ID" "Status: \\\[Paused\\\]" | grep "^MATCH:" | cut -d: -f2)

        if [[ -z "${PAUSED_MATCHED_SESSIONS}" ]]; then
            PAUSED_MATCHING_COUNT=0
        else
            PAUSED_MATCHING_COUNT=$(echo "${PAUSED_MATCHED_SESSIONS}" | grep -c .)
        fi

        # Resume all valid paused sessions if there are any
        if [[ ${PAUSED_MATCHING_COUNT} -gt 0 ]]; then
            echo "Resuming ${PAUSED_MATCHING_COUNT} paused sync sessions"
            while IFS= read -r session_id; do
                echo "  - ${session_id}"
            done <<< "${PAUSED_MATCHED_SESSIONS}"
            $WARDEN_BIN sync resume
        fi

        ## == mutagen sync start ==

        # Get all mutagen sessions for this environment (re-run because statuses changed after resume)
        SYNC_LIST_OUTPUT=$($WARDEN_BIN sync list)

        # Count connected sessions for current container
        CONNECTED_MATCHED_SESSIONS=$(categorizeSyncSessions "$SYNC_LIST_OUTPUT" "$CURRENT_CONTAINER_ID" "$CONNECTION_STATE_STRING" | grep "^MATCH:" | cut -d: -f2)

        if [[ -z "${CONNECTED_MATCHED_SESSIONS}" ]]; then
            CONNECTED_COUNT=0
        else
            CONNECTED_COUNT=$(echo "${CONNECTED_MATCHED_SESSIONS}" | grep -c .)
        fi

        # Start sync only if zero connected sessions for current container
        if [[ ${CONNECTED_COUNT} -eq 0 ]]; then
            echo "Starting mutagen sync (no connected sessions found)"
            $WARDEN_BIN sync start
        fi
    fi

    ## == mutagen sync stop ==
    if [[ "${WARDEN_PARAMS[0]}" == "down" ]]
    then
        $WARDEN_BIN sync stop
    fi
fi