#!/usr/bin/env bash
[[ ! ${WARDEN_COMMAND} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!" && exit 1

## ensure warden install has been run
assert_installed

mkdir -p "${WARDEN_HOME_DIR}/etc/traefik"
cp "${WARDEN_DIR}/config/traefik/traefik.toml" "${WARDEN_HOME_DIR}/etc/traefik/traefik.toml"
cp "${WARDEN_DIR}/config/dnsmasq.conf" "${WARDEN_HOME_DIR}/etc/dnsmasq.conf"

# TODO: Determine if a template loop may work in the config file to do this automatically in traefik
for cert in $(find "${WARDEN_SSL_DIR}/certs" -type f -name "*.crt.pem" | sed -E 's#^.*/ssl/certs/(.*)\.crt\.pem$#\1#'); do
  [[ "${cert}" = "warden.test" ]] && continue

  cat >> "${WARDEN_HOME_DIR}/etc/traefik/traefik.toml" <<-EOF
	      [[entryPoints.https.tls.certificates]]
	      certFile = "/etc/ssl/certs/${cert}.crt.pem"
	      keyFile = "/etc/ssl/certs/${cert}.key.pem"
	EOF
done

pushd "${WARDEN_DIR}" >/dev/null

## publish dnsmasq to a non-standard port on macOS due to bug in Docker Desktop 2.1.0.0
## https://github.com/docker/for-mac/issues/3775
if [[ "$OSTYPE" == "darwin"* ]]; then
	export WARDEN_DNSMASQ_PORT=6053
fi

docker-compose -p warden -f docker/docker-compose.yml up -d "${WARDEN_PARAMS[@]}" "$@"
