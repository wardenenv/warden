FROM davidalger/warden:fpm-7.3
USER root

RUN npm install -g grunt-cli

RUN mkdir -p /usr/local/bin \
    && curl -s https://files.magerun.net/n98-magerun2.phar > /usr/local/bin/n98-magerun \
    && chmod +x /usr/local/bin/n98-magerun

# Prevent pub dir from being auto-created by docker with wrong permissions when mounting pub/media
RUN mkdir /var/www/html/pub && chown www-data:www-data /var/www/html/pub

USER www-data
