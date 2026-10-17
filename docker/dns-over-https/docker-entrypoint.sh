#!/bin/sh
set -eu

upstream_host="${WARDEN_DNS_OVER_HTTPS_UPSTREAM_HOST:-dnsmasq}"
upstream_ip="$(getent hosts "${upstream_host}" | awk 'NR==1 { print $1 }')"
webserver_secret="$(od -An -N32 -tx1 /dev/urandom | tr -d ' \n')"

if [ -z "${upstream_ip}" ]; then
  echo "Failed to resolve DNS-over-HTTPS upstream host: ${upstream_host}" >&2
  exit 1
fi

printf '%s\n' "${WARDEN_DNS_OVER_HTTPS_CONFIG}" \
  | sed "s/__WARDEN_DNS_OVER_HTTPS_UPSTREAM__/${upstream_ip}/g" \
  > /tmp/warden-dnsdist.conf

cat >> /tmp/warden-dnsdist.conf <<EOF
webserver("0.0.0.0:8083")
-- CRL/AIA clients cannot authenticate. Traefik exposes only the two exact PKI
-- paths below, keeping the rest of dnsdist's webserver off the public routes.
setWebserverConfig({
  acl="0.0.0.0/0,::/0",
  apiKey=hashPassword("${webserver_secret}"),
  dashboardRequiresAuthentication=false,
  statsRequireAuthentication=false
})
EOF

cat /usr/local/bin/warden-dns-over-https-pki.lua >> /tmp/warden-dnsdist.conf

exec dnsdist --supervised --disable-syslog --config /tmp/warden-dnsdist.conf
