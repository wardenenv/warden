ARG ENV_SOURCE_IMAGE
ARG PHP_VERSION
FROM ${ENV_SOURCE_IMAGE}:${PHP_VERSION}
USER root

RUN curl -o - "http://packages.blackfire.io/fedora/blackfire.repo" \
    | sudo tee /etc/yum.repos.d/blackfire.repo \
    && dnf install -y blackfire-php \
    && dnf clean all \
    && rm -rf /var/cache/dnf

# Install the Blackfire Client to provide access to the CLI tool
RUN mkdir -p /tmp/blackfire \
    && curl -L https://blackfire.io/api/v1/releases/client/linux_static/amd64 | tar zxp -C /tmp/blackfire \
    && mv /tmp/blackfire/blackfire /usr/bin/blackfire \
    && rm -rf /tmp/blackfire

COPY blackfire/etc/php.d/*.ini /etc/php.d/

USER www-data
