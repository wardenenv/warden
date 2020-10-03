ARG PHP_VERSION
FROM docker.io/wardenenv/php-fpm:${PHP_VERSION}-shopware5
USER root

RUN yum install -y pygpgme \
    && curl -o - "http://packages.blackfire.io/fedora/blackfire.repo" | sudo tee /etc/yum.repos.d/blackfire.repo \
    && yum install -y blackfire-php

COPY blackfire/etc/php.d/*.ini /etc/php.d/

USER www-data
