#!/bin/sh
set -eu

upstream_host="${WARDEN_DNS_OVER_HTTPS_UPSTREAM_HOST:-dnsmasq}"
upstream_ip="$(getent hosts "${upstream_host}" | awk 'NR==1 { print $1 }')"

if [ -z "${upstream_ip}" ]; then
  echo "Failed to resolve DNS-over-HTTPS upstream host: ${upstream_host}" >&2
  exit 1
fi

printf '%s\n' "${WARDEN_DNS_OVER_HTTPS_CONFIG}" \
  | sed "s/__WARDEN_DNS_OVER_HTTPS_UPSTREAM__/${upstream_ip}/g" \
  > /tmp/warden-dnsdist.conf

exec dnsdist --supervised --disable-syslog --config /tmp/warden-dnsdist.conf
