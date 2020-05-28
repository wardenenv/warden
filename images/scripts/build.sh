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

## if --push is passed as first argument to script, this will login to docker hub and push images
PUSH_FLAG=
if [[ "${1:-}" = "--push" ]]; then
  PUSH_FLAG=1
  SEARCH_PATH="${2:-}"
else
  SEARCH_PATH="${1:-}"
fi

## since fpm images no longer can be traversed, this script should require a search path vs defaulting to build all
if [[ -z ${SEARCH_PATH} ]]; then
  >&2 printf "\n\e[01;31mError: Missing search path. Please try again passing an image type as an argument!\033[0m\n"
  exit 1
fi

## login to docker hub as needed
if [[ ${PUSH_FLAG} ]]; then
  if [[ ${DOCKER_USERNAME:-} ]]; then
    echo "Attempting non-interactive docker login (via provided credentials)"
    echo "${DOCKER_PASSWORD:-}" | docker login -u "${DOCKER_USERNAME:-}" --password-stdin ${DOCKER_REGISTRY:-docker.io}
  elif [[ -t 1 ]]; then
    echo "Attempting interactive docker login (tty)"
    docker login ${DOCKER_REGISTRY:-docker.io}
  fi
fi

## iterate over and build each Dockerfile
for file in $(find ${SEARCH_PATH} -type f -name Dockerfile | sort -V); do
    BUILD_DIR="$(dirname "${file}")"
    IMAGE_TAG="docker.io/wardenenv/$(echo "${BUILD_DIR}" | cut -d/ -f1)"
    IMAGE_SUFFIX="$(echo "${BUILD_DIR}" | cut -d/ -f2- -s | tr / - | sed 's/^-//')"

    ## due to build matrix requirements, magento1 and magento2 specific varients are built in separate invocation
    if [[ ${SEARCH_PATH} == "php-fpm" ]] && [[ ${file} =~ php-fpm/magento[1-2] ]]; then
      continue;
    fi

    ## fpm images will not have each version in a directory tree; require version be passed
    ## in as env variable for use as a build argument
    BUILD_ARGS=()
    if [[ ${SEARCH_PATH} = *fpm* ]]; then
      if [[ -z ${PHP_VERSION} ]]; then
        >&2 printf "\n\e[01;31mError: Building ${SEARCH_PATH} images requires PHP_VERSION env variable be set!\033[0m\n"
        exit 1
      fi

      export PHP_VERSION

      IMAGE_TAG+=":${PHP_VERSION}"
      if [[ ${IMAGE_SUFFIX} ]]; then
        IMAGE_TAG+="-${IMAGE_SUFFIX}"
      fi
      BUILD_ARGS+=("--build-arg")
      BUILD_ARGS+=("PHP_VERSION")
    else
      IMAGE_TAG+=":${IMAGE_SUFFIX}"
    fi

    if [[ -d "$(echo ${BUILD_DIR} | cut -d/ -f1)/context" ]]; then
      BUILD_CONTEXT="$(echo ${BUILD_DIR} | cut -d/ -f1)/context"
    else
      BUILD_CONTEXT="${BUILD_DIR}"
    fi

    printf "\e[01;31m==> building ${IMAGE_TAG} from ${BUILD_DIR}/Dockerfile with context ${BUILD_CONTEXT}\033[0m\n"
    docker build -t "${IMAGE_TAG}" -f ${BUILD_DIR}/Dockerfile ${BUILD_ARGS[@]} ${BUILD_CONTEXT}
    [[ $PUSH_FLAG ]] && docker push "${IMAGE_TAG}" || true
done
