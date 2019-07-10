0.1.3
===============

* Added ability on linux to prevent warden from touching dns configuration when `~/.warden/nodnsconfig` is present.
* Updated install routine to properly trust CA root on Ubuntu (previously warden install would simply fail)
* Updated DNS auto-configuration on linux systems to handle systemd-resolved usage.
* Fixed issue on Ubuntu where dnsmasq container would fail to bind to port 53.
* Fixed issue where lack of `~/.composer` dir (resulting in creation by docker) can cause permissions error inside containers.
* Fixed issue with `bin/magento setup:install` allowing it to pass permissions checks (PR #2 by @fooman)

0.1.2
===============

* Added `warden shell` command for easily dropping into the `php-fpm` container (container name is configurable for supporting "local" environment types)
* Added `max_allowed_packet=1024M` to `db` containers for M1 and M2 environments to avoid imports or upgrade routines from failing on large packets.
* Changed `php-fpm` and `php-debug` to use custom images based on `centos:7` as opposed to the `alpine3.9` based official php-fpm images to avoid seg-faults when Source Guardian loader is installed alongside Xdebug.
* Fixed issue with DEFINER stripping in `db import` allowing it to correctly strip from both TRIGGERS and ALGORITHM clauses.

0.1.1
===============

* Fixed bug where 'db' commands broke due to template overhaul in 0.1.0 release.

0.1.0
===============

* Changed the env type setup to automatically include additional configuration based on $OSTYPE.
* Changed the environment template structure to utilize per-OSTYPE docker-compose config additions where environments differ from one host OS to another (such as `magento2` env type, which uses plain mounts on `linux-gnu` but sync sessions on `darwin`)
* Fixed a few error messages so they won't change shell text color permanently when they output.
* Fixed sync command to output error message when any sub-command is run on an env lacking a mutagen configuration.

0.1.0-beta7
===============

* Added Xdebug support via additional `php-debug` container which Nginx routes to based on presence of `XDEBUG_SESSION` cookie.
* Fixed Elasticsearch images used in Magento 2 environment templates and configured for lower overall memory utilization upon container start for a smaller env footprint.

0.1.0-beta6
===============

* Added support for extending environment configuration on a per-project basis via `.warden/warden-env.yml` and `.warden/warden-env.<WARDEN_ENV_TYPE>.yml` files
* Added `local` env type to support projects which do not conform to any of the templated environments suppoprted out-of-the-box
* Changed Traefik configuration to automatically use the warden docker network (eliminates need for `traefik.docker.network=warden` label on all proxied containers
* Changed Traefik configuration to require containers be explicitly enabled for Traefik via the label `traefik.enable=true`
* Changed docker-compose environment type templates to version 3.5 for better extendability in project override files
* Fixed bug where resolver setup on macOS would fail if `/etc/resolver` dir was already present during install (PR #1 by @fooman)

0.1.0-beta5
===============

* Fixed issue with docker-compose exit codes would result in error messages from global trap
* Added auto-install of mutagen where not already present when any sync command is run
* Added support for WARDEN_WEB_ROOT env setting to publish a sub-dir into /var/www/html
* Changed images for php-fpm to use environment type specfic images from davidalger/warden repository

0.1.0-beta4
===============

* Added "env" command for controlling docker based per-project environments (currently this simply passes all commands and arguments through to docker-compose).
* Added "env-init" to add `.env` file with Warden configuration to the current working directory.
* Added "sync" command with start/stop/list sub-commands for controlling per-project mutagen sessions.
* Added "db" command for connecting to mysql and importing databases into the db service.
* Added three environment types: `magento1`, `magento2-mutagen`, `magento2-native` with auto-selecting the correct M2 environment on Linux/macOS.
* Fixed dnsmasq setup on Linux (nameserver is now configured on Linux when NetworkManager service is active during install; tested on Fedora 29)

0.1.0-beta3
===============

* Fixed infinite loop on initial setup routine.

0.1.0-beta2
===============

* Updated assertion to automatically execute "warden install" if installed metadata indicator is older than bin/warden.
* Fixed issue on Linux hosts where ssh_key.pub was unusable inside tunnel container due to bad permissions.

0.1.0-beta1
===============

* Initial beta release.
