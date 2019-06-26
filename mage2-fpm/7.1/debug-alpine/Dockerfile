FROM davidalger/php:7.1-fpm-alpine
USER root

ENV MAILHOG_HOST    mailhog
ENV MAILHOG_PORT    1025

RUN npm install -g grunt-cli

RUN mkdir -p /usr/local/bin \
    && curl -s https://files.magerun.net/n98-magerun2.phar > /usr/local/bin/n98-magerun \
    && chmod +x /usr/local/bin/n98-magerun

COPY docker-php-entrypoint /usr/local/bin/
COPY etc/additions.ini /usr/local/etc/php/conf.d/10-additions.ini.template

RUN touch /usr/local/etc/php/conf.d/10-additions.ini \
    && chown www-data /usr/local/etc/php/conf.d/10-additions.ini \
    && mkdir /var/www/html/pub \
    && chown www-data:www-data /var/www/html/pub

RUN docker-php-ext-enable xdebug

USER www-data
