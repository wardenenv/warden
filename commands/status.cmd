#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

wardenNetworkName=$(sed -n '/^networks:/,/^[^[:space:]]/s/^[[:space:]]*name:[[:space:]]*//p' "${WARDEN_DIR}/docker/docker-compose.yml")

## List core and project networks in one request; a failure here means Docker is not running.
if ! networkList=$(docker network ls --format '{{.Name}}{{"\t"}}{{.Label "dev.warden.environment.name"}}' 2>/dev/null); then
    fatal "Docker does not appear to be running. Please start Docker."
fi

wardenNetworkFound=
projectNetworks=""
while IFS=$'\t' read -r networkName environmentName; do
    if [[ "${networkName}" == "${wardenNetworkName}" ]]; then
        wardenNetworkFound=1
    elif [[ -n "${environmentName}" ]]; then
        projectNetworks+=" ${networkName}"
    fi
done <<< "${networkList}"

if [[ -z "${wardenNetworkFound}" ]]; then
    echo -e "[\033[33;1m!!\033[0m] \033[31mWarden is not currently running.\033[0m Run \033[36mwarden svc up\033[0m to start Warden core services."
fi

## One line per running Compose project: its default network name and working directory.
runningProjectList=""
if [[ -n "${projectNetworks}" ]]; then
    runningProjectList=$(set -o pipefail; docker container ls --filter label=com.docker.compose.project.working_dir \
        --format '{{.Label "com.docker.compose.project"}}_default{{"\t"}}{{.Label "com.docker.compose.project.working_dir"}}' \
        | LC_ALL=C sort -t $'\t' -u -k1,1)
fi

messageList=()
while IFS=$'\t' read -r projectNetwork projectDir; do
    # Skip Compose projects that are not Warden environments
    [[ "${projectNetworks} " == *" ${projectNetwork} "* ]] || continue

    unset WARDEN_ENV_NAME WARDEN_ENV_TYPE TRAEFIK_DOMAIN TRAEFIK_SUBDOMAIN
    for envFile in "${projectDir}/.env" "${projectDir}/.env.local"; do
        loadEnvFile "${envFile}" '(WARDEN_ENV_NAME|WARDEN_ENV_TYPE|TRAEFIK_DOMAIN|TRAEFIK_SUBDOMAIN)$'
    done

    fullDomain="${TRAEFIK_DOMAIN}"
    if [[ -n "${TRAEFIK_SUBDOMAIN}" ]]; then
        fullDomain="${TRAEFIK_SUBDOMAIN}.${TRAEFIK_DOMAIN}"
    fi

    if (( ${#messageList[@]} > 0 )); then
        messageList+=("")
    fi
    messageList+=("    \033[1;35m${WARDEN_ENV_NAME}\033[0m a \033[36m${WARDEN_ENV_TYPE}\033[0m project")
    messageList+=("       Project Directory: \033[33m${projectDir}\033[0m")
    messageList+=("       Project URL: \033[94mhttps://${fullDomain}\033[0m")
done <<< "${runningProjectList}"

if (( ${#messageList[@]} > 0 )); then
    if [[ -z "${wardenNetworkFound}" ]]; then
        echo -e "Found the following \033[32mrunning\033[0m projects; however, \033[31mWarden core services are currently not running\033[0m:"
    else
        echo -e "Found the following \033[32mrunning\033[0m environments:"
    fi
    for line in "${messageList[@]}"; do
        echo -e "${line}"
    done
else
    echo "No running environments found."
fi
