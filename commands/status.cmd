#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

assertDockerRunning

wardenNetworkName=$(cat ${WARDEN_DIR}/docker/docker-compose.yml | grep -A3 'networks:' | tail -n1 | sed -e 's/[[:blank:]]*name:[[:blank:]]*//g')
wardenNetworkId=$(docker network ls -q --filter name="${wardenNetworkName}")

if [[ -z "${wardenNetworkId}" ]]; then
    echo -e "[\033[33;1m!!\033[0m] \033[31mWarden is not currently running.\033[0m Run \033[36mwarden svc up\033[0m to start Warden core services."
fi

OLDIFS="$IFS";
IFS=$'\n'
projectNetworkList=( $(docker network ls --format '{{.Name}}' -q --filter "label=dev.warden.environment.name") )
IFS="$OLDIFS"

messageList=()
for projectNetwork in "${projectNetworkList[@]}"; do
    # Skip empty names and the Warden core services network
    test -z "${projectNetwork}" -o "${projectNetwork}" = "${wardenNetworkName}" && continue

    prefix="${projectNetwork%_default}"
    prefixLen="${#prefix}"
    ((prefixLen+=1))
    projectContainers=$(docker network inspect --format '{{ range $k,$v := .Containers }}{{ $nameLen := len $v.Name }}{{ if gt $nameLen '"${prefixLen}"' }}{{ $prefix := slice $v.Name 0 '"${prefixLen}"' }}{{ if eq $prefix "'"${prefix}-"'" }}{{ println $v.Name }}{{end}}{{end}}{{end}}' "${projectNetwork}")
    container=$(echo "$projectContainers" | head -n1)

    [[ -z "${container}" ]] && continue # Project is not running, skip it

    projectDir=$(docker container inspect --format '{{ index .Config.Labels "com.docker.compose.project.working_dir"}}' "$container")
    projectName=$(cat "${projectDir}/.env" | grep '^WARDEN_ENV_NAME=' | sed -e 's/WARDEN_ENV_NAME=[[:space:]]*//g')
    projectType=$(cat "${projectDir}/.env" | grep '^WARDEN_ENV_TYPE=' | sed -e 's/WARDEN_ENV_TYPE=[[:space:]]*//g')
    traefikDomain=$(cat "${projectDir}/.env" | grep '^TRAEFIK_DOMAIN=' | sed -e 's/TRAEFIK_DOMAIN=[[:space:]]*//g')
    traefikSubdomain=$(cat "${projectDir}/.env" | grep '^TRAEFIK_SUBDOMAIN=' | sed -e 's/TRAEFIK_SUBDOMAIN=[[:space:]]*//g')

    fullDomain="${traefikDomain}"
    if test -n "${traefikSubdomain}"; then
        fullDomain="${traefikSubdomain}.${traefikDomain}"
    fi

    messageList+=("    \033[1;35m${projectName}\033[0m a \033[36m${projectType}\033[0m project")
    messageList+=("       Project Directory: \033[33m${projectDir}\033[0m")
    messageList+=("       Project URL: \033[94mhttps://${fullDomain}\033[0m")

    [[ "$projectNetwork" != "${projectNetworkList[@]: -1:1}" ]] && messageList+=()
done

if [[ "${#messageList[@]}" > 0 ]]; then
    if [[ -z "${wardenNetworkId}" ]]; then
        echo -e "Found the following \033[32mrunning\033[0m projects; however, \033[31mWarden core services are currently not running\033[0m:"
    else
        echo -e "Found the following \033[32mrunning\033[0m environments:"
    fi
    for line in "${messageList[@]}"; do
        echo -e "$line"
    done
else
    echo "No running environments found."
fi
