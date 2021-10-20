FROM ghcr.io/drpayyne/warden-php-m2

USER root

RUN install-php-extensions xdebug

COPY xdebug3/etc/*.ini /etc/
COPY xdebug3/etc/php.d/*.ini /etc/php.d/

USER www-data
