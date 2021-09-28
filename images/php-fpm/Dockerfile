ARG PHP_TAG
FROM ghcr.io/drpayyne/php-fpm-loaders:${PHP_TAG}

# Clear undesired settings from base fpm images
ENV COMPOSER_ALLOW_SUPERUSER=
ENV COMPOSER_HOME=

ENV MAILHOG_HOST    mailhog
ENV MAILHOG_PORT    1025

RUN apt update

RUN apt install -y pv sudo bind9-utils python3-pip bash-completion rsync socat oathtool \
        wget ack automake autoconf nano vim cron mariadb-server

RUN apt install -y python2 && ln -s /usr/bin/python2 /usr/bin/python

ENV NODE_VERSION    10
RUN npm install -g n \
    && n install ${NODE_VERSION} \
    && rm -rf /usr/local/n/versions/node

COPY docker-entrypoint /usr/local/bin/
COPY etc/profile.d/*.sh /etc/profile.d/
COPY etc/*.ini /etc/
COPY etc/php.d/*.ini /usr/local/etc/php/conf.d
COPY etc/php.d/05-additions.ini.template /usr/local/etc/php/conf.d

ARG TARGETARCH

# Install mhsendmail to support routing email through mailhog
RUN mkdir -p /tmp/mhsendmail \
    && cd /tmp/mhsendmail \
    && curl -vLOs https://github.com/drpayyne/mhsendmail/releases/download/v0.3.0/mhsendmail_linux_$TARGETARCH \
    && chmod +x mhsendmail_linux_$TARGETARCH \
    && mv mhsendmail_linux_$TARGETARCH /usr/local/bin/mhsendmail

# Install awscli to support data backfill workflows using S3 storage; segno for QR code generation
RUN pip3 install awscli segno --no-cache-dir

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
