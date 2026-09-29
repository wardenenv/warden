#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

## Warden owns ${WARDEN_HOME_DIR}/etc/traefik/traefik.yml; it is generated configuration,
## not user state. After a Traefik major upgrade some settings, such as the router rule
## syntax, have to be adjusted globally for backward compatibility, and seeding the file
## once meant existing installs never received them.
##
## Override the service's volumes via ${WARDEN_HOME_DIR}/docker-compose.yml if you need
## Traefik to run against a hand-written static config.
##
## Returns 0 when the file was replaced, otherwise 1.
function refreshTraefikStaticConfig() {
    local source="${WARDEN_DIR}/config/traefik/traefik.yml"
    local target="${WARDEN_HOME_DIR}/etc/traefik/traefik.yml"

    if cmp -s "${source}" "${target}"; then
        return 1
    fi

    mkdir -p "$(dirname "${target}")"

    if [[ -f "${target}" ]]; then
        ## timestamped so a later refresh cannot clobber an earlier backup
        local backup
        backup="${target}.$(date +%Y%m%d-%H%M%S).bak"
        cp "${target}" "${backup}"
        echo "==> Refreshing ${target} from ${source}"
        echo "    Previous version saved as ${backup}"
    fi

    cp "${source}" "${target}"

    return 0
}

## Resolve the container id of Warden's own running Traefik. Matching on the Compose
## project labels keeps this scoped to the services 'warden svc' orchestrates, so a
## Traefik belonging to something else on the same daemon is never restarted.
function wardenTraefikContainerId() {
    docker container ls -q \
        --filter label=com.docker.compose.project=warden \
        --filter label=com.docker.compose.service=traefik \
        --filter status=running 2>/dev/null || true
}

## Refresh Traefik's static configuration, restarting Traefik when it changed. Traefik
## never reloads static configuration, and Compose will not recreate the container just
## because a bind mounted file changed, so the restart has to be explicit.
function assertTraefikStaticConfig() {
    refreshTraefikStaticConfig || return 0

    local traefikId
    traefikId="$(wardenTraefikContainerId)"

    if [[ -n "${traefikId}" ]]; then
        echo "==> Restarting traefik to apply the updated static configuration"
        docker restart "${traefikId}" >/dev/null
    fi
}

function assertSvcRunning() {
    ## test for global services running
    wardenNetworkName=$(cat ${WARDEN_DIR}/docker/docker-compose.yml | grep -A3 'networks:' | tail -n1 | sed -e 's/[[:blank:]]*name:[[:blank:]]*//g')
    wardenNetworkId=$(docker network ls -q --filter name="${wardenNetworkName}")

    if [[ -z "${wardenNetworkId}" ]]; then
        warning "Warden core services are not currently running.\033[0m Run \033[36mwarden svc up\033[0m to start Warden core services."
    fi
}
