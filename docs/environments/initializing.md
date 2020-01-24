## Initializing An Environment

The below example demonstrates the from-scratch setup of the Magento 2 application for local development. A similar process can easily be used to configure an environment of any other type. This assumes that Warden has been previously started via `warden up` as part of the installation procedure.

1. Create a new directory on your host machine at the location of your choice and then jump into the new directory to get started:

       mkdir -p ~/Sites/exampleproject
       cd ~/Sites/exampleproject

2. From the root of your new project directory, run `env-init` to create the `.env` file with configuration needed for Warden and Docker to work with the project. 

       warden env-init exampleproject magento2

    The result of this command is a `.env` file in the project root (tip: commit this to your VCS to share the configuration with other team members) having the following contents:

       WARDEN_ENV_NAME=exampleproject
       WARDEN_ENV_TYPE=magento2
       TRAEFIK_DOMAIN=exampleproject.test
       TRAEFIK_SUBDOMAIN=app

       BYPASS_VARNISH=false

       ELASTICSEARCH_VERSION=6.8
       MARIADB_VERSION=10.3
       NODE_VERSION=10
       PHP_VERSION=7.2
       RABBITMQ_VERSION=3.7.14
       REDIS_VERSION=5.0
       VARNISH_VERSION=4.1

       WARDEN_SELENIUM=0
       WARDEN_BLACKFIRE=0
       WARDEN_SPLIT_SALES=0
       WARDEN_SPLIT_CHECKOUT=0

       BLACKFIRE_CLIENT_ID="<client_id>"
       BLACKFIRE_CLIENT_TOKEN="<client_token>"
       BLACKFIRE_SERVER_ID="<server_id>"
       BLACKFIRE_SERVER_TOKEN="<server_token>"

3. Sign an SSL certificate for use with the project (the input here should match the value of `TRAEFIK_DOMAIN` in the above `.env` example file):

       warden sign-certificate exampleproject.test

4. Next you'll want to start the project environment:

       warden env up -d
       warden sync start   ## Omit this if running on a Linux host (or if not used by env type)

   If you encounter an error about `Mounts denied…`, follow the instructions in the error message and run `warden env up -d` again.

5. Drop into a shell within the project environment. Commands following this step in the setup procedure will be run from within the `php-fpm` docker container this launches you into:

       warden shell

6. If you already have Magento Marketplace credentials configured, you may skip this step (`~/.composer/` on the host is mounted into the container to share composer cache between projects, and has the effect of persisting the `auth.json` on the host machine as well):

    Note: To locate your authentication keys for Magento 2 repository, reference [this page on DevDocs](https://devdocs.magento.com/guides/v2.3/install-gde/prereq/connect-auth.html).

       composer global config http-basic.repo.magento.com <username> <password>

7. Initialize project source files using composer create-project and then move them into place:

       composer create-project --repository-url=https://repo.magento.com/ \
           magento/project-community-edition /tmp/exampleproject 2.3.x

       rsync -a /tmp/exampleproject/ /var/www/html/
       rm -rf /tmp/exampleproject/

8. Install the application and you should be all set:

       ## Install Application
       bin/magento setup:install \
           --backend-frontname=backend \
           --amqp-host=rabbitmq \
           --amqp-port=5672 \
           --amqp-user=guest \
           --amqp-password=guest \
           --db-host=db \
           --db-name=magento \
           --db-user=magento \
           --db-password=magento \
           --http-cache-hosts=varnish:80 \
           --session-save=redis \
           --session-save-redis-host=redis \
           --session-save-redis-port=6379 \
           --session-save-redis-db=2 \
           --session-save-redis-max-concurrency=20 \
           --cache-backend=redis \
           --cache-backend-redis-server=redis \
           --cache-backend-redis-db=0 \
           --cache-backend-redis-port=6379 \
           --page-cache=redis \
           --page-cache-redis-server=redis \
           --page-cache-redis-db=1 \
           --page-cache-redis-port=6379

       ## Configure Application
       bin/magento config:set --lock-env web/unsecure/base_url \
           "https://${TRAEFIK_SUBDOMAIN}.${TRAEFIK_DOMAIN}/"

       bin/magento config:set --lock-env web/secure/base_url \
           "https://${TRAEFIK_SUBDOMAIN}.${TRAEFIK_DOMAIN}/"

       bin/magento config:set --lock-env web/secure/offloader_header X-Forwarded-Proto

       bin/magento config:set --lock-env web/secure/use_in_frontend 1
       bin/magento config:set --lock-env web/secure/use_in_adminhtml 1
       bin/magento config:set --lock-env web/seo/use_rewrites 1

       bin/magento config:set --lock-env system/full_page_cache/caching_application 2
       bin/magento config:set --lock-env system/full_page_cache/ttl 604800

       bin/magento config:set --lock-env catalog/search/engine elasticsearch6
       bin/magento config:set --lock-env catalog/search/enable_eav_indexer 1
       bin/magento config:set --lock-env catalog/search/elasticsearch6_server_hostname elasticsearch
       bin/magento config:set --lock-env catalog/search/elasticsearch6_server_port 9200
       bin/magento config:set --lock-env catalog/search/elasticsearch6_index_prefix magento2
       bin/magento config:set --lock-env catalog/search/elasticsearch6_enable_auth 0
       bin/magento config:set --lock-env catalog/search/elasticsearch6_server_timeout 1

       bin/magento config:set --lock-env dev/static/sign 0

       bin/magento deploy:mode:set -s developer
       bin/magento cache:disable block_html full_page

       ## Generate an admin user
       ADMIN_PASS="$(pwgen -n1 16)"
       ADMIN_USER=localadmin

       bin/magento admin:user:create \
           --admin-password="${ADMIN_PASS}" \
           --admin-user="${ADMIN_USER}" \
           --admin-firstname="Local" \
           --admin-lastname="Admin" \
           --admin-email="${ADMIN_USER}@example.com"
       printf "u: %s\np: %s\n" "${ADMIN_USER}" "${ADMIN_PASS}"

9. Launch the application in your browser:

    * https://app.exampleproject.test/
    * https://app.exampleproject.test/backend/
    * https://mailhog.exampleproject.test/
    * https://rabbitmq.exampleproject.test/
    * https://elasticsearch.exampleproject.test/

Note: To completely destroy the `exampleproject` environment we just created, run `warden env down -v` to tear down the project's Docker containers, volumes, etc, then `warden sync stop` as needed to terminate the Mutagen session.
