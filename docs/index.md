Welcome to Warden's documentation!
==================================

``` toctree::
    :maxdepth: 1
    :caption: Table of Contents

    installing
    environments
    usage
    configuration
```

Warden is a CLI utility for orchestrating Docker developer environments, and enables multiple local environments to run simultaneously without port conflicts via the use of a few centrally run services for proxying requests into the correct environment's containers. Under the hood, `docker-compose` is used to to control everything which Warden runs (shared services as well as per-project containers) on Docker Engine.

## Features

* Traefik for SSL termination and routing/proxying requests into the correct containers.
* Portainer for quick visibility into what's running inside the local Docker host.
* Dnsmasq to serve DNS responses for `.test` domains eliminating manual editing of `/etc/hosts`
* An SSH tunnel for connecting from Sequel Pro or TablePlus into any one of multiple running database containers.
* Warden issued wildcard SSL certificates for running https on all local development domains.
* Full support for both Magento 1, Magento 2, and custom per-project environment configurations on macOS and Linux.
* Ability to override, extend, or setup completely custom environment definitions on a per-project basis.

### Global Services

After running `warden up` for the first time following installation, the following URLs can be used to interact with the UIs for services Warden runs globally:

* https://traefik.warden.test/
* https://portainer.warden.test/
* https://dnsmasq.warden.test/

### Docker Images

The custom base images used by Warden environments can be found on [Docker Hub](https://hub.docker.com/r/davidalger/warden) or on Github: https://github.com/davidalger/docker-images-warden

In addition to these custom base images, Warden also utilizes official images such as `redis`, `rabbitmq` and `mailhog` for example.
