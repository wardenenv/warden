#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

WARDEN_ENV_PATH="$(locateEnvPath)" || exit $?
loadEnvConfig "${WARDEN_ENV_PATH}" || exit $?

if [[ ${WARDEN_SELENIUM} -ne 1 ]] || [[ ${WARDEN_SELENIUM_DEBUG} -ne 1 ]]; then
  fatal "The project environment must have WARDEN_SELENIUM and WARDEN_SELENIUM_DEBUG enabled to use this command"
fi

WARDEN_SELENIUM_INDEX=${WARDEN_PARAMS[0]:-1}
WARDEN_SELENIUM_VNC=${WARDEN_ENV_NAME}-${WARDEN_PARAMS[1]:-selenium}-${WARDEN_SELENIUM_INDEX}

if ! which remmina >/dev/null; then
  EXPOSE_PORT=$((5900 + WARDEN_SELENIUM_INDEX))

  echo "Connect with your VNC client to 127.0.0.1:${EXPOSE_PORT}"
  echo "    Password: secret"
  echo "You can also use URL: vnc://127.0.0.1:${EXPOSE_PORT}/?VncPassword=secret"
  ssh -N -L localhost:${EXPOSE_PORT}:${WARDEN_SELENIUM_VNC}:5900 tunnel.warden.test
else

  cat > "${WARDEN_ENV_PATH}/.remmina" <<-EOF
	[remmina]
	name=${WARDEN_SELENIUM_VNC} Debug
	proxy=
	ssh_enabled=1
	colordepth=8
	server=${WARDEN_SELENIUM_VNC}
	ssh_auth=3
	quality=9
	scale=1
	ssh_username=user
	password=.
	disablepasswordstoring=0
	viewmode=1
	window_width=1200
	window_height=780
	ssh_server=tunnel.warden.test:2222
	protocol=VNC
	EOF

  echo -e "Launching VNC session via Remmina. Password is \"\033[1msecret\"\033[0m"
  remmina -c "${WARDEN_ENV_PATH}/.remmina"
fi
