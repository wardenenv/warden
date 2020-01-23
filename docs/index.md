Welcome to Warden's documentation!
==================================

Warden is a CLI utility for orchestrating Docker based developer environments, and enables multiple local environments to run simultaneously without port conflicts via the use of a few centrally run services for proxying requests into the correct environment's containers.

Under the hood, `docker-compose` is used to to control everything which Warden runs (shared services as well as per-project containers) via the Docker Engine.

``` toctree::
    :maxdepth: 2
    :caption: Table of Contents
    :glob:

    features
    installing
    services
    usage
    environments
    *
```
