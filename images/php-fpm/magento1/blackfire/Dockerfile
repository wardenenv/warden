ARG PHP_VERSION
FROM docker.io/wardenenv/php-fpm:${PHP_VERSION}-magento1
USER root

RUN curl -o - "http://packages.blackfire.io/fedora/blackfire.repo" \
    | sudo tee /etc/yum.repos.d/blackfire.repo \
    && dnf install -y blackfire-php \
    && dnf clean all \
    && rm -rf /var/cache/dnf

COPY blackfire/etc/php.d/*.ini /etc/php.d/

USER www-data
