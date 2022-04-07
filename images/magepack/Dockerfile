FROM zenika/alpine-chrome:with-puppeteer

USER root

WORKDIR /var/www/html
COPY bin/generate.sh /usr/bin/generate
COPY bin/bundle.sh /usr/bin/bundle

ARG MAGEPACK_VERSION=2.3
RUN npm install -g magepack@^${MAGEPACK_VERSION} && npm cache clean --force

CMD tail -f /dev/null

USER chrome
