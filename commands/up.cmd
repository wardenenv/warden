#!/usr/bin/env bash
[[ ! ${WARDEN_COMMAND} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!" && exit 1

mkdir -p ~/.warden/etc/traefik
cp "${WARDEN_DIR}/etc/traefik/traefik.toml" ~/.warden/etc/traefik/traefik.toml

pushd "${WARDEN_DIR}" >/dev/null
docker-compose -p warden -f docker/docker-compose.yml up -d
