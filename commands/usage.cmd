#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

## load usage info for the given command falling back on default usage text
if [[ -f "${WARDEN_CMD_HELP}" ]]; then
  source "${WARDEN_CMD_HELP}"
else
  source "${WARDEN_DIR}/commands/usage.help"
fi

echo -e "${WARDEN_USAGE}"
exit 1
