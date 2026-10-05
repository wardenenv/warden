#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

WARDEN_ENV_PATH="$(pwd -P)"
WARDEN_ENV_FILE="${WARDEN_ENV_PATH}/${WARDEN_ENV_FILENAME_CANONICAL}"
WARDEN_LEGACY_ENV_FILE="${WARDEN_ENV_PATH}/${WARDEN_ENV_FILENAME_DEPRECATED}"

# Prompt user if there is an extant config file to ensure they intend to overwrite
if test -f "${WARDEN_ENV_FILE}"; then
  while true; do
    read -p $'\033[32mA warden env file already exists at '"${WARDEN_ENV_FILE}"$'; would you like to overwrite? y/n\033[0m ' resp
    case $resp in
      [Yy]*) echo "Overwriting extant ${WARDEN_ENV_FILENAME_CANONICAL} file"; break;;
      [Nn]*) exit;;
      *) echo "Please answer (y)es or (n)o";;
    esac
  done
elif test -f "${WARDEN_LEGACY_ENV_FILE}" && grep -q "^WARDEN_ENV_NAME" "${WARDEN_LEGACY_ENV_FILE}"; then
  # An environment configured through the deprecated filename is superseded rather
  # than overwritten, which would otherwise silently leave two config files behind
  warning "This directory is already configured via \"${WARDEN_LEGACY_ENV_FILE}\", which is deprecated.\n         Writing \"${WARDEN_ENV_FILENAME_CANONICAL}\" will take precedence over it and the existing file will be left untouched."
  while true; do
    read -p $'\033[32mContinue and write '"${WARDEN_ENV_FILENAME_CANONICAL}"$'? y/n\033[0m ' resp
    case $resp in
      [Yy]*) break;;
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

# Write the configuration file to current working directory
cat > "${WARDEN_ENV_FILE}" <<EOF
WARDEN_ENV_NAME=${WARDEN_ENV_NAME}
WARDEN_ENV_TYPE=${WARDEN_ENV_TYPE}
WARDEN_WEB_ROOT=/

TRAEFIK_DOMAIN=${WARDEN_ENV_NAME}.test
TRAEFIK_SUBDOMAIN=app
EOF

ENV_INIT_FILE=$(fetchEnvInitFile)
if [[ ! -z $ENV_INIT_FILE ]]; then
  export WARDEN_ENV_NAME
  # No bundled template substitutes GENERATED_APP_KEY any longer, since Warden no
  # longer seeds application configuration; it stays exported because init.env
  # templates supplied via WARDEN_HOME_DIR or .warden/environments may rely on it
  export GENERATED_APP_KEY="base64:$(dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64)"
  envsubst '$WARDEN_ENV_NAME:$GENERATED_APP_KEY' < "${ENV_INIT_FILE}" >> "${WARDEN_ENV_FILE}"
fi

if [ -s "${WARDEN_ENV_FILE}" ]; then
  printf "A warden env file was created at ${WARDEN_ENV_FILE}\nYou may now use \'warden env up\' to start your environment.\n"
  exit 0
fi