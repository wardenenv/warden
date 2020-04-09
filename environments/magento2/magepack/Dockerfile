FROM zenika/alpine-chrome:with-puppeteer

USER root

WORKDIR /var/www/html
COPY generate.sh /usr/bin/generate
COPY bundle.sh /usr/bin/bundle

RUN mkdir -p /var/www/html && \
    npm install -g git+https://github.com/vbuck/magepack.git && \
    npm cache clean --force

ENTRYPOINT ["tail", "-f", "/dev/null"]
