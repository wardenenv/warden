## Environment Configuration

### Environment Types

Warden currently supports three environment types. These types are passed to `env-init` when configuring a project for local development for the first time. This list of environment types can also be seen by running `warden env-init --help` on your command line.

* [`local`](https://github.com/davidalger/warden/blob/master/environments/local.base.yml) This environment type does nothing more than declare the `docker-compose` version and declare the external `warden` network which Traefik uses to proxy requests into the project's containers. When this is used, a `.warden/warden-env.yml` may be placed in the root directory of the project workspace to define the desired containers, volumes, etc needed for the project. An example of a `local` environment type being used can be found in the [m2demo project](https://github.com/davidalger/m2demo).
* `magento2` Provides the necessary containerized services for running Magento 2 in a local development context including Nginx, Varnish, php-fpm (PHP 7.0+), MariaDB, Elasticsearch, RabbitMQ and Redis. In order to achieve a well performing experience on macOS, source files are synced into the container using a Mutagen sync session (`pub/media` remains mounted using a delegated mount).
* `magento1` Supports development of Magento 1 projects, launching containers for Nginx, php-fpm (PHP 5.5, 5.6 or 7.0+), MariaDB and Redis. Files mounted using delegated mount on macOS and natively on Linux.
* `laravel` Supports development of Laravel projects, launching containers for Nginx, php-fpm, MariaDB and Redis. Files mounted using delegated mount on macOS and natively on Linux.

All environment types (other than `local`) come pre-configured with a `mailhog` container, with `fpm` services configured to use `mhsendmail` to ensure outbound email does not inadvertently send out, and allows for simpler testing of email functionality on projects (you can use [Traefik](https://traefik.warden.test/) to find the `mailhog` url for each project). There are also two `fpm` containers, `php-fpm` and `php-debug` (more on this later) to provide Xdebug support enabled via nothing more than setting the `XDEBUG_SESSION` cookie in your browser to direct the request to the `php-debug` container.

For full details and a complete list of variables which may be used to adjusting things such as PHP or MySQL versions (by setting them in the project's `.env` file), and to see the `docker-compose` definitions used to assemble each environment type, look at the contents of the [environments directory](https://github.com/davidalger/warden/tree/master/environments) in this repository. Each environment has a `base` configuration YAML file, and optionally a `darwin` and `linux-gnu` file which add to the `base` definitions anything specific to a given host architecture (this is, for example, how the `magento2` environment type works seamlessly on macOS with Mutagen sync sessions while using native filesystem mounts on Linux hosts). This directory also houses the configuration used for starting Mutagen sync sessions on a project via the `warden sync start` command.

### Initializing An Environment

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

       ## Run application install process
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

       ## Generate an admin user
       ADMIN_PASS="$(cat /dev/urandom | base64 | head -n1 | sed 's/[^a-zA-Z0-9]//g' | colrm 17)"
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

### Customizing An Environment

Further information on customizing or extending an environment is forthcoming. For now, this section is limited to very simple and somewhat common customizations.

To configure your project with a non-default PHP version, add the following to the project's `.env` file and run `warden env up -d` to re-create the affected containers:

    PHP_VERSION=7.2

The versions of MariaDB, Elasticsearch, Varnish, Redis, and NodeJS may also be similarly configured using variables in the `.env` file:

  * `MARIADB_VERSION`
  * `ELASTICSEARCH_VERSION`
  * `REDIS_VERSION`
  * `VARNISH_VERSION`
  * `RABBITMQ_VERSION`
  * `NODE_VERSION`

### Magento 2 Specific Customizations

The following variables can be added to the project's `.env` file to enable additional database containers for use with the Magento 2 (Commerce Only) [split-database solution](https://devdocs.magento.com/guides/v2.3/config-guide/multi-master/multi-master.html).

  * `WARDEN_SPLIT_SALES=1`
  * `WARDEN_SPLIT_CHECKOUT=1`

### Additional Domains

If you need multiple domains pointing to the same server, you can follow the instructions below. In this example, we're going to add both an additional subdomain for an existing domain as well as add a couple of additional domains.

1. Sign certificates for your new domains:
   
       warden sign-certificate exampleproject2.test
       warden sign-certificate exampleproject3.test
    
2. Create a `.warden/warden-env.yml` file with the contents below (this will be additive to the docker-compose config Warden uses for the env, anything added here will be merged in, and you can see the complete config using `warden env config`):
   
       version: "3.5"
       services:
         varnish:
           labels:
             traefik.frontend.rule: Host:${TRAEFIK_HOST_LIST}
   
3. Add a comma-separated list of domains to the `.env` file (we're going to assume you want to continue to use the `app.exampleproject.test` domain for your primary application, so we're including that in the list):
   
       TRAEFIK_HOST_LIST=app.exampleproject.test,subdomain.exampleproject.test,exampleproject2.test,exampleproject3.test

4.  It will be up to you to ensure your application properly handles traffic coming from each of those domains (by editing the nginx configuration or your application). An example approach can be found [here](https://github.com/davidalger/warden/pull/37#issuecomment-554651099).

5. Run `warden env up -d` to update the containers then each of the URLs should work as expected.
