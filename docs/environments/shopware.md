## Installing Shopware 6

The below example demonstrates the from-scratch setup of the Shopware 6 application for local development. A similar process can easily be used to configure an environment of any other type. This assumes that Warden has been previously started via `warden svc up` as part of the installation procedure.

1.  Create a new directory on your host machine at the location of your choice and then jump into the new directory to get started:

        mkdir -p ~/Sites/exampleproject
        cd ~/Sites/exampleproject

2.  From the root of your new project directory, run `env-init` to create the `.env` file with configuration needed for Warden and Docker to work with the project.

        warden env-init exampleproject shopware

    The result of this command is a `.env` file in the project root (tip: commit this to your VCS to share the configuration with other team members) having the following contents:

        WARDEN_ENV_NAME=exampleproject
        WARDEN_ENV_TYPE=shopware
        WARDEN_WEB_ROOT=/

        TRAEFIK_DOMAIN=exampleproject.test
        TRAEFIK_SUBDOMAIN=app

        WARDEN_DB=1
        WARDEN_REDIS=1
        WARDEN_RABBITMQ=0
        WARDEN_ELASTICSEARCH=0
        WARDEN_VARNISH=0

        MYSQL_DISTRIBUTION=mariadb
        MYSQL_DISTRIBUTION_VERSION=10.4
        NODE_VERSION=12
        COMPOSER_VERSION=2
        PHP_VERSION=7.4
        PHP_XDEBUG_3=1
        RABBITMQ_VERSION=3.8
        REDIS_VERSION=5.0
        VARNISH_VERSION=6.0

3.  Sign an SSL certificate for use with the project (the input here should match the value of `TRAEFIK_DOMAIN` in the above `.env` example file):

        warden sign-certificate exampleproject.test

4.  Configure the project to use `./webroot` so the Shopware installer won't overwrite Warden's `.env` file

        perl -pi -e 's#^WARDEN_WEB_ROOT.*#WARDEN_WEB_ROOT=/webroot#' .env

5.  Clone the Shopware development template

        git clone git@github.com:shopware/development.git ./webroot

6.  Next you'll want to start the project environment:

        warden env up

    ```warning::
        If you encounter an error about ``Mounts denied``, follow the instructions in the error message and run ``warden env up`` again.
    ```

7.  Drop into a shell within the project environment. Commands following this step in the setup procedure will be run from within the `php-fpm` docker container this launches you into:

        warden shell

8.  Configure the `APP_URL` Shopware will use during installation:

        echo $'const:\n  APP_URL: "https://app.exampleproject.test"\n' > .psh.yaml.override

9.  Install the Shopware application complete with sample data:

        ./psh.phar install

10. Launch the application in your browser:

    - [https://app.exampleproject.test/](https://app.exampleproject.test/)
    - [https://app.exampleproject.test/admin/](https://app.exampleproject.test/admin/)

```note::
    The default username for Shopware 6 is ``admin`` with password ``shopware``.
```

```note::
    To completely destroy the ``exampleproject`` environment we just created, run ``warden env down -v`` to tear down the project's Docker containers, volumes, etc.
```
