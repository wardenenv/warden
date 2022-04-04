FROM quay.io/centos/centos:stream8

RUN dnf upgrade -y \
    && dnf clean all \
    && rm -rf /var/cache/dnf

ARG VARNISH_VERSION=60lts
ARG RPM_SCRIPT=https://packagecloud.io/install/repositories/varnishcache/varnish${VARNISH_VERSION}/script.rpm.sh
RUN curl -s "${RPM_SCRIPT}" | bash \
    && dnf install -y epel-release \
    && dnf module disable -y varnish \
    && dnf install -y varnish gettext \
    && dnf clean all \
    && rm -rf /var/cache/dnf

ENV VCL_CONFIG      /etc/varnish/default.vcl
ENV CACHE_SIZE      256m
ENV VARNISHD_PARAMS -p default_ttl=3600 -p default_grace=3600 \
    -p feature=+esi_ignore_https -p feature=+esi_disable_xml_check

COPY default.vcl /etc/varnish/default.vcl.template

ENV BACKEND_HOST    nginx
ENV BACKEND_PORT    80
ENV ACL_PURGE_HOST  0.0.0.0/0

EXPOSE 	80
CMD envsubst '${BACKEND_HOST} ${BACKEND_PORT} ${ACL_PURGE_HOST}' \
        < /etc/varnish/default.vcl.template > /etc/varnish/default.vcl \
    && varnishd -F -f $VCL_CONFIG -s malloc,$CACHE_SIZE $VARNISHD_PARAMS
