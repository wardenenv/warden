ARG PHP_VERSION
FROM davidalger/warden:mage1-fpm-${PHP_VERSION}
USER root

RUN PHP_VERSION=$(php -v | head -n1 | cut -d' ' -f2 | sed -E 's/([0-9])\.([0-9])\.([0-9]+)/\1\2/') \
    && yum install -y pygpgme \
    && curl -o - "http://packages.blackfire.io/fedora/blackfire.repo" | sudo tee /etc/yum.repos.d/blackfire.repo \
    && yum install -y blackfire-php \
    && yum clean all \
    && rm -rf /var/cache/yum

COPY blackfire/etc/php.d/*.ini /etc/php.d/

USER www-data
