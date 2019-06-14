FROM alpine:3.6
RUN apk add --no-cache varnish gettext

ENV VCL_CONFIG      /etc/varnish/default.vcl
ENV CACHE_SIZE      256m
ENV VARNISHD_PARAMS -p default_ttl=3600 -p default_grace=3600 -p feature=+esi_ignore_https -p feature=+esi_disable_xml_check

COPY default.vcl /etc/varnish/default.vcl.template

ENV BACKEND_HOST    nginx
ENV BACKEND_PORT    80

EXPOSE 	80
CMD envsubst '${BACKEND_HOST} ${BACKEND_PORT}' < /etc/varnish/default.vcl.template > /etc/varnish/default.vcl \
    && varnishd -F -f $VCL_CONFIG -s malloc,$CACHE_SIZE $VARNISHD_PARAMS
