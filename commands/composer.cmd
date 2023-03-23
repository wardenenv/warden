#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

## allow return codes from sub-process to bubble up normally
trap '' ERR

if [ "$1" == "--notty" ]; then
	"${WARDEN_DIR}/bin/warden" clinotty composer "${WARDEN_PARAMS[@]}" "$@"
else
	"${WARDEN_DIR}/bin/warden" cli composer "${WARDEN_PARAMS[@]}" "$@"
fi
