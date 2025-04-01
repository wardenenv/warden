#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

## Disable immediate exit on failure (set in main warden bin), we use this to detect whether docker is running and continue.
set +e

## Allow return codes from sub-process to bubble up normally, necessary for command testing
trap '' ERR

# The warden doctor command is designed to collect information useful in reasoning about the
# state of a system and configuration warden is running with.

if [[ ${OSTYPE} =~ ^darwin ]]; then
    echo -e "\033[032mHost information:\033[0m"
    sw_vers --productName
    sw_vers --productVersion
fi
echo

echo -e "\033[32mOS, version, architecture:\033[0m"
uname -orm
echo

command -v brew &>/dev/null
if [[ $? -eq 0 ]]; then
    echo -e "\033[32mHomebrew information:\033[0m"
    brew config
fi
echo

echo -e "\033[32mContainer runtime and compose information:\033[0m"
docker --version
${DOCKER_COMPOSE_COMMAND} version
echo

echo -e "\033[32mWarden version:\033[0m"
echo ${WARDEN_BIN} version
echo

echo -e "\033[32mWarden global .env:\033[0m"
cat ~/.warden/.env
echo

echo -e "\033[32mWarden service override via Docker compose file:\033[0m"
if [[ -f ~/.warden/docker-compose.yml ]]; then
    echo -e "\033[33mWarden services have additional service configuration added or overridden via ~/.warden/docker-compose.yml file.\033[0m"
else
    echo -e "\033[33mWarden services do not appear to be overridden via ~/.warden/docker-compose.yml file.\033[0m"
fi
echo

echo -e "\033[32mWarden service override via ~/.warden/warden-env.yml partial:\033[0m"
if [[ -f ~/.warden/warden-env.yml ]]; then
    echo -e "\033[33mWarden services have additional service configuration added or overridden via ~/.warden/warden-env.yml partial.\033[0m"
else
    echo -e "\033[33mWarden services do not appear to be overridden via ~/.warden/warden-env.yml partial.\033[0m"
fi
echo

docker stats --no-stream &>/dev/null
# Docker is required to be running for the next set of commands
if [[ $? -eq 0 ]]; then
    echo -e "\033[32mWarden image, tag and architecture:\033[0m"

    WARDEN_IMAGES=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -i wardenenv)
    for img in ${WARDEN_IMAGES}; do
        echo $img:$(docker image inspect $img --format "{{.Architecture}}");
    done
    echo

    echo -e "\033[32mWarden environments and service configuration files:\033[0m"
    command -v jq >/dev/null
    if [[ $? -eq 0 ]]
    then
        ${WARDEN_BIN} svc ls -a --format json | jq '.[] | (.Name + " - " + .Status), (.ConfigFiles | split(","))'
    else
        ${WARDEN_BIN} svc ls -a --format table
    fi
    echo

    echo -e "\033[32mWarden status:\033[0m"
    ${WARDEN_BIN} status
else
    echo "Docker does not appear to be running. Start Docker and re-run this command to see Warden images, tags and architecture."
fi
echo

command -v mutagen &>/dev/null
if [[ $? -eq 0 ]]; then
    echo -e "\033[32mMutagen sync list\033[0m"
    mutagen sync list
fi
echo
