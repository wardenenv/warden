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
