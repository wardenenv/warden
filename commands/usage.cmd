#!/usr/bin/env bash
[[ ! ${WARDEN_COMMAND} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

## load usage info for the given command falling back on default usage text
if [[ -f "${WARDEN_DIR}/commands/${WARDEN_COMMAND}.help" ]]; then
  source "${WARDEN_DIR}/commands/${WARDEN_COMMAND}.help"
else
  source "${WARDEN_DIR}/commands/usage.help"
fi

echo -e "${WARDEN_USAGE}"
exit 1
