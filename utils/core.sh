#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

## global service containers to be connected with the project docker network
DOCKER_PEERED_SERVICES=("traefik" "tunnel" "mailhog")

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
