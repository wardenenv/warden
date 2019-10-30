ARG PHP_VERSION
FROM davidalger/warden:fpm-${PHP_VERSION}
USER root

RUN npm install -g grunt-cli

RUN mkdir -p /usr/local/bin \
    && curl -s https://files.magerun.net/n98-magerun.phar > /usr/local/bin/n98-magerun \
    && chmod +x /usr/local/bin/n98-magerun

RUN curl -o /etc/bash_completion.d/n98-magerun.phar.bash \
        https://raw.githubusercontent.com/netz98/n98-magerun/master/res/autocompletion/bash/n98-magerun.phar.bash

USER www-data
