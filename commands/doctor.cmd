#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

# The warden doctor command is designed to collect information useful in reasoning about the
# state of a system and configuration warden is running with.

# Host information
## darwin
# > sw_vers

sw_vers --productName
sw_vers --productVersion
echo


docker --version
${DOCKER_COMPOSE_COMMAND} version

echo

echo "Warden version:" $(${WARDEN_BIN} version)
echo

echo "Warden image, tag and architecture: "
echo
WARDEN_IMAGES=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -i wardenenv)
for img in ${WARDEN_IMAGES}; do
    echo $img:$(docker image inspect $img --format "{{.Architecture}}");
done
echo

${WARDEN_BIN} svc ls -a --format json | jq '.[] | (.Name + " - " + .Status), (.ConfigFiles | split(","))'
echo

"$WARDEN_BIN" status
echo

mutagen sync list
echo

# ssh information related warden / warden project
# any docker inspect or configuration information

# echo "Warden doctor complete!"
