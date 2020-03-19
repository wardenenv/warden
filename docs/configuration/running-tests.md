# Magento 2 Testing Environment

**Warden** is the first Development Environment that has testing in the blood.

That is why we introduced additional configuration switch:

```
WARDEN_INTEGRATION_TESTS=1
```

That builds additional `MySQL 5.7` database instance running directly on `tempfs` (blazing-fast memory).

Additionally, we've mounted locations of temporary files to `tempfs` memory too:

- `/var/www/html/dev/tests/integration/tmp/`

## Running Integration Tests

All the necessary files are located in `dev/tests/integration/`:

1. Create your `phpunit.xml` using contents of `phpunit.xml.dist`. We recommend to customize values of:

    - Maximum memory usage `TESTS_MEM_USAGE_LIMIT` with value of `8G` should be enough
    - Magento deployment mode `TESTS_MAGENTO_MODE` should be covered both for `developer` and `production`
    - Significantly increase the speed with `TESTS_PARALLEL_RUN` set to `1`
    
2. Configure your Magento Installation using `etc/install-config-mysql.php.dist` as a template. The arguments are exactly the same to those you use for `bin/magento setup:install`:

    ```php
   return [
       'db-host' => 'tmp-mysql',
       'db-user' => 'root',
       'db-password' => 'magento',
       'db-name' => 'magento_integration_tests',
       'backend-frontname' => 'backend',
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
        'admin/security/limit_password_reset_requests_method' => 0,
        'catalog/search/engine' => 'elasticsearch6',
        'catalog/search/elasticsearch6_server_hostname' => 'elasticsearch',
    ]; 
   ``` 
   
That's it! Now you are ready to run your first Integration Tests.

### Execution

There's one thing you should be aware of: **always provide full path to `phpunit.xml`**.

- To run all tests declared in `phpunit.xml` execute:<br> `vendor/bin/phpunit -c $(pwd)/dev/tests/integration/phpunit.xml`
- If you need to run only specific directory, execute:<br> `vendor/bin/phpunit -c $(pwd)/dev/tests/integration/phpunit.xml {ABSOLUTE PATH TO TESTS}` 

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