ARG PHP_VERSION=
FROM davidalger/php:${PHP_VERSION}-fpm

# Clear undesired settings from base fpm images
ENV COMPOSER_ALLOW_SUPERUSER=
ENV COMPOSER_HOME=

ENV MAILHOG_HOST    mailhog
ENV MAILHOG_PORT    1025

RUN yum install -y which pv sudo bind-utils python36-pip mariadb102 bash-completion rsync socat \
    && yum clean all \
    && rm -rf /var/cache/yum

ENV NODE_VERSION    10
RUN npm install -g n \
    && n install ${NODE_VERSION} \
    && rm -rf /usr/local/n/versions/node

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

# Install and enable IonCube loader
RUN PHP_VERSION=$(php -v | head -n1 | cut -d' ' -f2 | cut -d. -f1-2) \
    && mkdir -p /tmp/ioncube \
    && cd /tmp/ioncube \
    && curl -Os https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz \
    && tar xzf ioncube_loaders_lin_x86-64.tar.gz \
    && curl -Os https://www.ioncube.com/php-7.4.0-beta-loaders/ioncube_loaders_lin_x86-64_7.4_BETA2.tar.gz \
    && tar xzf ioncube_loaders_lin_x86-64.tar.gz \
    && tar xzf ioncube_loaders_lin_x86-64_7.4_BETA2.tar.gz -C ioncube \
    && cp "$(find . -regex "./ioncube/ioncube_loader_lin_${PHP_VERSION}[0-9\.\_]*\(beta[0-9]*\|\)\.so")" \
        "$(php -i | grep '^extension_dir =' | cut -d' ' -f3)/ioncube_loader.so" \
    && echo "zend_extension=ioncube_loader.so" > /etc/php.d/01-ioncube-loader.ini \
    && rm -rf /tmp/ioncube

# Install mhsendmail to support routing email through mailhog
RUN mkdir -p /tmp/mhsendmail \
    && cd /tmp/mhsendmail \
    && curl -vLOs https://github.com/mailhog/mhsendmail/releases/download/v0.2.0/mhsendmail_linux_amd64 \
    && chmod +x mhsendmail_linux_amd64 \
    && mv mhsendmail_linux_amd64 /usr/local/bin/mhsendmail

# Install awscli to support data backfill workflows using S3 storage
RUN pip3 install awscli --no-cache-dir

# Configure www-data user as primary php-fpm user for better local dev experience
RUN useradd www-data \
    && chmod 0755 ~www-data \
    && mkdir -p /var/www/html \
    && chown www-data:www-data /var/www/html \
    && echo "www-data ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd \
    && PHP_FPM_USER=$(grep -i '^user = ' /etc/php-fpm.d/www.conf | awk '{print $3}') \
    && PHP_FPM_GROUP=$(grep -i '^group = ' /etc/php-fpm.d/www.conf | awk '{print $3}') \
    && find /var/log /var/lib/php -uid $(id -u ${PHP_FPM_USER}) | xargs chown www-data \
    && find /var/log /var/lib/php -gid $(id -g ${PHP_FPM_GROUP}) | xargs chgrp www-data \
    && perl -pi -e 's/^(user|group) = php-fpm$/$1 = www-data/g' /etc/php-fpm.d/www.conf

WORKDIR /var/www/html
USER www-data
