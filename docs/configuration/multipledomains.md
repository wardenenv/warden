## Multiple Domains

If you need multiple domains configured for your project, Warden will now automatically route all sub-domains of the configured `TRAEFIK_DOMAIN` (as given when running `env-init`) to the Varnish/Nginx containers provided there is not a more specific rule such as for example `rabbitmq.exampleproject.com` which routes to the `rabbitmq` service for the project.

Multiple top-level domains may also be setup by following the instructions below:

1. Sign certificates for your new domains:
   
       warden sign-certificate alternate1.test
       warden sign-certificate alternate2.test
    
2. Create a `.warden/warden-env.yml` file with the contents below (this will be additive to the docker-compose config Warden uses for the env, anything added here will be merged in, and you can see the complete config using `warden env config`):

    ```yaml
    version: "3.5"
    services:
      varnish:
        labels:
          - traefik.http.routers.${WARDEN_ENV_NAME}-varnish.rule=
              HostRegexp(`{subdomain:.+}.${TRAEFIK_DOMAIN}`)
              || Host(`${TRAEFIK_DOMAIN}`)
              || HostRegexp(`{subdomain:.+}.alternate1.test`)
              || Host(`alternate1.test`)
              || HostRegexp(`{subdomain:.+}.alternate2.test`)
              || Host(`alternate2.test`)
      nginx:
        labels:
          - traefik.http.routers.${WARDEN_ENV_NAME}-nginx.rule=
              HostRegexp(`{subdomain:.+}.${TRAEFIK_DOMAIN}`)
              || Host(`${TRAEFIK_DOMAIN}`)
              || HostRegexp(`{subdomain:.+}.alternate1.test`)
              || Host(`alternate1.test`)
              || HostRegexp(`{subdomain:.+}.alternate2.test`)
              || Host(`alternate2.test`)
    ```

3. Configure the application to handle traffic coming from each of these domains appropriately. An example on this for Magento 2 environments may be found below.

4. Run `warden env up` to update the containers, after which each of the URLs should work as expected.

    ``` note::
        If these alternate domains must be resolvable from within the FPM containers, you must also leverage ``extra_hosts`` to add each specific sub-domain to the ``/etc/hosts`` file of the container as dnsmasq is used only on the host machine, not inside the containers. This should look something like the following excerpt.

    ```

    ```yaml
    version: "3.5"
    services:
      php-fpm:
       extra_hosts:
         - alternate1.test:${TRAEFIK_ADDRESS:-0.0.0.0}
         - sub1.alternate1.test:${TRAEFIK_ADDRESS:-0.0.0.0}
         - sub2.alternate1.test:${TRAEFIK_ADDRESS:-0.0.0.0}
         - alternate2.test:${TRAEFIK_ADDRESS:-0.0.0.0}
         - sub1.alternate2.test:${TRAEFIK_ADDRESS:-0.0.0.0}
         - sub2.alternate2.test:${TRAEFIK_ADDRESS:-0.0.0.0}

      php-debug:
       extra_hosts:
         - alternate1.test:${TRAEFIK_ADDRESS:-0.0.0.0}
         - sub1.alternate1.test:${TRAEFIK_ADDRESS:-0.0.0.0}
         - sub2.alternate1.test:${TRAEFIK_ADDRESS:-0.0.0.0}
         - alternate2.test:${TRAEFIK_ADDRESS:-0.0.0.0}
         - sub1.alternate2.test:${TRAEFIK_ADDRESS:-0.0.0.0}
         - sub2.alternate2.test:${TRAEFIK_ADDRESS:-0.0.0.0}
    ```
### Magento 1 Subfolder setup
If you have a M1 subfolder setup to run your multiple stores, you will have to extend the `nginx` configuration. To do that, add `.warden/warden-env.yml`
file with the following content to your project root:
```
version: "3.5"
services:
  nginx:
    volumes:
      - ./.warden/nginx/custom.conf:/etc/nginx/default.d/custom.conf
``` 
Now you add a file `.warden/nginx/custom.conf` in your project root with the following content:
```
location /subdomain1 {
    alias /var/www/html/;
    try_files $uri $uri/ @subdomain1;

   location ~ \.php$ {
       try_files $uri =404;
       expires off;

       fastcgi_pass $fastcgi_backend;

       fastcgi_buffers 1024 4k;
       fastcgi_buffer_size 128k;
       fastcgi_busy_buffers_size 256k;
       fastcgi_read_timeout 3600s;

       include fastcgi_params;

       fastcgi_param HTTPS on;

       # Prevents these headers being used to exploit Zend_Controller_Request_Http
       fastcgi_param HTTP_X_REWRITE_URL "";
       fastcgi_param HTTP_X_ORIGINAL_URL "";

       fastcgi_param MAGE_RUN_CODE {{STORE_CODE_OF_YOUR_SUBDOMAIN1_STORE}};

       fastcgi_param SCRIPT_FILENAME  $realpath_root$fastcgi_script_name;
       fastcgi_param DOCUMENT_ROOT    $realpath_root;
       fastcgi_param SERVER_PORT      $http_x_forwarded_port;
   }

}

location @subdomain1 {
        rewrite /subdomain1/(.*)$ /subdomain1/index.php?/$1 last;
}

location /subdomain2 {
    alias /var/www/html/;
    try_files $uri $uri/ @subdomain2;

   location ~ \.php$ {
       try_files $uri =404;
       expires off;

       fastcgi_pass $fastcgi_backend;

       fastcgi_buffers 1024 4k;
       fastcgi_buffer_size 128k;
       fastcgi_busy_buffers_size 256k;
       fastcgi_read_timeout 3600s;

       include fastcgi_params;

       fastcgi_param HTTPS on;

       # Prevents these headers being used to exploit Zend_Controller_Request_Http
       fastcgi_param HTTP_X_REWRITE_URL "";
       fastcgi_param HTTP_X_ORIGINAL_URL "";

       fastcgi_param MAGE_RUN_CODE {{STORE_CODE_OF_YOUR_SUBDOMAIN2_STORE}};

       fastcgi_param SCRIPT_FILENAME  $realpath_root$fastcgi_script_name;
       fastcgi_param DOCUMENT_ROOT    $realpath_root;
       fastcgi_param SERVER_PORT      $http_x_forwarded_port;
   }

}

location @subdomain2 {
        rewrite /subdomain2/(.*)$ /subdomain2/index.php?/$1 last;
}
``` 
Insert the correct store codes instead of the placeholders to set the proper `MAGE_RUN_CODE`.
This way the correct store code is set depending on your subdomain and your shop works similar to your live setup.

### Magento 2 Run Params

When multiple domains are being used to load different stores or websites on Magento 2, the following configuration should be defined in order to set run codes and types as needed.

1. Add a file at `app/etc/stores.php` with the following contents:

    ```php
    <?php

    use \Magento\Store\Model\StoreManager;
    $serverName = isset($_SERVER['HTTP_HOST']) ? $_SERVER['HTTP_HOST'] : null;

    switch ($serverName) {
        case 'domain1.exampleproject.test':
            $runCode = 'examplecode1';
            $runType = 'website';
            break;
        case 'domain2.exampleproject.test':
            $runCode = 'examplecode2';
            $runType = 'website';
            break;
        default:
            return;
    }

    if ((!isset($_SERVER[StoreManager::PARAM_RUN_TYPE])
            || !$_SERVER[StoreManager::PARAM_RUN_TYPE])
        && (!isset($_SERVER[StoreManager::PARAM_RUN_CODE])
            || !$_SERVER[StoreManager::PARAM_RUN_CODE])
    ) {
        $_SERVER[StoreManager::PARAM_RUN_CODE] = $runCode;
        $_SERVER[StoreManager::PARAM_RUN_TYPE] = $runType;
    }
    ```

    ``` note::
        The above example will not alter production site behavior given the default is to return should the ``HTTP_HOST`` value not match one of the defined ``case`` statements. This is desired as some hosting environments define run codes and types in an Nginx mapping. One may add production host names to the switch block should it be desired to use the same site switching mechanism across all environments.
    ```

2. Then in `composer.json` add the file created in the previous step to the list of files which are automatically loaded by composer on each web request:

    ```json
    {
        "autoload": {
            "files": [
                "app/etc/stores.php"
            ]
        }
    }
    ```

    ``` note::
        This is similar to using `magento-vars.php` on Magento Commerce Cloud, but using composer to load the file rather than relying on Commerce Cloud magic: https://devdocs.magento.com/guides/v2.3/cloud/project/project-multi-sites.html
    ```

3. After editing the `composer.json` regenerate the auto load configuration:

    ```bash
    composer dump-autoload
    ```
