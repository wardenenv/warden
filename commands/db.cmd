#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

WARDEN_ENV_PATH="$(locateEnvPath)" || exit $?
loadEnvConfig "${WARDEN_ENV_PATH}" || exit $?
assertDockerRunning

if [[ ${WARDEN_DB:-1} -eq 0 ]]; then
  fatal "Database environment is not used (WARDEN_DB=0)."
fi

if (( ${#WARDEN_PARAMS[@]} == 0 )) || [[ "${WARDEN_PARAMS[0]}" == "help" ]]; then
  $WARDEN_BIN db --help || exit $? && exit $?
fi

## load connection information for the database service
DB_CONTAINER=$($WARDEN_BIN env ps -q db)
if [[ ! ${DB_CONTAINER} ]]; then
    fatal "No container found for db service."
fi

## detect database type and load appropriate connection variables
DB_ENV_OUTPUT="$(
    docker container inspect ${DB_CONTAINER} --format '
        {{- range .Config.Env }}{{with split . "=" -}}
            {{- index . 0 }}='\''{{ range $i, $v := . }}{{ if $i }}{{ $v }}{{ end }}{{ end }}'\''{{println}}
        {{- end }}{{ end -}}
    '
)"

DB_TYPE="mysql"
if echo "${DB_ENV_OUTPUT}" | grep -q "^POSTGRES_"; then
    DB_TYPE="postgres"
fi

eval "$(echo "${DB_ENV_OUTPUT}" | grep "^${DB_TYPE^^}_")"

## sub-command execution
case "${WARDEN_PARAMS[0]}" in
    connect)
        if [[ "${DB_TYPE}" == "postgres" ]]; then
            PGPASSWORD="${POSTGRES_PASSWORD}" "$WARDEN_BIN" env exec db \
                psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" "${WARDEN_PARAMS[@]:1}" "$@"
        else
            "$WARDEN_BIN" env exec db \
                mysql -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --database="${MYSQL_DATABASE}" "${WARDEN_PARAMS[@]:1}" "$@"
        fi
        ;;
    import)
        if [[ "${DB_TYPE}" == "postgres" ]]; then
            PGPASSWORD="${POSTGRES_PASSWORD}" "$WARDEN_BIN" env exec -T db \
                psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" "${WARDEN_PARAMS[@]:1}" "$@"
        else
            LC_ALL=C sed -E 's/DEFINER[ ]*=[ ]*`[^`]+`@`[^`]+`/DEFINER=CURRENT_USER/g' \
                | LC_ALL=C sed -E '/\@\@(GLOBAL\.GTID_PURGED|SESSION\.SQL_LOG_BIN)/d' \
                | "$WARDEN_BIN" env exec -T db \
                mysql -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --database="${MYSQL_DATABASE}" "${WARDEN_PARAMS[@]:1}" "$@"
        fi
        ;;
    dump)
        if [[ "${DB_TYPE}" == "postgres" ]]; then
            PGPASSWORD="${POSTGRES_PASSWORD}" "$WARDEN_BIN" env exec -T db \
                pg_dump -U "${POSTGRES_USER}" "${POSTGRES_DB:-${POSTGRES_USER}}" "${WARDEN_PARAMS[@]:1}" "$@"
        else
            "$WARDEN_BIN" env exec -T db \
                mysqldump -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" "${MYSQL_DATABASE}" "${WARDEN_PARAMS[@]:1}" "$@"
        fi
        ;;
    *)
        fatal "The command \"${WARDEN_PARAMS[0]}\" does not exist. Please use --help for usage."
        ;;
esac
