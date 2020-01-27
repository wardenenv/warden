## Customizing An Environment

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
