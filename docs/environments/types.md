### Environment Types

Warden currently supports three environment types. These types are passed to `env-init` when configuring a project for local development for the first time. This list of environment types can also be seen by running `warden env-init --help` on your command line. The `docker-compose` configuration used to assemble each environment type can be found in the [environments directory](https://github.com/davidalger/warden/tree/master/environments) on Github.

#### Local

The `local` environment type does nothing more than declare the `docker-compose` version and label the project network so Warden will recognize it as belonging to an environment orchestrated by Warden.

When this type is used, a `.warden/warden-env.yml` may be placed in the root directory of the project workspace to define the desired containers, volumes, etc needed for the project. An example of a `local` environment type being used can be found in the [m2demo project](https://github.com/davidalger/m2demo).

Similar to the other environment type's base definitions, Warden supports a `warden-env.darwin.yml` and `warden-env.linux.yml`

#### Magento 2

The `magento2` environment type provides necessary containerized services for running Magento 2 in a local development context including:

* Nginx
* Varnish
* PHP-FPM (7.0+)
* MariaDB
* Elasticsearch
* RabbitMQ
* Redis

In order to achieve a well performing experience on macOS, files in the webroot are synced into the container using a Mutagen sync session with the exception of `pub/media` which remains mounted using a delegated mount.

#### Magento 1

The `magento1` environment type supports development of Magento 1 projects, launching containers including:

* Nginx
* PHP-FPM (5.5, 5.6 or 7.0+)
* MariaDB
* Redis

Files are currently mounted using a delegated mount on macOS and natively on Linux.

#### Laravel

The `laravel` environment type supports development of Laravel projects, launching containers including:

* Nginx
* PHP-FPM
* MariaDB
* Redis

Files are currently mounted using a delegated mount on macOS and natively on Linux.

#### Symfony

The `symfony` environment type supports development of Symfony 4+ projects, launching containers including:

* Nginx
* PHP-FPM
* MariaDB
* Redis
* RabbitMQ (disabled by default)
* Varnish (disabled by default)
* Elasticsearch (disabled by default)

Files are currently mounted using a delegated mount on macOS and natively on Linux.

#### Shopware

The `shopware` environment type supports development of Shopware 6 projects, launching containers including:

* Nginx
* PHP-FPM
* MariaDB
* Redis
* RabbitMQ (disabled by default)
* Varnish (disabled by default)
* Elasticsearch (disabled by default)

In order to achieve a well performing experience on macOS, files in the webroot are synced into the container using a Mutagen sync session with the exception of `public/media` which remains mounted using a delegated mount.

#### Commonalities

In addition to the above, each environment type (with the exception of the `local` type) come with PHP setup to use `mhsendmail` to ensure outbound email does not inadvertently leave your network and to support simpler testing of email functionality. Mailhog may be accessed by navigating to [https://mailhog.warden.test/](https://mailhog.warden.test/) in a browser.

Where PHP is specified in the above list, there should be two `fpm` containers, `php-fpm` and `php-debug` in order to provide Xdebug support. Use of Xdebug is enabled by setting the `XDEBUG_SESSION` cookie in your browser to direct the request to the `php-debug` container. Shell sessions opened in the debug container via `warden debug` will also connect PHP process for commands on the CLI to Xdebug.

The configuration of each environment leverages a `base` configuration YAML file, and optionally a `darwin` and `linux` file to add to `base` configuration anything which may be specific to a given host architecture (this is, for example, how the `magento2` environment type works seamlessly on macOS with Mutagen sync sessions while using native filesystem mounts on Linux hosts).

### Environment Templates

There is a [Github Template available for Magento 2](https://github.com/davidalger/warden-env-magento2) allowing for quick setup of new Magento projects. To use this, click the green "Use this template" button to create your own repository based on the template repository, run the init script and update the README with any project specific information.
