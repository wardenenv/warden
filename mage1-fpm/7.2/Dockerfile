FROM davidalger/php:7.2-fpm
USER root

ENV MAILHOG_HOST    mailhog
ENV MAILHOG_PORT    1025

RUN yum install -y which pv sudo bind-utils python36-pip mariadb102 \
    && yum clean all \
    && rm -rf /var/cache/yum

ENV NODE_VERSION    10
RUN npm install -g n \
    && n install ${NODE_VERSION} \
    && rm -rf /usr/local/n/versions/node

RUN npm install -g grunt-cli

RUN mkdir -p /usr/local/bin \
    && curl -s https://files.magerun.net/n98-magerun.phar > /usr/local/bin/n98-magerun \
    && chmod +x /usr/local/bin/n98-magerun

COPY docker-entrypoint /usr/local/bin/
COPY etc/profile.d/*.sh /etc/profile.d/
COPY etc/php.d/*.ini /etc/php.d/
COPY etc/php.d/05-additions.ini.template /etc/php.d/

# Install and enable Source Gaurdian loader
RUN PHP_VERSION=$(php -v | head -n1 | cut -d' ' -f2 | cut -d. -f1-2) \
    && mkdir -p /tmp/sourceguardian \
    && cd /tmp/sourceguardian \
    && curl -Os https://www.sourceguardian.com/loaders/download/loaders.linux-x86_64.tar.gz \
    && tar xzf loaders.linux-x86_64.tar.gz \
    && cp ixed.${PHP_VERSION}.lin "$(php -i | grep '^extension_dir =' | cut -d' ' -f3)/sourceguardian.so" \
    && echo "extension=sourceguardian.so" > /etc/php.d/15-sourceguardian.ini \
    && rm -rf /tmp/sourceguardian

# Install mhsendmail to support routing email through mailhog
RUN mkdir -p /tmp/mhsendmail \
    && cd /tmp/mhsendmail \
    && curl -vLOs https://github.com/mailhog/mhsendmail/releases/download/v0.2.0/mhsendmail_linux_amd64 \
    && chmod +x mhsendmail_linux_amd64 \
    && mv mhsendmail_linux_amd64 /usr/local/bin/mhsendmail

RUN echo "www-data ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd
USER www-data
