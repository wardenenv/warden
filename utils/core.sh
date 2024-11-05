#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

## global service containers to be connected with the project docker network
DOCKER_PEERED_SERVICES=("traefik" "tunnel" "mailhog" "phpmyadmin")

## messaging functions
function warning {
  >&2 printf "\033[33mWARNING\033[0m: $@\n"
}

function error {
  >&2 printf "\033[31mERROR\033[0m: $@\n"
}

function fatal {
  error "$@"
  exit -1
}

function version {
  echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }';
}

## determines if value is present in an array; returns 0 if element is present
## in array, otherwise returns 1
##
## usage: containsElement <needle> <haystack>
##
function containsElement {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

## verify docker is running
function assertDockerRunning {
  if ! docker system info >/dev/null 2>&1; then
    fatal "Docker does not appear to be running. Please start Docker."
  fi
}

## methods to peer global services requiring network connectivity with project networks
function connectPeeredServices {
  for svc in ${DOCKER_PEERED_SERVICES[@]}; do
    echo "Connecting ${svc} to $1 network"
    (docker network connect "$1" ${svc} 2>&1| grep -v 'already exists in network') || true
  done
}

function disconnectPeeredServices {
  for svc in ${DOCKER_PEERED_SERVICES[@]}; do
    echo "Disconnecting ${svc} from $1 network"
    (docker network disconnect "$1" ${svc} 2>&1| grep -v 'is not connected') || true
  done
}
function regeneratePMAConfig() {
  if [[ -f "${WARDEN_HOME_DIR}/.env" ]]; then
    # Recheck PMA since old versions of .env may not have WARDEN_PHPMYADMIN_ENABLE setting
    eval "$(grep "^WARDEN_PHPMYADMIN_ENABLE" "${WARDEN_HOME_DIR}/.env")"
    WARDEN_PHPMYADMIN_ENABLE="${WARDEN_PHPMYADMIN_ENABLE:-1}"
  fi
  if [[ "${WARDEN_PHPMYADMIN_ENABLE}" == 1 ]]; then
    echo "Regenerating phpMyAdmin configuration..."
    pma_config_file="${WARDEN_HOME_DIR}/etc/phpmyadmin/config.user.inc.php"
    {
      echo "<?php"
      echo "\$i = 1;"
      for container_id in $(docker ps -q --filter "name=mysql" --filter "name=mariadb" --filter "name=db"); do
        container_name=$(docker inspect --format '{{.Name}}' "${container_id}" | sed 's#^/##')
        container_ip=$(docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "${container_id}")
        MYSQL_ROOT_PASSWORD=$(docker exec "${container_id}" printenv | grep MYSQL_ROOT_PASSWORD | awk -F '=' '{print $2}')
        echo "\$cfg['Servers'][\$i]['host'] = '${container_ip}';"
        echo "\$cfg['Servers'][\$i]['auth_type'] = 'config';"
        echo "\$cfg['Servers'][\$i]['user'] = 'root';"
        echo "\$cfg['Servers'][\$i]['password'] = '${MYSQL_ROOT_PASSWORD}';"
        echo "\$cfg['Servers'][\$i]['AllowNoPassword'] = true;"
        echo "\$cfg['Servers'][\$i]['hide_db'] = '(information_schema|performance_schema|mysql|sys)';"
        echo "\$cfg['Servers'][\$i]['verbose'] = '${container_name}';"
        echo "\$i++;"
      done
    } > "${pma_config_file}"
    echo "phpMyAdmin configuration regenerated."
  fi
}
