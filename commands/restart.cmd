#!/usr/bin/env bash
[[ ! ${WARDEN_COMMAND} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

source "${WARDEN_DIR}/utils/core.sh"
warning "This command is deprecated as of 0.6.0 and will be removed in 0.7.0; please use 'warden svc restart' instead."

trap '' ERR
"${WARDEN_DIR}/bin/warden" svc restart "${WARDEN_PARAMS[@]}" "$@"
