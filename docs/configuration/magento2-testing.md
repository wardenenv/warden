# Testing Magento 2

**Warden** is the first Development Environment that has testing in the blood.

To enable testing components, set the following configuration in your project's `.env` file:

```
WARDEN_TEST_DB=1
```

This will launch an additional MySQL 5.7 database instance running on `tempfs` (blazing-fast memory) storage.

Temporary file locations have also been mounted into `tempfs` memory stoage:

- `/var/www/html/dev/tests/integration/tmp/`

## Running Unit Tests

Create your `phpunit.xml` using contents of `phpunit.xml.dist`. We recommend customizing values of:

- Memory usage `TESTS_MEM_USAGE_LIMIT` with value of `8G` should be enough

   ```xml
   <php>
       <const name="TESTS_MEM_USAGE_LIMIT" value="8G"/>
   </php> 
   ```
      
That's it! Now you are ready to run Unit Tests.

### Execution

- To run all tests declared in `phpunit.xml` execute:<br> `vendor/bin/phpunit -c dev/tests/unit/phpunit.xml`
- If you need to run only specific directory, execute:<br> `vendor/bin/phpunit -c dev/tests/unit/phpunit.xml {PATH TO TESTS}` 

### Debugging

If you have [configured Xdebug](xdebug.md), run Unit tests inside **Debug** console (`warden debug` instead of `warden shell`). The code execution will stop at the breakpoints.

## Running Javascript Unit Tests

1. Configure your `.env` and set `NODE_VERSION=10`
2. Launch a shell session within the project environment's `php-fpm` container with `warden shell`
3. Install javascript unit test dependencies with `npm install`
4. Deploy static content with
    
        bin/magento setup:static-content:deploy -f

### Execution

```bash
$ grunt spec:<THEME>
```

For more specific jasmine unit test instructions, see the Magento DevDocs ([Magento 2.4](https://devdocs.magento.com/guides/v2.4/test/js/jasmine.html))

### Troubleshooting

- You must be within your project environment's `php-fpm` container before running `npm install`.  If you are having issues
installing node packages, remove your `node_modules` directory with `rm -rf node_modules/ package-lock.json` and then retry `npm install`.
- If you have an issue with `jasmine` tests being unable to execute it might be due to installing the wrong versions of node `grunt-contrib-jasmine`.
You can fix this by using: 

```bash
cp package.json.sample package.json && rm -rf node_modules/ package-lock.json && npm install
```

## Running Integration Tests

All the necessary files are located in `dev/tests/integration/`:

1. Create your `phpunit.xml` using contents of `phpunit.xml.dist`. We recommend customizing values of:

    - Maximum memory usage `TESTS_MEM_USAGE_LIMIT` with value of `8G` should be enough
    - Magento deployment mode `TESTS_MAGENTO_MODE` should be covered both for `developer` and `production`
    - Significantly increase the speed with `TESTS_PARALLEL_RUN` set to `1`
    
2. You need to create `etc/install-config-mysql.php` based on `etc/install-config-mysql.php.dist` as a template. The arguments are exactly the same to those you use for `bin/magento setup:install`:

    ```php
   return [
       'db-host' => 'tmp-mysql',
       'db-user' => 'root',
       'db-password' => 'magento',
       'db-name' => 'magento_integration_tests',
       'backend-frontname' => 'backend',
       'search-engine' => 'elasticsearch7',
       'elasticsearch-host' => 'elasticsearch',
       'elasticsearch-port' => 9200,
       'admin-user' => \Magento\TestFramework\Bootstrap::ADMIN_NAME,
       'admin-password' => \Magento\TestFramework\Bootstrap::ADMIN_PASSWORD,
       'admin-email' => \Magento\TestFramework\Bootstrap::ADMIN_EMAIL,
       'admin-firstname' => \Magento\TestFramework\Bootstrap::ADMIN_FIRSTNAME,
       'admin-lastname' => \Magento\TestFramework\Bootstrap::ADMIN_LASTNAME,
       'amqp-host' => 'rabbitmq',
       'amqp-port' => '5672',
       'amqp-user' => 'guest',
       'amqp-password' => 'guest',
       'session-save' => 'redis',
       'session-save-redis-host' => 'redis',
       'session-save-redis-port' => 6379,
       'session-save-redis-db' => 2,
       'session-save-redis-max-concurrency' => 20,
       'cache-backend' => 'redis',
       'cache-backend-redis-server' => 'redis',
       'cache-backend-redis-db' => 0,
       'cache-backend-redis-port' => 6379,
       'page-cache' => 'redis',
       'page-cache-redis-server' => 'redis',
       'page-cache-redis-db' => 1,
       'page-cache-redis-port' => 6379,
   ];
   ```
   
3. You need to create `etc/config-global.php` based on `config-global.php.dist`. This is your container for Config data - for example: Configuration of Elasticsearch connection!

    ```php
    return [
        'customer/password/limit_password_reset_requests_method' => 0,
        'admin/security/admin_account_sharing' => 1,
        'admin/security/limit_password_reset_requests_method' => 0
    ]; 
   ``` 
   
That's it! Now you are ready to run your first Integration Tests.

### Execution

There's one thing you should be aware of: **always provide full path to `phpunit.xml`**.

- To run all tests declared in `phpunit.xml` execute:<br> `vendor/bin/phpunit -c $(pwd)/dev/tests/integration/phpunit.xml`
- If you need to run only specific directory, execute:<br> `vendor/bin/phpunit -c $(pwd)/dev/tests/integration/phpunit.xml {ABSOLUTE PATH TO TESTS}` 

### Debugging

If you have [configured Xdebug](xdebug.md), run Integration tests inside **Debug** console (`warden debug` instead of `warden shell`). The code execution will stop at the breakpoints.


### Troubleshooting

- In case you're getting a message like `Fatal error: Allowed memory size of ...` try to add prefix `php -dmemory_limit=-1` to your command, like 
    ```bash
    php -dmemory_limit=-1 vendor/bin/phpunit -c $(pwd)/dev/tests/integration/phpunit.xml
    ```

- If you're getting a message like `The store that was requested wasn't found. Verify the store and try again.` - run the following command 
    ```bash
    rm -Rf app/etc/env.php app/etc/config.php dev/tests/integration/tmp/*
    ```

## Running Setup Integration Tests

All the necessary files are located in `dev/tests/setup-integration/`:

1. Create your `phpunit.xml` using contents of `phpunit.xml.dist`. We recommend customizing values of:

    - Install config file `TESTS_INSTALL_CONFIG_FILE` should be `etc/install-config-mysql.php`
    - Tests cleanup `TESTS_CLEANUP` should be set to `enabled`
    - Magento deployment mode `TESTS_MAGENTO_MODE` should be covered both for `developer` and `production` (set to `developer` for start)
    
2. You need to create `etc/install-config-mysql.php` based on `etc/install-config-mysql.php.dist` as a template. Example:

    ```php
   return [
       'default' => [
           'db-host' => 'tmp-mysql',
           'db-user' => 'root',
           'db-password' => 'magento',
           'db-name' => 'magento_integration_tests',
           'db-prefix' => '',
           'backend-frontname' => 'admin',
           'admin-user' => 'admin',
           'admin-password' => '123123q',
           'admin-email' => \Magento\TestFramework\Bootstrap::ADMIN_EMAIL,
           'admin-firstname' => \Magento\TestFramework\Bootstrap::ADMIN_FIRSTNAME,
           'admin-lastname' => \Magento\TestFramework\Bootstrap::ADMIN_LASTNAME,
           'enable-modules' => 'Magento_TestSetupModule2,Magento_TestSetupModule1,Magento_Backend',
           'disable-modules' => 'all'
       ],
       'checkout' => [
           'host' => 'tmp-mysql',
           'username' => 'root',
           'password' => 'magento',
           'dbname' => 'magento_integration_tests'
       ],
       'sales' => [
           'host' => 'tmp-mysql',
           'username' => 'root',
           'password' => 'magento',
           'dbname' => 'magento_integration_tests'
       ]
   ];
   ```
   
That's it! Now you are ready to run your first Setup Integration Tests.

### Execution

There's one thing you should be aware of: **always provide full path to `phpunit.xml`**.

- To run all tests declared in `phpunit.xml` execute:<br> `vendor/bin/phpunit -c $(pwd)/dev/tests/setup-integration/phpunit.xml`
- If you need to run only specific directory, execute:<br> `vendor/bin/phpunit -c $(pwd)/dev/tests/setup-integration/phpunit.xml {ABSOLUTE PATH TO TESTS}` 

### Debugging

If you have [configured Xdebug](xdebug.md), run Integration tests inside **Debug** console (`warden debug` instead of `warden shell`). The code execution will stop at the breakpoints.

## Running API Functional Tests

All the necessary files are located in `dev/tests/api-functional/`.

1. Create your own `phpunit_{type}.xml` file using contents of `phpunit_{type}.xml.dist`. You **need** to configure:

    - Magento installation URL (with protocol) `TESTS_BASE_URL` - for example `https://app.magento2.test/`
    - Admin credentials `TESTS_WEBSERVICE_USER` and `TESTS_WEBSERVICE_APIKEY` (it's formally **password**)<br>
      _The Admin account should exist, it will be created only if `TESTS_MAGENTO_INSTALLATION` is enabled_

1. Configure your Magento Installation using `etc/install-config-mysql.php.dist` as a template. The arguments are exactly the same to those you use for `bin/magento setup:install`:

    ```php
   return [
       'db-host' => 'tmp-mysql',
       'db-user' => 'root',
       'db-password' => 'magento',
       'db-name' => 'magento_integration_tests',
       'cleanup-database' => true,
   
       'amqp-host' => 'rabbitmq',
       'amqp-port' => '5672',
       'amqp-user' => 'guest',
       'amqp-password' => 'guest',
       'session-save' => 'redis',
       'session-save-redis-host' => 'redis',
       'session-save-redis-port' => 6379,
       'session-save-redis-db' => 2,
       'session-save-redis-max-concurrency' => 20,
       'cache-backend' => 'redis',
       'cache-backend-redis-server' => 'redis',
       'cache-backend-redis-db' => 0,
       'cache-backend-redis-port' => 6379,
       'page-cache' => 'redis',
       'page-cache-redis-server' => 'redis',
       'page-cache-redis-db' => 1,
       'page-cache-redis-port' => 6379,
   
       'language' => 'en_US',
       'timezone' => 'America/Los_Angeles',
       'currency' => 'USD',
       'backend-frontname' => 'backend',
       'base-url' => 'https://app.magento2.test/',
       'use-secure' => '1',
       'use-rewrites' => '1',
       'admin-lastname' => 'Admin',
       'admin-firstname' => 'Admin',
       'admin-email' => 'admin@example.com',
       'admin-user' => 'admin',
       'admin-password' => '123123q',
       'admin-use-security-key' => '0',
       'sales-order-increment-prefix' => time(),
   ];
   ```

1. You need to create `etc/config-global.php` based on `config-global.php.dist`. This is your container for Config data - for example: Configuration of Elasticsearch connection!

    ```php
    return [
        'catalog/search/engine' => 'elasticsearch6',
        'catalog/search/elasticsearch6_server_hostname' => 'elasticsearch',
    ]; 
   ``` 

### Execution

There's one thing you should be aware of: **always provide full path to `phpunit.xml`**.

- To run all tests declared in `phpunit_{type}.xml` execute:<br> `vendor/bin/phpunit -c $(pwd)/dev/tests/api-functional/phpunit_{type}.xml`
- If you need to run only specific directory, execute:<br> `vendor/bin/phpunit -c $(pwd)/dev/tests/api-functional/phpunit_{type}.xml {ABSOLUTE PATH TO TESTS}` 

### Debugging

When debugging APIs you may need to use Xdebug - configure your `phpunit_{type}.xml`:

   - `TESTS_XDEBUG_ENABLED` to `true`
   - `TESTS_XDEBUG_SESSION` to `phpstorm`
   
## Running MFTF Tests

All the MFTF-related operations are operated by `vendor/bin/mftf`, necessary files are located in `dev/tests/acceptance/`.

To run Acceptance tests you need to [configure the MFTF environment](mftf.md). Once you've done that, follow these steps to run the tests.

1. Make sure that you enabled following in your `.env` file:
    - `WARDEN_SELENIUM` - Responsible for running virtual browser for your tests
    - `WARDEN_ALLURE` - Responsible for test results reporting
    - `WARDEN_SELENIUM_DEBUG` - Enables you to preview the tests with VNC
1. Run `vendor/bin/mftf build:project`, the configuration files will be generated in `dev/tests/acceptance`.
1. Adjust `dev/tests/acceptance/.env` file by setting:
    - `MAGENTO_BASE_URL`
    - `MAGENTO_BACKEND_NAME` to your Backend path (Check with `bin/magento info:adminuri`)
    - `MAGENTO_ADMIN_USERNAME` and `MAGENTO_ADMIN_PASSWORD`
    - `SELENIUM_HOST` (by default it is `selenium-hub`)

   Sample configuration
   ```
   MAGENTO_BASE_URL=https://app.magento2.test/
   MAGENTO_BACKEND_NAME=backend
   MAGENTO_ADMIN_USERNAME=admin
   MAGENTO_ADMIN_PASSWORD=123123q
   BROWSER=chrome
   MODULE_WHITELIST=Magento_Framework,ConfigurableProductWishlist,ConfigurableProductCatalogSearch
   ELASTICSEARCH_VERSION=7
   SELENIUM_HOST=selenium-hub
   ```
   More details can be found [in Magento DevDocs](https://devdocs.magento.com/mftf/docs/configuration.html).

### Execution

* Execute single test<br>`vendor/bin/mftf run:test -r AdminLoginTest`
* Execute group/suite of tests<br>`vendor/bin/mftf run:group -r customer`

### Debugging

For more information about Debugging MFTF - please follow the [Magento Functional Testing Framework](mftf.md) section.
The process of debugging is based on VNC connection to the Chrome instance.

You can connect to Chrome session with `warden vnc` command.
