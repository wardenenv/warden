ARG PHP_VERSION
FROM docker.io/wardenenv/php-fpm:${PHP_VERSION}
USER root

RUN mkdir -p media/temp/ \
    && mkdir -p var/cache/ \
    && mkdir -p var/log/ \
    && mkdir -p web/cache/ \
    && mkdir -p media/archive/ \
    && mkdir -p media/image/ \
    && mkdir -p media/image/thumbnail/ \
    && mkdir -p media/music/ \
    && mkdir -p media/pdf/ \
    && mkdir -p media/unknown/ \
    && mkdir -p media/vector/ \
    && mkdir -p media/video/ \
    && mkdir -p media/temp/ \
    && mkdir -p files/documents/ \
    && mkdir -p files/downloads/ \
    && chmod 777 -R files \
    && chmod 777 -R media \
    && chmod 777 -R var/ \
    && chmod 777 -R web/

USER www-data
