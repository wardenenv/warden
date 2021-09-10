FROM ghcr.io/drpayyne/warden-php-m2

USER root

RUN set -eux \
    && dnf install -y php-pecl-xdebug3 \
    && dnf clean all \
    && rm -rf /var/cache/dnf

COPY xdebug3/etc/*.ini /etc/
COPY xdebug3/etc/php.d/*.ini /etc/php.d/

USER www-data
