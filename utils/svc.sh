#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

function assertSvcRunning() {
    ## test for global services running
    wardenNetworkName=$(cat ${WARDEN_DIR}/docker/docker-compose.yml | grep -A3 'networks:' | tail -n1 | sed -e 's/[[:blank:]]*name:[[:blank:]]*//g')
    wardenNetworkId=$(docker network ls -q --filter name="${wardenNetworkName}")

    if [[ -z "${wardenNetworkId}" ]]; then
        warning "Warden core services are not currently running.\033[0m Run \033[36mwarden svc up\033[0m to start Warden core services."
    fi
}
