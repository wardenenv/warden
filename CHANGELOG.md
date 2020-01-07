## UNRELEASED-0.2.0 (yyyy-mm-dd)
[All Commits](https://github.com/davidalger/warden/compare/0.1.12..develop)

**Enhancements:**
* Updated Traefik container and configuration to deploy Traefik 2.1; this is a **breaking change** as Traefik v2 overhauled the labeling used to auto-configure routing on containers. All labeling on built-in environment configurations has been updated, but where labels are used to configure Traefik in per-project configuration files such as in `.warden/warden-env.yml` the project may require a coordinated update to labeling for continued interoperability of the customizations with Warden 0.2.0+
* Added native support for multi-domain projects without requiring per-project routing configuration. This is accomplished using wildcard rules in the new Traefik labeling configuration allowing Warden to automatically route any sub-domain of the `TRAEFIK_DOMAIN` value in `.env` to the nginx and/or varnish container for handling by the application.
* Added labels to `fpm` containers in `magento2` environment to support use of Live Reload via an injected JS snippet in the site header or footer (issue [#62](https://github.com/davidalger/warden/issues/62))
* Updated Mutagen usage to rely on new commands and configuration in Mutagen 0.10.0 (Warden will now throw an error if you attempt to start a sync and have a version of Mutagen older than 0.10.0 installed)
* Added `WARDEN_ENV_NAME` as prefix to each container hostname in compose configs (issue [#29](https://github.com/davidalger/warden/issues/29))
* Added `BYPASS_VARNISH` flag which when set in project `.env` file will cause Traefik to route requests directly to `nginx` container rather than `varnish` (issue [#63](https://github.com/davidalger/warden/issues/63))
* Updated configuration setup for SSH tunnel container so it will automatically re-instate the needed configuration (if missing) when running `up`, `start`, or `restart` to mitigate issue caused by macOS Catalina updates wiping out customizations to `/etc/ssh/ssh_config` (issue [#59](https://github.com/davidalger/warden/issues/59))
* Added `laravel` environment type to support local development of Laravel based applications (issue [#60](https://github.com/davidalger/warden/issues/60))
* Updated `env-init` command to include default values for available variables in the project's `.env` making customization a bit easier (issue [#32](https://github.com/davidalger/warden/issues/32))
* Updated default Elasticsearch version for `magento2` environments from 5.4 to 6.8 (issue [#66](https://github.com/davidalger/warden/issues/66))

**Bug fixes:**
* Fixed broken incorrect Blackfire environment template name for magento1 env type (issue [#48](https://github.com/davidalger/warden/issues/48))

## [0.1.12](https://github.com/davidalger/warden/tree/0.1.12) (2019-12-10)
[All Commits](https://github.com/davidalger/warden/compare/0.1.11..0.1.12)

**Bug fixes:**
* Fixed issue breaking SSH tunnel as used for port-forwards.

## [0.1.11](https://github.com/davidalger/warden/tree/0.1.11) (2019-11-26)
[All Commits](https://github.com/davidalger/warden/compare/0.1.10..0.1.11)

**Enhancements:**
* Added option to enable and setup Selenium for use with MFTF via flag in project's `.env` file ([#40](https://github.com/davidalger/warden/pull/40) by [lbajsarowicz](https://github.com/lbajsarowicz))
* Added error message to `warden install` when `docker-compose` version in `$PATH` is incompatible ([#41](https://github.com/davidalger/warden/pull/41) by [lbajsarowicz](https://github.com/lbajsarowicz))

0.1.10
===============

* Added native support to Warden for using the [split-database system](https://devdocs.magento.com/guides/v2.3/config-guide/multi-master/multi-master.html) in Magento Commerce during local development ([#5](https://github.com/davidalger/warden/pull/5) by [navarr](https://github.com/navarr))
* Added support for optional Blackfire profiling which can be enabled via settings in the project's `.env` file ([#12](https://github.com/davidalger/warden/pull/12) by [navarr](https://github.com/navarr))

0.1.9
===============

* Pinned image for Traefik to use `traefik:v1.7` imgae vs `traefik:latest` to resolve issues caused by Traefik 2.0 having breaking changes in the configuration API

0.1.8
===============

* Introduced `NODE_VERSION` environment variable to specify which version of NodeJS to install in FPM images during container startup (by default v10 is now pre-installed in `mage1-fpm` and `mage2-fpm` images at the time of this release; latest images must be pulled from Docker Hub for this to work).
* Fixed issue where if sub-directory included a relative symlink pointing `.env` at parent project's `.env` file, `--project-dir` passed to `docker-compose` could be specified incorrectly when running warden from within the given sub-directory.

0.1.7
===============

* All published ports now listen on `127.0.0.1` by default as opposed to `0.0.0.0` for a local environment that is fully inaccessible to the outside world apart from using a proxy (such as [Charles](https://www.charlesproxy.com/)).

0.1.6
===============

* Changed the default value `env-init` uses for `TRAEFIK_SUBDOMAIN` to `app` (previously it would match the environment type)
* Added mount of `~/.warden/ssl/rootca/certs:/etc/ssl/warden-rootca-cert:ro` to each env type's `php-fpm` and `php-debug` containers to support FPM images appending this CA root to the trusted ca-bundle on container start
* Added `extra_hosts` entry to set an entry in `/etc/hosts` within `php-fpm` and `php-debug` containers pointing the project's primary domain to the Traefik service IP address so `curl` and `SoapClient` (for example) may work inside a project's FPM services
* Added FPM containers to the "warden" network so they'll be able to route http requests to Traefik

0.1.5
===============

* Changed Mutagen polling interval from 20 to 10 seconds
* Removed `generated` directory from exclusions in Mutagen sync configuration (having this ignored breaks ability to step into generated class files during Xdebug sessions)
* Fixed issue with Mutagen sync cofiguration causing `pub/static` (and other files) to have incorrect permissions resulting in 404'ing static resources
* Fixed issue causing `warden env` to break when run from a path which contained a space (issue [#3](https://github.com/davidalger/warden/issues/3))

0.1.4
===============

* Removed exclusion of 'node_modules' from Mutagen sync for Magento 2 to avoid breaking Dotdigitalgroup_Email module in vendor directory (this module includes a node_modules dir pre-installed).

0.1.3
===============

* Added ability on linux to prevent warden from touching dns configuration when `~/.warden/nodnsconfig` is present.
* Updated install routine to properly trust CA root on Ubuntu (previously warden install would simply fail)
* Updated DNS auto-configuration on linux systems to handle systemd-resolved usage.
* Fixed issue on Ubuntu where dnsmasq container would fail to bind to port 53.
* Fixed issue where lack of `~/.composer` dir (resulting in creation by docker) can cause permissions error inside containers.
* Fixed issue with `bin/magento setup:install` allowing it to pass permissions checks ([#2](https://github.com/davidalger/warden/pull/2) by [fooman](https://github.com/fooman))
* Fixed issue where `env` and `env-init` commands failed to reset shell colors when printing error messages (issue [#4](https://github.com/davidalger/warden/issues/4))

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
* Fixed bug where resolver setup on macOS would fail if `/etc/resolver` dir was already present during install ([#1](https://github.com/davidalger/warden/pull/1) by [fooman](https://github.com/fooman))

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
