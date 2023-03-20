#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

WARDEN_ENV_PATH="$(pwd -P)"

# Prompt user if there is an extant .env file to ensure they intend to overwrite
if test -f "${WARDEN_ENV_PATH}/.env"; then
  while true; do
    read -p $'\033[32mA warden env file already exists at '"${WARDEN_ENV_PATH}/.env"$'; would you like to overwrite? y/n\033[0m ' resp
    case $resp in
      [Yy]*) echo "Overwriting extant .env file"; break;;
      [Nn]*) exit;;
      *) echo "Please answer (y)es or (n)o";;
    esac
  done
fi

WARDEN_ENV_NAME="${WARDEN_PARAMS[0]:-}"

# If warden environment name was not provided, prompt user for it
while [ -z "${WARDEN_ENV_NAME}" ]; do
  read -p $'\033[32mAn environment name was not provided; please enter one:\033[0m ' WARDEN_ENV_NAME
done

WARDEN_ENV_TYPE="${WARDEN_PARAMS[1]:-}"

# If warden environment type was not provided, prompt user for it
if [ -z "${WARDEN_ENV_TYPE}" ]; then
  while true; do
    read -p $'\033[32mAn environment type was not provided; please choose one of ['"$(fetchValidEnvTypes)"$']:\033[0m ' WARDEN_ENV_TYPE
    assertValidEnvType && break
  done
fi

# Verify the auto-select and/or type path resolves correctly before setting it
assertValidEnvType || exit $?

# Write the .env file to current working directory
cat > "${WARDEN_ENV_PATH}/.env" <<EOF
WARDEN_ENV_NAME=${WARDEN_ENV_NAME}
WARDEN_ENV_TYPE=${WARDEN_ENV_TYPE}
WARDEN_WEB_ROOT=/

TRAEFIK_DOMAIN=${WARDEN_ENV_NAME}.test
TRAEFIK_SUBDOMAIN=app
EOF

ENV_INIT_FILE=$(fetchEnvInitFile)
if [[ ! -z $ENV_INIT_FILE ]]; then
  export WARDEN_ENV_NAME
  export GENERATED_APP_KEY="base64:$(dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64)"
  envsubst '$WARDEN_ENV_NAME:$GENERATED_APP_KEY' < "${ENV_INIT_FILE}" >> "${WARDEN_ENV_PATH}/.env"
fi