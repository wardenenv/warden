#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

assertDockerRunning

wardenNetworkName=$(cat ${WARDEN_DIR}/docker/docker-compose.yml | grep -A3 'networks:' | tail -n1 | sed -e 's/[[:blank:]]*name:[[:blank:]]*//g')
wardenNetworkId=$(docker network ls -q --filter name="${wardenNetworkName}")

if [[ -z "${wardenNetworkId}" ]]; then
    echo -e "🛑 \033[31mDen is not currently running.\033[0m Run \033[36mwarden svc up\033[0m to start Den core services."
    exit 0
fi

wardenTraefikId=$(docker container ls --filter network="${wardenNetworkId}" --filter status=running --filter name=traefik -q)
projectNetworks=$(docker container inspect --format '{{ range $k,$v := .NetworkSettings.Networks }}{{ if ne $k "${wardenNetworkName}" }}{{println $k }}{{ end }}{{end}}' "${wardenTraefikId}")
OLDIFS="$IFS";
IFS=$'\n'
projectNetworkList=($projectNetworks)
IFS="$OLDIFS"

messageList=()
for projectNetwork in "${projectNetworkList[@]}"; do
    [[ -z "${projectNetwork}" || "${projectNetwork}" == "${wardenNetworkName}" ]] && continue # Skip empty project network names (if any)

    prefix="${projectNetwork%_default}"
    prefixLen="${#prefix}"
    ((prefixLen+=1))
    projectContainers=$(docker network inspect --format '{{ range $k,$v := .Containers }}{{ $nameLen := len $v.Name }}{{ if gt $nameLen '"${prefixLen}"' }}{{ $prefix := slice $v.Name 0 '"${prefixLen}"' }}{{ if eq $prefix "'"${prefix}-"'" }}{{ println $v.Name }}{{end}}{{end}}{{end}}' "${projectNetwork}")
    container=$(echo "$projectContainers" | head -n1)

    [[ -z "${container}" ]] && continue # Project is not running, skip it

    projectDir=$(docker container inspect --format '{{ index .Config.Labels "com.docker.compose.project.working_dir"}}' "$container")
    projectName=$(cat "${projectDir}/.env" | grep '^WARDEN_ENV_NAME=' | sed -e 's/WARDEN_ENV_NAME=[[:space:]]*//g' | tr -d -)
    projectType=$(cat "${projectDir}/.env" | grep '^WARDEN_ENV_TYPE=' | sed -e 's/WARDEN_ENV_TYPE=[[:space:]]*//g' | tr -d -)
    traefikDomain=$(cat "${projectDir}/.env" | grep '^TRAEFIK_DOMAIN=' | sed -e 's/TRAEFIK_DOMAIN=[[:space:]]*//g' | tr -d -)

    messageList+=("    \033[1;35m${projectName}\033[0m a \033[36m${projectType}\033[0m project")
    messageList+=("       Project Directory: \033[33m${projectDir}\033[0m")
    messageList+=("       Project URL: \033[94mhttps://${traefikDomain}\033[0m")

    [[ "$projectNetwork" != "${projectNetworkList[@]: -1:1}" ]] && messageList+=()
done

if [[ "${#messageList[@]}" > 0 ]]; then
    echo -e "Found the following \033[32mrunning\033[0m environments:"
    for line in "${messageList[@]}"; do
        echo -e "$line"
    done
else
    echo "No running environments found."
fi