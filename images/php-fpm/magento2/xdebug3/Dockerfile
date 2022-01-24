ARG PHP_TAG
FROM ghcr.io/drpayyne/warden-php-m2:${PHP_TAG}

USER root

RUN install-php-extensions xdebug xsl sockets

COPY xdebug3/etc/*.ini /etc/
COPY xdebug3/etc/xdebug-config /usr/local/etc/php/conf.d/xdebug-config

RUN cat /usr/local/etc/php/conf.d/xdebug-config >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && rm /usr/local/etc/php/conf.d/xdebug-config

USER www-data
