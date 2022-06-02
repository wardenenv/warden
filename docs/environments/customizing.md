## Customizing An Environment

Further information on customizing or extending an environment is forthcoming. For now, this section is limited to very simple and somewhat common customizations.

To configure your project with a non-default PHP version, add the following to the project's `.env` file and run `warden env up` to re-create the affected containers:

    PHP_VERSION=7.2

The versions of MariaDB/Mysql, Elasticsearch, Varnish, Redis, NodeJS and Composer may also be similarly configured using variables in the `.env` file:

  * `MYSQL_DISTRIBUTION_VERSION` (Available distributions: `MYSQL_DISTRIBUTION=mysql` or `MYSQL_DISTRIBUTION=mariadb`)
  * `ELASTICSEARCH_VERSION`
  * `REDIS_VERSION`
  * `VARNISH_VERSION`
  * `RABBITMQ_VERSION`
  * `NODE_VERSION`
  * `COMPOSER_VERSION`

Start of some environments could be skipped by using variables in `.env` file:

  * `WARDEN_DB=0`
  * `WARDEN_REDIS=0`

### Docker Specific Customizations
To override default docker settings, add a custom configuration file in your project root
folder: `/.warden/warden-env.yml`
This file will be merged with the default environment configuration.
One example for a use case is [the setup of multiple domains](https://docs.warden.dev/configuration/multipledomains.html?highlight=warden%20env%20yml#multiple-domains).

### PHP Specific Customizations
To override default php settings, follow the docker customization above and include your custom `php.ini` file.
In this case the `warden-env.yml` should look like this:

```
version: "3.5"
services:
  php-fpm:
    volumes:
      - ./.warden/php/zz-config.ini:/etc/php.d/zz-config.ini
  php-debug:
    volumes:
      - ./.warden/php/zz-config.ini:/etc/php.d/zz-config.ini
```
Now add the referenced `.warden/php/zz-config.ini` file with your wanted changes.
For example you could change the error reporting value:
```
error_reporting=(E_ALL ^ E_DEPRECATED)
```
The config file will be merged with the default `01-php.ini` resp. override the values
included there. The default values are the following:
```
date.timezone = UTC
max_execution_time = 3600
max_input_vars = 10000
memory_limit = 2G
display_errors = On
post_max_size = 25M
session.auto_start = Off
upload_max_filesize = 25M
```
### Nginx Specific Customizations
To override the default nginx configuration of your project, add a new file 
`.warden/warden-env.yml` to your project root with the following content:
```
version: "3.5"
services:
  nginx:
    volumes:
      - ./.warden/nginx/custom.conf:/etc/nginx/default.d/custom.conf
```
There you can specify a custom Nginx configuration which will be included following the `.conf` files within the `/etc/nginx/available.d` directory: `include /etc/nginx/default.d/*.conf`

### Magento 1 Specific Customizations

If you use a `modman` structure, initialize the environment in your project path. 
The `.modman` folder and the corresponding `.basedir` file will be recognized and set up automatically. 

### Magento 2 Specific Customizations

The following variables can be added to the project's `.env` file to enable additional database containers for use with the Magento 2 (Commerce Only) [split-database solution](https://devdocs.magento.com/guides/v2.3/config-guide/multi-master/multi-master.html).

  * `WARDEN_SPLIT_SALES=1`
  * `WARDEN_SPLIT_CHECKOUT=1`

Start of some Magento 2 specific environments could be skipped by using variables in `.env` file:

  * `WARDEN_ELASTICSEARCH=0`
  * `WARDEN_VARNISH=0`
  * `WARDEN_RABBITMQ=0`
