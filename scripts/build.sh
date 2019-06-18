#!/usr/bin/env bash
set -e
trap '>&2 printf "\n\e[01;31mError: Command \`%s\` on line $LINENO failed with exit code $?\033[0m\n" "$BASH_COMMAND"' ERR

## find directory where this script is located following symlinks if neccessary
readonly BASE_DIR="$(
  cd "$(
    dirname "$(
      (readlink "${BASH_SOURCE[0]}" || echo "${BASH_SOURCE[0]}") \
        | sed -e "s#^../#$(dirname "$(dirname "${BASH_SOURCE[0]}")")/#"
    )"
  )" >/dev/null \
  && pwd
)/.."

## support passing a single argument to the command to be more specific on what is built
SEARCH_PATH="${1:-*}"

## change into base directory and login to docker hub if neccessary
pushd ${BASE_DIR} >/dev/null
docker login

## iterate over and build each Dockerfile
for file in $(find ${SEARCH_PATH} -type f -name Dockerfile); do
    BUILD_DIR="$(dirname "${file}")"
    IMAGE_TAG="davidalger/warden:$(dirname "${file}" | tr / -)"
    docker build -t "${IMAGE_TAG}" ${BUILD_DIR}
    docker push "${IMAGE_TAG}"
done
