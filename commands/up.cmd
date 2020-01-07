#!/usr/bin/env bash
[[ ! ${WARDEN_COMMAND} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!" && exit 1

source "${WARDEN_DIR}/utils/install.sh"
assertWardenInstall

mkdir -p "${WARDEN_HOME_DIR}/etc/traefik"
cp "${WARDEN_DIR}/config/traefik/traefik.yml" "${WARDEN_HOME_DIR}/etc/traefik/traefik.yml"
cp "${WARDEN_DIR}/config/traefik/dynamic.yml" "${WARDEN_HOME_DIR}/etc/traefik/dynamic.yml"
cp "${WARDEN_DIR}/config/dnsmasq.conf" "${WARDEN_HOME_DIR}/etc/dnsmasq.conf"

cat >> "${WARDEN_HOME_DIR}/etc/traefik/dynamic.yml" <<-EOF
tls:
  certificates:
EOF

for cert in $(find "${WARDEN_SSL_DIR}/certs" -type f -name "*.crt.pem" | sed -E 's#^.*/ssl/certs/(.*)\.crt\.pem$#\1#'); do
  cat >> "${WARDEN_HOME_DIR}/etc/traefik/dynamic.yml" <<-EOF
	    - certFile: /etc/ssl/certs/${cert}.crt.pem
	      keyFile: /etc/ssl/certs/${cert}.key.pem
	EOF
done

pushd "${WARDEN_DIR}" >/dev/null
docker-compose -p warden -f docker/docker-compose.yml up -d "${WARDEN_PARAMS[@]}" "$@"
