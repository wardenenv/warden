#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

eval "$(
    docker container inspect ${DB_CONTAINER} --format '
        {{- range .Config.Env }}{{with split . "=" -}}
            {{- index . 0 }}='\''{{ range $i, $v := . }}{{ if $i }}{{ $v }}{{ end }}{{ end }}'\''{{println}}
        {{- end }}{{ end -}}
    ' | grep "^MYSQL_"
)"

## sub-command execution
case "${WARDEN_PARAMS[0]}" in
    connect)
        "$WARDEN_BIN" env exec db \
            mysql -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --database="${MYSQL_DB}" "${WARDEN_PARAMS[@]:1}" "$@"
        ;;
    import)
        LC_ALL=C sed -E 's/DEFINER[ ]*=[ ]*`[^`]+`@`[^`]+`/DEFINER=CURRENT_USER/g' \
            | LC_ALL=C sed -E '/\@\@(GLOBAL\.GTID_PURGED|SESSION\.SQL_LOG_BIN)/d' \
            | "$WARDEN_BIN" env exec -T db \
            mysql -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --database="${MYSQL_DATABASE}" "${WARDEN_PARAMS[@]:1}" "$@"
        ;;
    dump)
            "$WARDEN_BIN" env exec -T db \
            mysqldump -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" "${MYSQL_DATABASE}" "${WARDEN_PARAMS[@]:1}" "$@"
        ;;
    *)
        fatal "The command \"${WARDEN_PARAMS[0]}\" does not exist. Please use --help for usage."
        ;;
esac
