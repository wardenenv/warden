#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

## load usage info for the given command falling back on default usage text
if [[ -f "${WARDEN_CMD_HELP}" ]]; then
  source "${WARDEN_CMD_HELP}"
else
  source "${WARDEN_DIR}/commands/usage.help"

  WARDEN_ENV_PATH="$(locateEnvPath)" || true
  if [[ -n "${WARDEN_ENV_PATH}" && -d "${WARDEN_ENV_PATH}/.warden/commands" ]]; then
    CUSTOM_COMMAND_LIST=$(ls "${WARDEN_ENV_PATH}/.warden/commands/"*.cmd)
    
    if [[ -n "${CUSTOM_COMMAND_LIST}" ]]; then
      TRIM_PREFIX="${WARDEN_ENV_PATH}/.warden/commands/"
      TRIM_SUFFIX=".cmd"
      CUSTOM_COMMANDS=""
      for COMMAND in $CUSTOM_COMMAND_LIST; do
        COMMAND=${COMMAND#"$TRIM_PREFIX"}
        COMMAND=${COMMAND%"$TRIM_SUFFIX"}
        [[ ! -e "${TRIM_PREFIX}${COMMAND}.help" ]] && continue;
        CUSTOM_COMMANDS="${CUSTOM_COMMANDS}  ${COMMAND}"$'\n'
      done

      if [[ -n "${CUSTOM_COMMANDS}" ]]; then
        CUSTOM_ENV_COMMANDS=$'\n\n'"\033[33mCustom Commands For Environment \033[35m${WARDEN_ENV_PATH##*/}\033[33m:\033[0m"
        CUSTOM_ENV_COMMANDS="$CUSTOM_ENV_COMMANDS"$'\n'"$CUSTOM_COMMANDS"
        WARDEN_USAGE=$(cat <<EOF
${WARDEN_USAGE}${CUSTOM_ENV_COMMANDS}
EOF
)
      fi
    fi
  fi
fi

echo -e "${WARDEN_USAGE}"
exit 1
