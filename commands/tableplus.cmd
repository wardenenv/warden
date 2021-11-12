#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

if [[ "$OSTYPE" != "darwin"* ]]; then
   fatal "Tableplus command does only works for Mac Os"
fi

WARDEN_ENV_PATH="$(locateEnvPath)" || exit $?
loadEnvConfig "${WARDEN_ENV_PATH}" || exit $?
assertDockerRunning

if [[ ${WARDEN_DB:-1} -eq 0 ]]; then
  fatal "Database environment is not used (WARDEN_DB=0)."
fi

### load connection information for the mysql service
DB_CONTAINER=$(warden env ps -q db)
if [[ ! ${DB_CONTAINER} ]]; then
    fatal "No container found for db service."
fi

eval "$(
    docker container inspect ${DB_CONTAINER} --format '
        {{- range .Config.Env }}{{with split . "=" -}}
            {{- index . 0 }}='\''{{ range $i, $v := . }}{{ if $i }}{{ $v }}{{ end }}{{ end }}'\''{{println}}
        {{- end }}{{ end -}}
    ' | grep "^MYSQL_"
)"

eval "MYSQL_HOST=$(docker container inspect ${DB_CONTAINER} --format='{{.Name}}' | cut -c2-)"

query="mysql+ssh://user@tunnel.warden.test:2222/${MYSQL_USER}:${MYSQL_PASSWORD}@${MYSQL_HOST}/${MYSQL_DATABASE}?enviroment=local&name=${WARDEN_ENV_NAME}&tLSMode=0&usePrivateKey=true"
open "$query" -a "/Applications/TablePlus.app/Contents/MacOS/TablePlus"
