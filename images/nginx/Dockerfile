ARG NGINX_VERSION
FROM nginx:${NGINX_VERSION}-alpine
RUN apk add --no-cache bash shadow

ENV NGINX_UPSTREAM_HOST           php-fpm
ENV NGINX_UPSTREAM_PORT           9000
ENV NGINX_UPSTREAM_DEBUG_HOST     php-debug
ENV NGINX_UPSTREAM_DEBUG_PORT     9000
ENV NGINX_UPSTREAM_BLACKFIRE_HOST php-blackfire
ENV NGINX_UPSTREAM_BLACKFIRE_PORT 9000
ENV NGINX_ROOT                    /var/www/html
ENV NGINX_PUBLIC                  ''
ENV NGINX_TEMPLATE                application.conf
ENV XDEBUG_CONNECT_BACK_HOST      '""'

COPY etc/nginx/fastcgi_params /etc/nginx/fastcgi_params.template
COPY etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.template
COPY etc/nginx/available.d/*.conf /etc/nginx/available.d/

CMD envsubst '${NGINX_UPSTREAM_HOST} ${NGINX_UPSTREAM_PORT} \
              ${NGINX_UPSTREAM_BLACKFIRE_HOST} ${NGINX_UPSTREAM_BLACKFIRE_PORT} \
              ${NGINX_UPSTREAM_DEBUG_HOST} ${NGINX_UPSTREAM_DEBUG_PORT} \
              ${NGINX_ROOT} ${NGINX_PUBLIC} ${NGINX_TEMPLATE}' \
        < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf \
    && envsubst '${XDEBUG_CONNECT_BACK_HOST}' \
        < /etc/nginx/fastcgi_params.template > /etc/nginx/fastcgi_params \
    && nginx -g "daemon off;"

WORKDIR /var/www/html
