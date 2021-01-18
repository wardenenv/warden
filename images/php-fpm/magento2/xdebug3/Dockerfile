ARG PHP_VERSION=
FROM docker.io/wardenenv/php-fpm:${PHP_VERSION}-magento2
USER root

RUN set -eux \
    && yum install -y php-pecl-xdebug3 \
    && yum clean all \
    && rm -rf /var/cache/yum

COPY xdebug3/etc/*.ini /etc/
COPY xdebug3/etc/php.d/*.ini /etc/php.d/

USER www-data
