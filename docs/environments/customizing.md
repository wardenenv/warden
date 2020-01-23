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
