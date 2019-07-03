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

## if --push is passed as first argument to script, this will login to docker hub and push images
PUSH_FLAG=
if [[ "${1:-}" = "--push" ]]; then
  PUSH_FLAG=1
  SEARCH_PATH="${2:-*}"
else
  SEARCH_PATH="${1:-*}"
fi

## change into base directory and login to docker hub if neccessary
pushd ${BASE_DIR} >/dev/null
[[ $PUSH_FLAG ]] && docker login

## iterate over and build each Dockerfile
for file in $(find ${SEARCH_PATH} -type f -name Dockerfile); do
    BUILD_DIR="$(dirname "${file}")"
    IMAGE_TAG="davidalger/warden:$(dirname "${file}" | tr / - | sed 's/--/-/')"

    docker build -t "${IMAGE_TAG}" ${BUILD_DIR}
    [[ $PUSH_FLAG ]] && docker push "${IMAGE_TAG}"
done
