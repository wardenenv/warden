FROM davidalger/php:7.2-fpm-alpine
USER root

ENV MAILHOG_HOST    mailhog
ENV MAILHOG_PORT    1025

RUN npm install -g grunt-cli

RUN mkdir -p /usr/local/bin \
    && curl -s https://files.magerun.net/n98-magerun.phar > /usr/local/bin/n98-magerun \
    && chmod +x /usr/local/bin/n98-magerun

COPY docker-php-entrypoint /usr/local/bin/
COPY etc/xdebug.ini /usr/local/etc/php/conf.d/05-xdebug.ini
COPY etc/additions.ini /usr/local/etc/php/conf.d/10-additions.ini.template

RUN touch /usr/local/etc/php/conf.d/10-additions.ini \
    && chown www-data /usr/local/etc/php/conf.d/10-additions.ini

RUN docker-php-ext-enable xdebug

USER www-data
