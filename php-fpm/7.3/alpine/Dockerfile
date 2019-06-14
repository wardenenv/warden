FROM php:7.3-fpm-alpine3.9

# Install dependencies
RUN apk add --no-cache \
        bzip2-dev \
        freetype-dev \
        gettext-dev \
        icu-dev \
        imap-dev \
        libjpeg-turbo-dev \
        libpng-dev \
        libxml2-dev \
        libxslt-dev \
        libzip-dev \
        rabbitmq-c-dev

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
    && docker-php-ext-enable xdebug redis igbinary amqp \
    && apk del .build-deps

COPY etc/php.ini /usr/local/etc/php/php.ini
COPY etc/opcache.ini /usr/local/etc/php/conf.d/05-opcache.ini
COPY --from=composer /usr/bin/composer /usr/bin/composer

RUN mkdir -p /var/www/html/pub && chown -R www-data:www-data /var/www/html

USER www-data

VOLUME  /var/www/html
WORKDIR /var/www/html
