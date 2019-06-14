#!/usr/bin/env bash
[[ ! ${WARDEN_COMMAND} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!" && exit 1

WARDEN_ENV_PATH="$(pwd)"
while [[ "${WARDEN_ENV_PATH}" != "/" ]]; do
    if [[ -f "${WARDEN_ENV_PATH}/.env" ]] && grep "^WARDEN_ENV_TYPE" "${WARDEN_ENV_PATH}/.env" >/dev/null; then
        break
    fi
    WARDEN_ENV_PATH="$(dirname "${WARDEN_ENV_PATH}")"
done

[[ "${WARDEN_ENV_PATH}" = "/" ]] \
    && >&2 echo -e "\033[31mEnvironment config could not be found. Please run \"warden env-init\" and try again!" && exit 1

eval "$(grep "^WARDEN_" "${WARDEN_ENV_PATH}/.env")"

WARDEN_ENV_NAME="${WARDEN_ENV_NAME:-$(basename "${WARDEN_ENV_PATH}")}"
WARDEN_ENV_TYPE="${WARDEN_ENV_TYPE:-}"

[[ ! -f "${WARDEN_DIR}/type/${WARDEN_ENV_TYPE}.yml" ]] \
    && >&2 echo -e "\033[31mInvalid environment type \"${WARDEN_ENV_TYPE}\" specified." && exit 1

docker-compose \
    --project-directory "${WARDEN_ENV_PATH}" \
    -p "${WARDEN_ENV_NAME}" \
    -f "${WARDEN_DIR}/type/${WARDEN_ENV_TYPE}.yml" \
    "${WARDEN_PARAMS[@]}" "$@"
