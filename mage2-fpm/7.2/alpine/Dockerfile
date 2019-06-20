FROM davidalger/php:7.2-fpm-alpine
USER root

ENV MAILHOG_HOST    mailhog
ENV MAILHOG_PORT    1025

RUN PHP_VERSION=$(echo ${PHP_VERSION} | cut -d. -f1-2) \
    && mkdir -p /tmp/sourceguardian \
    && cd /tmp/sourceguardian \
    && curl -Os https://www.sourceguardian.com/loaders/download/loaders.linux-x86_64.tar.gz \
    && tar xzf loaders.linux-x86_64.tar.gz \
    && cp ixed.${PHP_VERSION}.lin "$(php -i | grep '^extension_dir =' | cut -d' ' -f3)/sourceguardian.so" \
    && echo "zend_extension=$(php -i | grep '^extension_dir =' | cut -d' ' -f3)/sourceguardian.so" \
        > /usr/local/etc/php/conf.d/docker-php-ext-sourceguardian.ini \
    && rm -rf /tmp/sourceguardian

RUN npm install -g grunt-cli

RUN mkdir -p /usr/local/bin \
    && curl -s https://files.magerun.net/n98-magerun2.phar > /usr/local/bin/n98-magerun \
    && chmod +x /usr/local/bin/n98-magerun

COPY docker-php-entrypoint /usr/local/bin/
COPY etc/additions.ini /usr/local/etc/php/conf.d/10-additions.ini.template

RUN touch /usr/local/etc/php/conf.d/10-additions.ini \
    && chown www-data /usr/local/etc/php/conf.d/10-additions.ini

USER www-data
