FROM davidalger/php:7.1-fpm-alpine
USER root

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
    && curl -s https://files.magerun.net/n98-magerun1.phar > /usr/local/bin/n98-magerun \
    && chmod +x /usr/local/bin/n98-magerun

USER www-data
