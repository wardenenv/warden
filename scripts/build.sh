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

pushd ${BASE_DIR} >/dev/null
docker login

for file in $(find * -type f -name Dockerfile); do
    BUILD_DIR="$(dirname "${file}")"
    IMAGE_TAG="davidalger/magento:$(dirname "${file}" | tr / -)"
    docker build -t "${IMAGE_TAG}" ${BUILD_DIR}
    docker push "${IMAGE_TAG}"
done
