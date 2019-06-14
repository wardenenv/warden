FROM nginx:1.16-alpine

COPY etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf
COPY etc/nginx/default.d/magento2.conf /etc/nginx/default.d/magento2.conf

RUN mkdir -p /var/www/html/pub && chown -R 82:www-data /var/www/html

VOLUME  /var/www/html
WORKDIR /var/www/html
