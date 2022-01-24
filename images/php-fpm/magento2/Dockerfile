ARG PHP_TAG
FROM ghcr.io/drpayyne/warden-php:${PHP_TAG}

USER root

RUN install-php-extensions xsl sockets

RUN npm install -g grunt-cli gulp yarn

RUN set -eux \
    && PHP_VERSION=$(php -v | head -n1 | cut -d' ' -f2 | awk -F '.' '{print $1$2}') \
    && if (( ${PHP_VERSION} >= 72 )); \
        then MAGERUN_PHAR_URL=https://files.magerun.net/n98-magerun2.phar; \
        else MAGERUN_PHAR_URL=https://files.magerun.net/n98-magerun2-3.2.0.phar; \
    fi \
    && mkdir -p /usr/local/bin \
    && curl -s ${MAGERUN_PHAR_URL} > /usr/local/bin/n98-magerun \
    && chmod +x /usr/local/bin/n98-magerun

RUN set -eux \
    && PHP_VERSION=$(php -v | head -n1 | cut -d' ' -f2 | awk -F '.' '{print $1$2}') \
    && if (( ${PHP_VERSION} >= 72 )); \
        then MAGERUN_BASH_REF=master; \
        else MAGERUN_BASH_REF=3.2.0; \
    fi \
    && curl -o /etc/bash_completion.d/n98-magerun2.phar.bash \
        https://raw.githubusercontent.com/netz98/n98-magerun2/${MAGERUN_BASH_REF}/res/autocompletion/bash/n98-magerun2.phar.bash \
    && perl -pi -e 's/^(complete -o default .*)$/$1 n98-magerun/' /etc/bash_completion.d/n98-magerun2.phar.bash

# Create mr alias for n98-magerun
RUN ln -s /usr/local/bin/n98-magerun /usr/local/bin/mr

USER www-data
