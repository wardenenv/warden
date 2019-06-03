# Warden
Warden is a CLI utility for working with docker-compose environments, and enables multiple local developer environments to run simultaneously without port conflicts via the use of a few centrally run services for proxying into each environment's containers.

## Prerequisites

* [Homebrew](https://brew.sh) package manager (for installing Warden)
* [Docker for Mac](https://hub.docker.com/editions/community/docker-ce-desktop-mac) or [Docker for Linux](https://docs.docker.com/install/linux/docker-ce/fedora/)
* `docker-compose` available in your `$PATH` (included in Docker for Mac, can be installed via brew on Linux hosts)

## Installing Warden

    brew install davidalger/warden/warden
    warden up

## Features

* Traefik for SSL termination and routing/proxying requests into the correct containers.
* Portainer for quick visibility into what's running inside the local Docker host.
* Dnsmasq to serve DNS responses for .test domains eliminating manual editing of `/etc/hosts`
* An SSH tunnel for connecting from SequelPro or TablePlus into any one of multiple running database containers.
* Warden wildcard SSl certificate signing for running https on all local development domains.

## License

This work is licensed under the MIT license. See LICENSE file for details.

## Author Information

This project was started in 2019 by [David Alger](https://davidalger.com/).
