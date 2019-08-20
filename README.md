# Warden
Warden is a CLI utility for orchestrating Docker developer environments, and enables multiple local environments to run simultaneously without port conflicts via the use of a few centrally run services for proxying requests into the correct environment's containers. Under the hood, `docker-compose` is used to to control everything which Warden runs (shared services as well as per-project containers) on Docker Engine.

## Prerequisites

* [Homebrew](https://brew.sh/) package manager (for installing Warden and other dependencies)
* [Docker for Mac](https://hub.docker.com/editions/community/docker-ce-desktop-mac) or [Docker for Linux](https://docs.docker.com/install/) (tested on Fedora 29 and Ubuntu 18.10)
* `docker-compose` available in your `$PATH` (included with Docker for Mac, can be installed via `brew`, `apt` or `dnf` on Linux)
* [Mutagen](https://mutagen.io/) v0.9.0 or later installed via Homebrew (required on macOS only; Warden will attempt to install this via `brew` if not present when running `warden sync start`).

### Recomended Additions

* `pv` installed and available in your `$PATH` (you can install this via `brew install pv`) for use sending database files to `warden db import` and providing determinate progress indicators for the import. Alternatively `cat` may be used where `pv` is referenced in documentation but will not provide progress indicators.

## Installing Warden

Warden may be installed via [Homebrew](https://brew.sh/) on both macOS and Linux hosts:

    brew install davidalger/warden/warden
    warden up

Alternatively Warden may also be installed by cloning the repository to the directory of your choice and adding it to your `$PATH`:

    sudo mkdir /opt/warden
    sudo chown $(whoami) /opt/warden
    git clone -b master git@github.com:davidalger/warden.git /opt/warden
    echo 'export PATH="/opt/warden/bin:$PATH"' >> ~/.bash_profile
    PATH="/opt/warden/bin:$PATH"

## Features

* Traefik for SSL termination and routing/proxying requests into the correct containers.
* Portainer for quick visibility into what's running inside the local Docker host.
* Dnsmasq to serve DNS responses for `.test` domains eliminating manual editing of `/etc/hosts`
* An SSH tunnel for connecting from Sequel Pro or TablePlus into any one of multiple running database containers.
* Warden issued wildcard SSL certificates for running https on all local development domains.
* Full support for both Magento 1, Magento 2, and custom per-project environment configurations on macOS and Linux.
* Ability to override, extend, or setup completely custom environment definitions on a per-project basis.

After running `warden up` for the first time following installation, the following URLs can be used to interact with the UIs for services Warden runs globally:

* https://traefik.warden.test/
* https://portainer.warden.test/
* https://dnsmasq.warden.test/

### Environment Types

Warden currently supports three environment types. These types are passed to `env-init` when configuring a project for local development for the first time. This list of environment types can also be seen by running `warden env-init --help` on your command line.

* [`local`](https://github.com/davidalger/warden/blob/master/environments/local.base.yml) This environment type does nothing more than declare the `docker-compose` version and declare the external `warden` network which Traefik uses to proxy requests into the project's containers. When this is used, a `.warden/warden-env.yml` may be placed in the root directory of the project workspace to define the desired containers, volumes, etc needed for the project. An example of a `local` environment type being used can be found in the [m2demo project](https://github.com/davidalger/m2demo).
* `magento2` Provides the necessary containerized services for running Magento 2 in a local development context including Nginx, Varnish, php-fpm (PHP 7.1+), MariaDB, Elasticsearch, RabbitMQ and Redis. In order to achieve a well performing experience on macOS, source files are synced into the container using a Mutagen sync session (`pub/media` remains mounted using a delegated mount).
* `magento1` Supports development of Magento 1 projects, launching containers for Nginx, php-fpm (PHP 5.5, 5.6 or 7.1+), MariaDB and Redis. Files mounted using delegated mount on macOS and natively on Linux.

All environment types (other than `local`) come pre-configured with a `mailhog` container, with `fpm` services configured to use `mhsendmail` to ensure outbound email does not inadvertently send out, and allows for simpler testing of email functionality on projects. There are also two `fpm` containers, `php-fpm` and `php-debug` (more on this later) to provide Xdebug support enabled via nothing more than setting the `XDEBUG_SESSION` cookie in your browser to direct the request to the `php-debug` container.

For full details and a complete list of variables which may be used to adjusting things such as PHP or MySQL versions (by setting them in the project's `.env` file), and to see the `docker-compose` definitions used to assemble each environment type, look at the contents of the [environments directory](https://github.com/davidalger/warden/tree/master/environments) in this repository. Each environment has a `base` configuration YAML file, and optionally a `darwin` and `linux-gnu` file which add to the `base` definitions anything specific to a given host architecture (this is, for example, how the `magento2` environment type works seamlessly on macOS with Mutagen sync sessions while using native filesystem mounts on Linux hosts). This directory also houses the configuration used for starting Mutagen sync sessions on a project via the `warden sync start` command.

## Warden Usage

### Common Warden Commands

Drop into a shell within the project environment (this command opens a bash shell in the `php-fpm` container)

    warden shell

Stopping a running environment (on linux, drop the `sync` command, it's not used on Linux)

    warden env stop && warden sync stop

Starting a stopped environment (on linux, drop the `sync` command, it's not used on Linux)

    warden env start && warden sync start

Watch the database processlist:

    watch -n 3 "warden db connect -A -e 'show processlist'"

Tail environment access logs:

    warden env logs --tail 0 -f nginx php-fpm php-debug

Tail the varnish activity log:

    warden env exec -T varnish varnishlog

### Warden Usage Information

Run `warden help` and `warden env -h` for more details and useful command information.

## Environment Configuration

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

5. Drop into a shell within the project environment. Commands following this step in the setup procedure will be run from within the `php-fpm` docker container this launches you into:

       warden shell

6. If you already have Magento Marketplace credentials configured, you may skip this step (`~/.composer/` on the host is mounted into the container to share composer cache between projects, and has the effect of persisting the `auth.json` on the host machine as well):

    Note: To locate your authentication keys for Magento 2 repository, reference [this page on DevDocs](https://devdocs.magento.com/guides/v2.3/install-gde/prereq/connect-auth.html).

       composer global config http-basic.repo.magento.com <username> <password>

7. Initialize project source files using composer create-project:

       composer create-project --repository-url=https://repo.magento.com/ \
           magento/project-community-edition /tmp/exampleproject 2.3.x

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

The versions of MariaDB, Elasticsearch, Varnish and Redis may also be similarly configured using variables in the `.env` file:

  * `MARIADB_VERSION`
  * `ELASTICSEARCH_VERSION`
  * `REDIS_VERSION`
  * `VARNISH_VERSION`
  * `RABBITMQ_VERSION`

## License

This work is licensed under the MIT license. See LICENSE file for details.

## Author Information

This project was started in 2019 by [David Alger](https://davidalger.com/).
