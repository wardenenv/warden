ARG PHP_VERSION
FROM davidalger/warden:fpm-${PHP_VERSION}
USER root

RUN npm install -g grunt-cli

RUN mkdir -p /usr/local/bin \
    && curl -s https://files.magerun.net/n98-magerun.phar > /usr/local/bin/n98-magerun \
    && chmod +x /usr/local/bin/n98-magerun

USER www-data
