ARG PHP_VERSION
FROM davidalger/warden:fpm-${PHP_VERSION}
USER root

RUN npm install -g grunt-cli

RUN mkdir -p /usr/local/bin \
    && curl -s https://files.magerun.net/n98-magerun2.phar > /usr/local/bin/n98-magerun \
    && chmod +x /usr/local/bin/n98-magerun

RUN curl -o /etc/bash_completion.d/n98-magerun2.phar.bash \
        https://raw.githubusercontent.com/netz98/n98-magerun2/master/res/autocompletion/bash/n98-magerun2.phar.bash \
    && perl -pi -e 's/^(complete -o default .*)$/$1 n98-magerun/' /etc/bash_completion.d/n98-magerun2.phar.bash

# Prevent pub dir from being auto-created by docker with wrong permissions when mounting pub/media
RUN mkdir /var/www/html/pub && chown www-data:www-data /var/www/html/pub

USER www-data
