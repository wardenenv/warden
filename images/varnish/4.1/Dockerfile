FROM alpine:3.6
RUN apk add --no-cache varnish gettext bash

ENV VCL_CONFIG      /etc/varnish/default.vcl
ENV CACHE_SIZE      256m
ENV VARNISHD_PARAMS -p default_ttl=3600 -p default_grace=3600 -p feature=+esi_ignore_https -p feature=+esi_disable_xml_check

COPY default.vcl /etc/varnish/default.vcl.template

ENV BACKEND_HOST    nginx
ENV BACKEND_PORT    80
ENV ACL_PURGE_HOST  php-fpm

RUN echo "export PS1='\[\033[0;0m\]\u@\h\[\033[0m\]:\[\033[0;31m\]\w\[\033[0m\]# '" >> /root/.bashrc

EXPOSE 	80
CMD envsubst '${BACKEND_HOST} ${BACKEND_PORT} ${ACL_PURGE_HOST}' \
        < /etc/varnish/default.vcl.template > /etc/varnish/default.vcl \
    && varnishd -F -f $VCL_CONFIG -s malloc,$CACHE_SIZE $VARNISHD_PARAMS
