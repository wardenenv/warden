FROM php:7.1-fpm-alpine3.9

# Install dependencies
RUN apk add --no-cache \
        shadow \
        bzip2-dev \
        freetype-dev \
        gettext-dev \
        icu-dev \
        imap-dev \
        libjpeg-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        libxml2-dev \
        libxslt-dev \
        libzip-dev \
        rabbitmq-c-dev \
        bash

# Install required PHP extensions
RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
    && docker-php-ext-configure \
        gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install \
        bcmath \
        gd \
        bz2 \
        calendar \
        exif \
        gettext \
        imap \
        intl \
        mcrypt \
        shmop \
        soap \
        sockets \
        xmlrpc \
        xsl \
        zip \
        pdo_mysql \
        dom \
        pcntl \
        opcache \
    && pecl channel-update pecl.php.net \
    && echo -e "yes\nyes" | pecl install -o -f \
        xdebug \
        igbinary \
        redis \
        amqp \
    && docker-php-ext-enable redis igbinary amqp \
    && apk del .build-deps

COPY etc/php.ini /usr/local/etc/php/php.ini
COPY etc/opcache.ini /usr/local/etc/php/conf.d/05-opcache.ini
COPY --from=composer /usr/bin/composer /usr/bin/composer

# Configure pretty PS1 with differing colors for root and www-data
RUN echo "export PS1='\[\033[0;0m\]\u@\h\[\033[0m\]:\[\033[0;31m\]\w\[\033[0m\]# '" >> /root/.bashrc \
    && echo "export PS1='\[\033[0;36m\]\u@\h\[\033[0m\]:\[\033[0;37m\]\w\[\033[0m\]$ '" >> /home/www-data/.bashrc

RUN usermod -u 1000 www-data && groupmod -g 1000 www-data && chown www-data:www-data /var/www/html
USER www-data

VOLUME  /var/www/html
WORKDIR /var/www/html
