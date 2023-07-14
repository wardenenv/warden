# Change Log

## UNRELEASED [x.y.z](https://github.com/davidalger/warden/tree/x.y.z) (yyyy-mm-dd)
[All Commits](https://github.com/davidalger/warden/compare/0.14.1..main)

**Enhancements:**
* Project and Local Warden commands will now take precedence over built-in warden commands ([#676](https://github.com/wardenenv/warden/pull/676) by @flpandre)

## Version [0.14.1](https://github.com/wardenenv/warden/tree/0.14.1) (2023-07-10)
[All Commits](https://github.com/wardenenv/warden/compoare/0.14.0..0.14.1)

**Enhancements:**
* `warden status` command added that shows running Warden environments ([#669](https://github.com/wardenenv/warden/pull/669) by @bap14)

**Bug Fixes:**
* Updated Mutagen connection detection so that Mutagen doesn't resync every time in versions >= 0.15.0

## Version [0.14.0](https://github.com/wardenenv/warden/tree/0.14.0) (2023-06-19)
[All Commits](https://github.com/wardenenv/warden/compare/0.13.1..0.14.0)

**Dependency Changes:**
* All commands now use the Docker Compose plugin (`docker compose`) instead of the standalone command (`docker-compose`)  
  Please be aware that this will change your container names from using underscores to using dashes (e.g. vanilla_db_1 becomes vanilla-db-1).  This is configured through the environment variable `DOCKER_COMPOSE_COMMAND` which defaults to `docker compose`.

**Enhancements**
* ElasticSearch 8.7 and 8.8 images are available
* Drupal environment type added ([#646](https://github.com/wardenenv/warden/pull/646) by @bap14)

## Version [0.13.1](https://github.com/wardenenv/warden/tree/0.13.1) (2023-03-21)
[All Commits](https://github.com/wardenenv/warden/compare/0.13.0..0.13.1)

**Bug Fixes:**
* Removed changelog item about Backup and Restore commands that were reverted
* Incremented version from 0.12.0 to 0.13.1

## Version [0.13.0](https://github.com/wardenenv/warden/tree/0.13.0) (2023-03-20)
[All Commits](https://github.com/wardenenv/warden/compare/0.12.0..0.13.0)

**Enhancements:**

* Updated environment default Node version from 10 to 12 ([#425](https://github.com/wardenenv/warden/pull/425) by @davidalger)
* Ignore the only root .git directory ([#496](https://github.com/wardenenv/warden/pull/496) by @ihor-sviziev)
* Allow dnsmasq service to be disabled ([#462](https://github.com/wardenenv/warden/pull/462) by by @davidhiendl)
* Update Magento2 defaults to 2.4.6 ([#618](https://github.com/wardenenv/warden/pull/618) by by @lalittmohan)
* The ability to specify `MYSQL_DISTRIBUTION=(mysql|mariadb)` and `MYSQL_DISTRIBUTION_VERSION` ([dd5ff](https://github.com/wardenenv/warden/commit/dd5ffddf4764d43c70387435c7c75035615661f0) by @rootindex)
* Add `WARDEN_OPENSEARCH=1` and `OPENSEARCH_VERSION` ([2bd95](https://github.com/wardenenv/warden/commit/2bd95457748c1d639dc6109018d963ff624137ac) by @navarr)
* Migration from Selenium to Seleniarm ([471dc](https://github.com/wardenenv/warden/commit/471dc0411771e21448dd4aa9eba8e8fdc7abdfdb) by @navarr)
* Scoped environment config loading ([#451](https://github.com/wardenenv/warden/pull/451) by @tdgroot)
* Portainer made optional and off by default ([03783](https://github.com/wardenenv/warden/commit/03783b65cfdd644133e75468808a93e751922077) by @bap14)
* Persist MySQL command history ([45a16](https://github.com/wardenenv/warden/commit/45a16f064680dec0e7cb3fe4906090359bd3dfd5) by @navarr)

**Bug Fixes:**
* Update default URL for ElasticsearchHQ by @ihor-sviziev in [wardenenv/warden#428](https://github.com/wardenenv/warden/pull/428)
* Corrected syntax of env-init.help command by @davidalger in [wardenenv/warden#490](https://github.com/wardenenv/warden/pull/490)
* Add `traefik.docker.network` label to specify docker network exclusively by @tdgroot in [wardenenv/warden#458](https://github.com/wardenenv/warden/pull/458)
* Require docker compose 2.2.3 when compose v2 is active by @davidalger in [wardenenv/warden#489](https://github.com/wardenenv/warden/pull/489)

## Version [0.12.0](https://github.com/davidalger/warden/tree/0.12.0) (2021-08-28)
[All Commits](https://github.com/davidalger/warden/compare/0.11.0..0.12.0)

**Enhancements:**

* Added Elastic HQ support available at elastichq.mydomain.test for viewing Elasticsearch data ([#350](https://github.com/davidalger/warden/pull/350) by @Den4ik)
* Update selenium to standalone latest version resolving issues with old hub/chrome image combinations ([#349](https://github.com/davidalger/warden/pull/349) by @Den4ik)
* Environment and image build improvements ([#363](https://github.com/davidalger/warden/pull/363) by @Den4ik)
* Introduces new redis sub-command for easy access to the running redis container ([#413](https://github.com/davidalger/warden/pull/413) by @werfu)
* SSH known hosts will now be persisted via an additional `sshdirectory:/home/www-data/.ssh` volume on php-fpm containers ([#315](https://github.com/davidalger/warden/pull/315) by @ihor-sviziev)
* Docker images for Nginx 1.18 are now available ([#414](https://github.com/davidalger/warden/pull/414) by @darrakurt)

**Bug Fixes:**

* Fixed loadEnvConfig inability to parse .env with CRLF line endings (issue [#380](https://github.com/davidalger/warden/issues/380))

## Version [0.11.0](https://github.com/davidalger/warden/tree/0.11.0) (2021-04-22)
[All Commits](https://github.com/davidalger/warden/compare/0.10.2..0.11.0)

**Upgrade Notes:**

PHP and Varnish images have been rebuilt on a CentOS 8 base image (previously used a CentOS 7 base image). This eliminates the need for IUS for installing Git and MariaDB clients as these can now be installed from the default EL RPMs. This also allows for constants supported by more recent versions of Curl to be used in PHP code, latest calendar / locale features available in newer versions of ICU libraries to be used, etc.

Please note that builds for PHP versions 5.5, 5.6, 7.0 and 7.1 have been dropped. Images will remain on Docker Hub so they'll continue to be available for existing projects actively using them, they simply will see no further enhancements or maintenance.

To ensure you have the latest re-builds of Warden images and update your projects: `warden env pull && warden env up`

For full details on what went into these rebuilds, please see [#345](https://github.com/davidalger/warden/pull/345).

Huge shout out to @tdgroot who helped with updating the builds, testing, etc.

**Enhancements:**

* Shopware and Symfony environments will now use Composer v2 by default (issue [#359](https://github.com/davidalger/warden/issues/359))

## Version [0.10.2](https://github.com/davidalger/warden/tree/0.10.2) (2021-04-03)
[All Commits](https://github.com/davidalger/warden/compare/0.10.1..0.10.2)

**Bug Fixes:**

* Fixed bug where Live Reload might not work when Varnish was disabled due to routing priorities ([#337](https://github.com/davidalger/warden/pull/337) by @alinalexandru)

**Enhancements:**

* Magento 1 and Magento 2 environments now set developer environment variables by default ([#332](https://github.com/davidalger/warden/pull/332) by @norgeindian)
* SSH Agent forwarding will no longer use socat except when needed ([#334](https://github.com/davidalger/warden/pull/334) by @alinalexandru)

## Version [0.10.1](https://github.com/davidalger/warden/tree/0.10.1) (2021-03-01)
[All Commits](https://github.com/davidalger/warden/compare/0.10.0..0.10.1)

**Bug Fixes:**

* Fixed a bug where SSH Agent forwarding would break following container restart ([#307](https://github.com/davidalger/warden/pull/307) by @ihor-sviziev)
* Fixed a issue where Xdebug 3 images would generate excessive profile data when running CLI commands in debug container ([#309](https://github.com/davidalger/warden/pull/309) by @Den4ik)

Please note that you must pull the latest `php-fpm` images via `warden env pull` to get these bug fixes relating to configuration in the pre-built images.

**Enhancements:**

* There is now a `warden db dump` command available to run `mysqldump` on the `db` container ([#310](https://github.com/davidalger/warden/pull/310) by @Den4ik)
* Bash history will now be persisted via an additional `bashhistory:/bash_history` volume on php-fpm containers ([#304](https://github.com/davidalger/warden/pull/304) by @Den4ik)

## Version [0.10.0](https://github.com/davidalger/warden/tree/0.10.0) (2021-02-13)
[All Commits](https://github.com/davidalger/warden/compare/0.9.1..0.10.0)

**Upgrade Notes:**

* Various updates to PHP images have occurred since the last major release including a transition to using Remi vs IUS for RPMs. It's highly recommended you re-pull to get the latest images and update your projects: `warden env pull && warden env up`
* Warden now requires `mutagen` 0.11.8 or later for environments leveraging sync sessions on Mac OS. Reference issue [#235](https://github.com/davidalger/warden/issues/235) for details. This is to resolve an incompatibility between earlier versions of Mutagen and Docker Desktop 2.3.0.5 and later.
* There is a new docs page on [DNS resolver configuration](https://docs.warden.dev/configuration/dns-resolver.html) thanks to @Skullsneeze
* The docs page on Installing Warden includes a new section titled [Trusted CA Root Certificate](https://docs.warden.dev/installing.html#trusted-ca-root-certificate) with additional post-install information largely relevant to Linux users.
* Images for Varnish 6.4 and 6.5 are now available in addition to 6.0 LTS and 4.1 to support users who desire to remain closer to the bleeding edge.
* Redis 6 and Elasticsearch 7.11 images have recently been made available.
* When updating to Composer v2 using the new `COMPOSER_VERSION=2` setting, make sure you remove `hirak/prestissimo` from global (if present) `composer global remove hirak/prestissimo`
* Warden will no longer attempt to auto-configure DNS resolution for `*.test` on non-Darwin systems due to a combination of security reasons, lack of per-TLD resolver configuration (as is used on Darwin/Mac OS) and the myriad permutations of resolver configuration across various Linux based distros. The dnsmasq container will still be started, but a warning will now be emitted on Linux directing users to the new docs page on [DNS resolver configuration](https://docs.warden.dev/configuration/dns-resolver.html).

**Bug Fixes:**

* The `.idea` directory is no longer ignored from Mutagen sync allowing `bin/magento dev:urn-catalog:generate` to be generate metadata the IDE uses (issue [#291](https://github.com/davidalger/warden/issues/291))
* Installing on WSL will no longer report innocuous errors related to lack of systemd support on WSL as the install routine no longer makes calls to `systemctl` on Linux systems (issue [#220](https://github.com/davidalger/warden/issues/220))

**Enhancements:**

* Added opt-in support for Xdebug 3 (see docs for details; new environments will set `PHP_XDEBUG_3=1`) ([#279](https://github.com/davidalger/warden/pull/279) by @Den4ik)
* Added ability to provide persistent additional configuration to `dnsmasq` service (issue [#214](https://github.com/davidalger/warden/issues/214))
* Added ability to easily specify alternate nameservers for `dnsmasq` to use (issue [#214](https://github.com/davidalger/warden/issues/214))
* Added ability to customize bundled environment compositions by overriding them in the Warden home dir ([#228](https://github.com/davidalger/warden/pull/228) by @k4emic)
* Added ability to override sync configuration on a per-project basis or provide one on env types such as `local` where default one does not exist ([#246](https://github.com/davidalger/warden/pull/246) by @Den4ik)
* Updated version of Portainer from 1.24.X to 2.0.X ([#245](https://github.com/davidalger/warden/pull/245) by @MarcoFaul)
* Added support for `COMPOSER_VERSION` in `.env` to configure `composer` to run the newer Composer v2. At this time the default remains Composer v1 for compatibility reasons (issue [#296](https://github.com/davidalger/warden/issues/296))
* Added modman support for `magento1` environment type ([#290](https://github.com/davidalger/warden/pull/290) by @norgeindian)

## Version [0.9.1](https://github.com/davidalger/warden/tree/0.9.1) (2020-08-25)
[All Commits](https://github.com/davidalger/warden/compare/0.9.0..0.9.1)

**Bug Fixes:**

* Fixed bug on WSL2 where Xdebug connect back host was improperly set ([#213](https://github.com/davidalger/warden/pull/213) by @ihor-sviziev)

## Version [0.9.0](https://github.com/davidalger/warden/tree/0.9.0) (2020-08-06)
[All Commits](https://github.com/davidalger/warden/compare/0.8.2..0.9.0)

**Upgrade Notes:**

* Removed deprecated first-class commands `warden start`, `warden stop`, `warden up`, `warden down`, and `warden restart`; please use `warden svc <verb>` to manage global services such as Traefik, Portainer, Mailhog, etc ([#205](https://github.com/davidalger/warden/pull/205) by @davidalger)

**Enhancements:**

* Added a new `wordpress` environment type pre-configured for running the Wordpress application ([#206](https://github.com/davidalger/warden/pull/206) by @jamescowie)

## Version [0.8.2](https://github.com/davidalger/warden/tree/0.8.2) (2020-08-03)
[All Commits](https://github.com/davidalger/warden/compare/0.8.1..0.8.2)

**Enhancements:**

* Changed all `:delegated` mounts to `:cached` mounts to preserve existing behavior of mounts when new behavior in Docker Desktop Edge 2.3.2.0 is promoted to stable channel ([#204](https://github.com/davidalger/warden/pull/204) by @davidalger)

## Version [0.8.1](https://github.com/davidalger/warden/tree/0.8.1) (2020-07-30)
[All Commits](https://github.com/davidalger/warden/compare/0.8.0..0.8.1)

**Enhancements:**

* Updated default version of PHP for new `magento2` environments to PHP 7.4
* Updated default version of Elasticsearch for new `magento2` environments to Elasticsearch 7.6
* Updated default version of Elasticsearch where unspecified in project's `.env` file to Elasticsearch 7.8
* Dropped Elasticsearch image builds for versions prior to 6.8 and versions 7.0 through 7.5

**Bug Fixes:**

* Fixed issue where nginx would unexpectedly exit on Linux due to incorrect default value for `XDEBUG_CONNECT_BACK_HOST` in base nginx configuration (issue [#200](https://github.com/davidalger/warden/issues/200))

## Version [0.8.0](https://github.com/davidalger/warden/tree/0.8.0) (2020-07-27)
[All Commits](https://github.com/davidalger/warden/compare/0.7.0..0.8.0)

**Upgrade Notes:**

* To ensure Traefik 2.2 version update takes effect, run `warden svc up` after updating.
* Pre-existing projects may need to be re-created to avoid warnings from docker-compose regarding unused named volumes.
* The `BYPASS_VARNISH` flag (deprecated in 0.5.0) has been removed. Use toggle `WARDEN_VARNISH=0` to disable Varnish.
* Recently updated `php-fpm` images now include the `crontabs` package with `crond` running in the background. Be sure you have the latest images by running `warden env pull` in the project directory followed by `warden env up` to use this functionality. To configure a crontab that is persistent, a crontab file may be mounted at `/var/spool/cron/www-data` (std crontab path) via custom configuration in the project's `.warden/warden-env.yml` file.

**Enhancements:**

* Added `warden vnc` command to launch VNC tunnel via SSH or (when installed) launch Remmina ([#116](https://github.com/davidalger/warden/pull/116) by @lbajsarowicz)
* Updated `warden env`, `warden svc` and `warden db` to print help text when called without any parameters specified
* Updated volume declarations for RabbitMQ and Redis services to use named volumes (avoid use of anonymous volumes)
* Updated version of Traefik from 2.1 to 2.2
* Updated `warden debug` to also pass `host.docker.internal` into the `php-debug` container for the `XDEBUG_REMOTE_HOST` value on WSL when Microsoft is present in `/proc/sys/kernel/osrelease` ([#196](https://github.com/davidalger/warden/pull/196) by @LeeSaferite)
* Updated nginx configuration to pass `XDEBUG_CONNECT_BACK_HOST` as environment variable in base config allowing it to be overridden by exported env variable on all host OS envs ([#199](https://github.com/davidalger/warden/pull/199) by @LeeSaferite)

## Version [0.7.0](https://github.com/davidalger/warden/tree/0.7.0) (2020-07-22)
[All Commits](https://github.com/davidalger/warden/compare/0.6.0..0.7.0)

**Upgrade Notes:**

* With `mailhog` being changed from running on a per-project basis to running as a global service (see issue [#175](https://github.com/davidalger/warden/issues/175)) you will need to ensure `warden svc up` has been run after updating Warden. On pre-existing projects that already had their own Mailhog container running, `warden env up --remove-orphans` will clean it up.

**Enhancements:**

* Added `warden blackfire` command for easily running profiles via the CLI tool ([#188](https://github.com/davidalger/warden/pull/188) by @navarr)
* Changed `mailhog` service to run as a single global service rather than as a per-project service (issue [#175](https://github.com/davidalger/warden/issues/175))
* Updated `warden db import` to strip usages of `@@GLOBAL.GITD_PURGED` and `@@SESSION.SQL_LOG_BIN` from database dumps during import process to avoid failures importing databases originating from Amazon RDS (issue [#162](https://github.com/davidalger/warden/issues/162))
* Added Mutagen sync configuration for `magento1` environment type (issue [#97](https://github.com/davidalger/warden/issues/97))

## Version [0.6.0](https://github.com/davidalger/warden/tree/0.6.0) (2020-07-02)
[All Commits](https://github.com/davidalger/warden/compare/0.5.3..0.6.0)

**Upgrade Notes:**

* Warden now requires `docker-compose` 1.25.0 or later; see [issue #165](https://github.com/davidalger/warden/issues/165)
* Warden now requires `mutagen` 0.11.4 or later for environments leveraging sync sessions on Mac OS (currently Magento 2 and Shopware 6 use Mutagen).

**Enhancements:**

* Added `warden svc` command to control global services replacing `warden start`, `warden stop`, `warden up`, `warden down`, and `warden restart` and offering further flexibility as this works similar to `warden env` in that any verb known to `docker-compose` may be used in orchestrating global services such as `traefik`, `dnsmasq` and `portainer`; for example, `warden svc up` does what `warden up` did previously.
* Updated `warden env` to report an error if Docker does not appear to be running.
* Updated `warden env up` to imply `-d` (`--detach`) to work in like manner to `warden svc up` (formerly `warden up`)
* The `warden sync` command now allows use of mutagen sub-commands `flush` and `reset`
* The following version defaults were updated (these defaults apply when versions remain unspecified in a project's `.env` file; new project `.env` files may differ by environment type)
  * PHP-FPM default updated from 7.3 to 7.4
  * Elasticsearch default updated from 6.8 to 7.7
  * RabbitMQ default updated from 3.7 to 3.8
  * MariaDB default updated from 10.3 to 10.4
* Updated `warden env-init` command to prompt user before overwriting an existing `.env` file in a project directory ([#166](https://github.com/davidalger/warden/pull/166) by @Lunaetic)
* Updated `warden env-init` command to prompt user for required arguments when missing ([#170](https://github.com/davidalger/warden/pull/170) by @Lunaetic)
* Added support for Magepack advanced JS bundling ([#138](https://github.com/davidalger/warden/pull/138) by @vbuck)
* Added a new `shopware` environment type including Mutagen configuration for file sync on macOS (issue [#169](https://github.com/davidalger/warden/issues/169))
* Added support for implementing custom commands in `~/.warden/commands` or `<project>/.warden/commands` ([#172](https://github.com/davidalger/warden/pull/172) by @davidalger)
* Added new feature flag `WARDEN_NGINX` to enable/disable service on per-project basis. This will allow (for example) using a `local` env type for a static site by adding `WARDEN_NGINX=1` to the project's `.env` file.
* Added ability to pass arguments to and override the database name `db connect` and `db import` operate on (issue [#22](https://github.com/davidalger/warden/issues/22))

**Bug Fixes:**

* Fixed issue where specifying `-v` flag would short circuit argument parsing (this flag was removed; previously was only used with `warden sync list` where `warden sync list -l` now accomplishes the same thing by passing the `-l` flag to mutagen to list in detail)
* Fixed bug where quoted arguments like `"foo bar"` would be passed into sub-route as two arguments, `foo` and `bar` (technical detail of argument parsing; no known cases where this caused an issue)
* Fixed incorrect var name in output of `warden env-init` for Laravel env type

**Deprecated Functionality:**

* The `warden start` command has been deprecated and will be removed in the 0.7.0 release; please use `warden svc start` instead.
* The `warden stop` command has been deprecated and will be removed in the 0.7.0 release; please use `warden svc stop` instead.
* The `warden up` command has been deprecated and will be removed in the 0.7.0 release; please use `warden svc up` instead.
* The `warden down` command has been deprecated and will be removed in the 0.7.0 release; please use `warden svc down` instead.
* The `warden restart` command has been deprecated and will be removed in the 0.7.0 release; please use `warden svc restart` instead.

## Version [0.5.3](https://github.com/davidalger/warden/tree/0.5.3) (2020-06-23)
[All Commits](https://github.com/davidalger/warden/compare/0.5.2..0.5.3)

**Bug Fixes:**

* Reverted filtering of GTID SET commands as added in 0.5.2 release to resolve db import errors (issue [#162](https://github.com/davidalger/warden/issues/162))

## Version [0.5.2](https://github.com/davidalger/warden/tree/0.5.2) (2020-06-11)
[All Commits](https://github.com/davidalger/warden/compare/0.5.1..0.5.2)

**Enhancements:**

* Fixed inability to run `warden debug -c '<command>'` in like manner to `warden shell -c ...`
* Fixed issue where GTID related SET statements in a database dump failed the import (issue [#162](https://github.com/davidalger/warden/issues/162))

## Version [0.5.1](https://github.com/davidalger/warden/tree/0.5.1) (2020-05-28)
[All Commits](https://github.com/davidalger/warden/compare/0.5.0..0.5.1)

**Upgrade Notes:**

All docker images have been re-located to a [new Docker Hub organization](https://hub.docker.com/u/wardenenv) created specifically for use with Warden. All built-in environment types having been updated to reference the images on `docker.io/wardenenv` rather than `quay.io/warden`. Images currently on Quay will remain available (for at least the next 90-days) in order to preserve functionality of Warden prior to the 0.5.1 release, but these will no longer be updated and are considered deprecated immediately. Where references to `quay.io/warden` exist in per-project configuration within the `.warden` directory, it is strongly recommended these references be updated to use images from `docker.io/wardenenv`. You can quickly check an environment's configuration for references to images on Quay via the following command:

```
warden env config | grep quay.io
```

The backstory, and reason for moving the images, is that in Warden 0.2.0 (circa January 2020) images were relocated from a single Docker Hub repository to individual repositories on Quay.io both as a means of breaking down a mon-repo and also to leverage images scanning of Quay.io. Since that time, Quay.io has had multiple outages, including a recent one which lasted for 19 hours with intermittent inability to pull images as even read-only operations were failing as the service failed to be scaled. This morning [Quay.io is down yet again](https://github.com/davidalger/warden/issues/157), prompting all-out inability to pull images. Given the saddening instability of Quay.io and the inability to [setup a local mirror as you can with Docker Hub](https://docs.docker.com/registry/recipes/mirror/) it has become painstakingly obvious that the images must be moved back to Docker Hub for a long-term and stable home, with the added benefit that you will now be able to use a local registry service as a pass-through mirror for reducing network bandwidth and/or ensuring you have a copy of all images local to your network should at any time Docker Hub encounter issues in the future.

The new long-term home for Warden docker images can be found here at [https://hub.docker.com/u/wardenenv](https://hub.docker.com/u/wardenenv).

**Change Summary:**

* Updated images to reside in the `docker.io/wardenenv` registry on [Docker Hub](https://hub.docker.com/u/wardenenv)
* Removed usages of images previously on `quay.io/warden`
* Deprecated images on `quay.io/warden` for planned removal at some point in the future (to be not less than 90-days from today)

## Version [0.5.0](https://github.com/davidalger/warden/tree/0.5.0) (2020-05-21)
[All Commits](https://github.com/davidalger/warden/compare/0.4.4..0.5.0)

**Upgrade Notes:**

If `PHP_VERSION` is not defined in a project's `.env` type the default version is now 7.3 across the board for all environment types. This should not pose any issues for recent `magento1` or `magento2` setups, but `laravel` environments will likely require an update to the project's `.env` to continue using PHP 7.2 or rather than 7.3 for local development.

There is a **breaking change** where custom environment config specific to Linux has been used in the form of placing a `.warden/warden-env.linux-gnu.yml` file in the project directory. The value used for `WARDEN_ENV_SUBT` on Linux is now `linux` rather than `linux-gnu`. After upgrading, these files will need to be re-named from `.warden/warden-env.linux-gnu.yml` to `.warden/warden-env.linux.yml`. Where continued compatibility with prior versions of Warden is desired (for example, to not require the entire team to upgrade Warden at once), a symlink may be placed to point the old file name to the new one allowing Warden to load the definition correctly on both new and old implementations: `warden-env.linux-gnu.yml -> warden-env.linux.yml`

The `BYPASS_VARNISH` flag will continue to work as before but has been **deprecated** to be removed in a future release. It will no longer be included in the `.env` file created for new `magento2` environments. Please use the new feature toggle `WARDEN_VARNISH=0` to disable Varnish instead.

**Enhancements:**

* Added `symfony` environment type for use with Symfony 4+ ([#146](https://github.com/davidalger/warden/pull/146) by @lbajsarowicz)
* Added `COMPOSER_MEMORY_LIMIT=-1` to env on all `php-*` containers ([#154](https://github.com/davidalger/warden/pull/154) by @navarr)
* Added new feature flag `WARDEN_DB` to enable/disable service on per-project basis.
* Added new feature flag `WARDEN_ELASTICSEARCH` to enable/disable service on per-project basis.
* Added new feature flag `WARDEN_VARNISH` to enable/disable service on per-project basis.
* Added new feature flag `WARDEN_RABBITMQ` to enable/disable service on per-project basis.
* Added new feature flag `WARDEN_REDIS` to enable/disable service on per-project basis.
* Added new feature flag `WARDEN_MAILHOG` to enable/disable service on per-project basis.
* Updated `WARDEN_ALLURE` to now enable Allure container on any environment type.
* Updated `WARDEN_SELENIUM` to now enable Selenium containers on any environment type.
* Updated `WARDEN_BLACKFIRE` to now enable Blackfire containers on any environment type.
* Updated `env-init` command to include locked values for `MARIADB_VERSION`, `NODE_VERSION`, `PHP_VERSION`, and `REDIS_VERSION` for `laravel` environment types.
* Updated `local` env type so it can now include common services by adding the above feature flags to the project `.env` file.

## Version [0.4.4](https://github.com/davidalger/warden/tree/0.4.4) (2020-05-14)
[All Commits](https://github.com/davidalger/warden/compare/0.4.3..0.4.4)

**Enhancements:**

* Updated `php-fpm` images to use `fpm-loaders` variant of base image to include IonCube & SourceGuardian from upstream images
* Updated `php-fpm` images fix for directory ownership of mounted volume paths for future flexibility by moving it to the `docker-entrypoint` script with an env var `CHOWN_DIR_LIST` to specify what directories to chown on container startup

**Bug Fixes:**

* Fixed missing SSH agent forwarding in `php-blackfire` container
* Fixed lack of `extra_hosts` in `php-blackfire` and `blackfire-agent` containers (issue [#145](https://github.com/davidalger/warden/issues/145))
* Fixed missing `extra_hosts` line for non-subdomain entry in `/etc/hosts` on `selenium` container
* Fixed `$OSTYPE` check for compatibility with OpenSUSE which uses `linux` rather than `linux-gnu` ([#149](https://github.com/davidalger/warden/pull/149) by @Den4ik)

## Version [0.4.3](https://github.com/davidalger/warden/tree/0.4.3) (2020-05-02)
[All Commits](https://github.com/davidalger/warden/compare/0.4.2..0.4.3)

**Enhancements:**

* Updated init routine allowing `WARDEN_HOME_DIR` and `WARDEN_COMPOSER_DIR` to be overridden via environment variables
* Updated environment configuration to reference `WARDEN_SSL_DIR` eliminating hard-coded `~/.warden/ssl` references
* Updated warden global docker config to reference `WARDEN_HOME_DIR` eliminating hard-coded `~/.warden` references
* Updated `warden up` to return an error when docker is not running rather than blindly attempt to start global services

## Version [0.4.2](https://github.com/davidalger/warden/tree/0.4.2) (2020-04-15)
[All Commits](https://github.com/davidalger/warden/compare/0.4.1..0.4.2)

**Enhancements:**

* Added `WARDEN_SYNC_IGNORE` to support passing a comma-separated list of additional [per-session-ignores](https://mutagen.io/documentation/synchronization/ignores#per-session-ignores) to Mutagen when sync sessions are started ([#142](https://github.com/davidalger/warden/pull/142) by @davidalger)
* Added pause, resume and monitor to `warden sync` command ([#141](https://github.com/davidalger/warden/pull/141) by @fooman)
* Changed Mutagen sync to pause on `warden env stop` and resume on `warden env up -d` ([#141](https://github.com/davidalger/warden/pull/141) by @fooman)

**Bug Fixes:**

* Removed exclusion of (commonly large) files types (*.sql, *.gz, *.zip, *.bz2) from sync sessions (as introduced in 0.4.0) because it broke the ability to use artifact repositories with composer ([#142](https://github.com/davidalger/warden/pull/142) by @davidalger)

## Version [0.4.1](https://github.com/davidalger/warden/tree/0.4.1) (2020-04-11)
[All Commits](https://github.com/davidalger/warden/compare/0.4.0..0.4.1)

**Bug Fixes:**

* Removed `tmpfs` volumes from sub-directories of `/var/www/html` when `WARDEN_TEST_DB=1` was set due to compatibility issues ([#139](https://github.com/davidalger/warden/pull/139) by @lbajsarowicz)

## Version [0.4.0](https://github.com/davidalger/warden/tree/0.4.0) (2020-04-02)
[All Commits](https://github.com/davidalger/warden/compare/0.3.1..0.4.0)

**Upgrade Notes:**

The introduction of SSH Agent Forwarding support in [PR #121](https://github.com/davidalger/warden/pull/121) results in Warden now requiring Docker Desktop 2.2.0.0 or later for macOS clients. Please upgrade Docker Desktop prior to upgrading to the latest Warden release to avoid errors relating to unauthorized mounts.

**Enhancements:**

* Added MySQL 5.6 and 5.7 images to Quay repository for use with Warden environments
* Added support for Integration, Unit and API Tests leveraging a `MySQL 5.7` container running on `tempfs` memory disk ([#115](https://github.com/davidalger/warden/pull/115) by @lbajsarowicz)
* Added `WARDEN_ALLURE` setting to control Allure separately from Selenium for use reporting on Integration and Unit tests ([#117](https://github.com/davidalger/warden/pull/117) by @lbajsarowicz)
* Added ssh agent forwarding support on both macOS and Linux hosts ([#121](https://github.com/davidalger/warden/pull/121) by @davidalger)
* Updated entrypoint in php-fpm images to support mounting PEM files into `/etc/pki/ca-trust/source/anchors` ([3a841b7d](https://github.com/davidalger/warden/commit/3a841b7dd80c6827bc8bf238ae8ff53b2519a258))
* Updated config for Mutagen sync to exclude large files (*.sql, *.gz, *.zip, *.bz2) from sync sessions

**Bug Fixes:**

* Fixed issue where `-` in `WARDEN_ENV_NAME` would results in `0.0.0.0` being used in `extra_hosts` passed to containers
* Fixed race condition caused by docker-compose starting two containers with identical mounts simultaneously (issue [#110](https://github.com/davidalger/warden/issues/110))
* Fixed issue with incorrect network name reference when uppercase characters are present in `WARDEN_ENV_NAME` (issue [#127](https://github.com/davidalger/warden/issues/127))
* Fixed issue where Mutagen sync autostart would attempt to start when php-fpm container was not running (ex: when executing `warden env up -d db` to start only the db service)

## Version [0.3.1](https://github.com/davidalger/warden/tree/0.3.1) (2020-03-06)
[All Commits](https://github.com/davidalger/warden/compare/0.3.0..0.3.1)

**Upgrade Notes:**

If you're upgrading from version 0.2.x to 0.3.x for the first time, please reference upgrade notes for [Warden 0.3.0](https://docs.warden.dev/changelog.html#version-0-3-0-2020-03-06) and plan accordingly.

**Bug Fixes:**

* Fixed issue where `env up` and `env start` would exit with an error on env types not using Mutagen sessions
* Fixed issue where `env down` and `env stop` would exit with an error on env types not using Mutagen sessions

## Version [0.3.0](https://github.com/davidalger/warden/tree/0.3.0) (2020-03-06)
[All Commits](https://github.com/davidalger/warden/compare/0.2.4..0.3.0)

**Upgrade Notes:**

The fix for issue [#65](https://github.com/davidalger/warden/issues/65) required removing the `warden` network from each environment's services (see commit [36cb0174](https://github.com/davidalger/warden/commit/36cb0174399a40c7f3eb4c39ae70d33afd39c4a3)) and as a result environments referencing the `warden` network in per-project `.warden/*.yml` configuration files may need to be updated for compatibility with Warden 0.3.0.

Should you see an error like the following when running `warden env ...` then this applies to you:

```
ERROR: Service "nginx" uses an undefined network "warden"
```

To resolve this issue, simply remove the following from each service defined in `.warden/*.yml` files on the project similar to what was done in commit [36cb0174](https://github.com/davidalger/warden/commit/36cb0174399a40c7f3eb4c39ae70d33afd39c4a3) on the base environment definitions:

```
networks:
  - warden
  - default
```

**Bug Fixes:**

* Updated to no longer connect environment containers to `warden` network and instead peer `traefik` and `tunnel` containers with each project when it is started (issue [#65](https://github.com/davidalger/warden/issues/65))

**Enhancements:**

* Added automatic start of Mutagen sync on `env up` and `env start` when sync is not connected (issue [#90](https://github.com/davidalger/warden/issues/90))
* Added automatic stop of Mutagen sync on `env down` and `env stop` (issue [#90](https://github.com/davidalger/warden/issues/90))
* Updated routing rules so Traefik will now by default route both example.com and *.example.com to application ([#111](https://github.com/davidalger/warden/pull/111) by [davidalger](https://github.com/davidalger))

## Version [0.2.4](https://github.com/davidalger/warden/tree/0.2.4) (2020-02-29)
[All Commits](https://github.com/davidalger/warden/compare/0.2.3..0.2.4)

**Bug Fixes:**

* Updated environment path (`WARDEN_ENV_PATH` in scripts) to use physical vs logical current working directory to resolve issues with using symlinked file paths (issue [#101](https://github.com/davidalger/warden/issues/101))
* Removed confusingly quoted placeholder values related to Blackfire from env file generated by `env-init`
* Removed timeout for Selenium Hub, increased timeout for MFTF's `command.php` endpoint to 10 minutes ([#107](https://github.com/davidalger/warden/pull/107) by [lbajsarowicz](https://github.com/lbajsarowicz))
* Fixed issue where `warden sync start` would infinitely wait when Mutagen encountered an error ([#100](https://github.com/davidalger/warden/pull/100) by [Lunaetic](https://github.com/Lunaetic))

## Version [0.2.3](https://github.com/davidalger/warden/tree/0.2.3) (2020-02-14)
[All Commits](https://github.com/davidalger/warden/compare/0.2.2..0.2.3)

**Bug Fixes:**

* Fixed mutagen version check (issue [#95](https://github.com/davidalger/warden/issues/95)); ([#94](https://github.com/davidalger/warden/pull/94) by [blakesaunders](https://github.com/blakesaunders))

**Enhancements:**

* Added `explicit_defaults_for_timestamp=on` to `db` settings on `magento2` environment allowing `setup:db:status` to report clean (2.3.4 and later) (issue [#89](https://github.com/davidalger/warden/issues/89))

## Version [0.2.2](https://github.com/davidalger/warden/tree/0.2.2) (2020-02-09)
[All Commits](https://github.com/davidalger/warden/compare/0.2.1..0.2.2)

**Enhancements:**

* Updated sign-certificates command to specify "O" value and "extendedKeyUsage" to comply with stricter SSL guidelines (issue [#85](https://github.com/davidalger/warden/issues/85))

**Bug Fixes:**

* Fixed missing CN value on CA used to sign SSL certificates (issue [#85](https://github.com/davidalger/warden/issues/85))

## Version [0.2.1](https://github.com/davidalger/warden/tree/0.2.1) (2020-01-30)
[All Commits](https://github.com/davidalger/warden/compare/0.2.0..0.2.1)

**Upgrade Notes:**

If you're upgrading from version 0.1.x to 0.2.x for the first time, please reference upgrade notes for [Warden 0.2.0](https://docs.warden.dev/changelog.html#version-0-2-0-2020-01-27) and plan accordingly.

**Enhancements:**

* Added support for using `~/.warden/.env` to configure aspects of Global Services ([see docs for details](https://docs.warden.dev/services.html)) (issue [#13](https://github.com/davidalger/warden/issues/13))
* Updated `sync start` to no longer call `mutagen daemon start` as Mutagen now does this automatically.
* Updated `warden install` to include short hostname in the common name used when signing the Root CA used by Warden allowing easier identification and interoperability when a single user is running Warden across multiple workstations.

## Version [0.2.0](https://github.com/davidalger/warden/tree/0.2.0) (2020-01-27)
[All Commits](https://github.com/davidalger/warden/compare/0.1.12..0.2.0)

**Upgrade Notes:**

As mentioned below this release of Warden brings with it an update to Traefik 2.1. The v2 line of Traefik completely overhauled the labelling system used to define routes. It also opens the door to new possibilities. All labeling on built-in environment configurations has been updated for compatibility with new versions of Traefik. However, this is a **breaking change** in the two following scenarios:

* The `local` environment type is being used. When `local` env type is used, all config is contained in the project's `.warden/` directory and routes setup via labels on the custom containers will naturally need to be updated.
* Projects using custom labels applied via override files such as `.warden/warden-env.yml` may need to be updated.

Please reference the updated [base environment definitions](https://github.com/davidalger/warden/tree/develop/environments) for examples of how to update the labels on custom definitions.

Environments referencing `laravel.conf` in custom configuration within `.warden` directory must update their configuration to reference the generic `application.conf` instead as the file was renamed in the Nginx image for re-use in the future on additional environment types.

Docker images have all been re-located and/or mirrored to Quay with all built-in environment types having been updated to reference the images at the new location. Images currently on Docker Hub will remain available in order to preserve functionality of Warden 0.1.x release line *(**UPDATE** These images have been removed as of May 28th, 2020)*, but will no longer be updated and compatibility with all functionality in Warden 0.2.0 is not guaranteed. Where these images are referenced in per-project configuration within the `.warden` directory, it is strongly suggested these references be updated to use images at the new locations:

* [https://quay.io/repository/warden/varnish?tab=tags](https://quay.io/repository/warden/varnish?tab=tags)
* [https://quay.io/repository/warden/redis?tab=tags](https://quay.io/repository/warden/redis?tab=tags)
* [https://quay.io/repository/warden/rabbitmq?tab=tags](https://quay.io/repository/warden/rabbitmq?tab=tags)
* [https://quay.io/repository/warden/php-fpm?tab=tags](https://quay.io/repository/warden/php-fpm?tab=tags)
* [https://quay.io/repository/warden/nginx?tab=tags](https://quay.io/repository/warden/nginx?tab=tags)
* [https://quay.io/repository/warden/mariadb?tab=tags](https://quay.io/repository/warden/mariadb?tab=tags)
* [https://quay.io/repository/warden/mailhog?tab=tags](https://quay.io/repository/warden/mailhog?tab=tags)
* [https://quay.io/repository/warden/elasticsearch?tab=tags](https://quay.io/repository/warden/elasticsearch?tab=tags)

**Enhancements:**
* Added native support for multi-domain projects without requiring per-project routing configuration. This is accomplished using wildcard rules in the new Traefik labeling configuration allowing Warden to automatically route any sub-domain of the `TRAEFIK_DOMAIN` value in `.env` to the nginx and/or varnish container for handling by the application.
* Added `warden debug` command which launches user into Xdebug enabled `php-debug` container for debugging CLI based workflows (issue [#33](https://github.com/davidalger/warden/issues/33); [#35](https://github.com/davidalger/warden/pull/35) by [molotovbliss](https://github.com/molotovbliss))
* Added labels to `fpm` containers in `magento2` environment to support use of Live Reload via an injected JS snippet in the site header or footer (issue [#62](https://github.com/davidalger/warden/issues/62))
* Added `WARDEN_ENV_NAME` as prefix to each container hostname in compose configs (issue [#29](https://github.com/davidalger/warden/issues/29))
* Added `BYPASS_VARNISH` flag which when set in project `.env` file will cause Traefik to route requests directly to `nginx` container rather than `varnish` (issue [#63](https://github.com/davidalger/warden/issues/63))
* Added `laravel` environment type to support local development of Laravel based applications (issue [#60](https://github.com/davidalger/warden/issues/60))
* Added Allure reporting support to Selenium setup for MFTF ([#69](https://github.com/davidalger/warden/pull/69) by [lbajsarowicz](https://github.com/lbajsarowicz))
* Updated Traefik container and configuration to deploy Traefik 2.1; this is a **potentially breaking change** as Traefik v2 overhauled the labeling used to auto-configure routing on containers. All labeling on built-in environment configurations has been updated, but where labels are used to configure Traefik in per-project configuration files such as in `.warden/warden-env.yml` the project may require a coordinated update to labeling for continued interoperability of the customizations with Warden 0.2.0+
* Updated Mutagen usage to rely on new commands and configuration in Mutagen 0.10+ (Warden will now throw an error if you attempt to start a sync and have a version of Mutagen older than 0.10.3 installed)
* Updated configuration setup for SSH tunnel container so it will automatically re-instate the needed configuration (if missing) when running `up`, `start`, or `restart` to mitigate issue caused by macOS Catalina updates wiping out customizations to `/etc/ssh/ssh_config` (issue [#59](https://github.com/davidalger/warden/issues/59))
* Updated `env-init` command to include default values for available variables in the project's `.env` making customization a bit easier (issue [#32](https://github.com/davidalger/warden/issues/32))
* Updated default Elasticsearch version for `magento2` environments from 5.4 to 6.8 (issue [#66](https://github.com/davidalger/warden/issues/66))
* Updated Selenium setup for MFTF to use hub and headless nodes by default (issue [#67](https://github.com/davidalger/warden/issues/67); [#68](https://github.com/davidalger/warden/pull/68) by [lbajsarowicz](https://github.com/lbajsarowicz))
* Updated environment templates to pass `TRAEFIK_DOMAIN` and `TRAEFIK_SUBDOMAIN` into `php-fpm` and `php-debug` for use in documented install routine (issue [#42](https://github.com/davidalger/warden/issues/42))
* Updated default PHP version for `magento2` environments from 7.2 to 7.3 (issue [#75](https://github.com/davidalger/warden/issues/75))
* Updated default Varnish version for `magento2` environments from 4.1 to 6.0 (LTS)
* Changed `laravel.conf` in nginx image to generic `application.conf`
* Updated defaults for nginx on `magento2` environments to be set in the docker env vs built into the nginx image; the image now defaults to loading the generic `application.conf` with `/var/www/html` as webroot

**Bug fixes:**
* Fixed broken incorrect Blackfire environment template name for magento1 env type (issue [#48](https://github.com/davidalger/warden/issues/48))
* Fixed inability to get help content specific to env sub-commands using `warden env <command> -h`

## Version [0.1.12](https://github.com/davidalger/warden/tree/0.1.12) (2019-12-10)
[All Commits](https://github.com/davidalger/warden/compare/0.1.11..0.1.12)

**Bug fixes:**
* Fixed issue breaking SSH tunnel as used for port-forwards.

## Version [0.1.11](https://github.com/davidalger/warden/tree/0.1.11) (2019-11-26)
[All Commits](https://github.com/davidalger/warden/compare/0.1.10..0.1.11)

**Enhancements:**
* Added option to enable and setup Selenium for use with MFTF via flag in project's `.env` file ([#40](https://github.com/davidalger/warden/pull/40) by [lbajsarowicz](https://github.com/lbajsarowicz))
* Added error message to `warden install` when `docker-compose` version in `$PATH` is incompatible ([#41](https://github.com/davidalger/warden/pull/41) by [lbajsarowicz](https://github.com/lbajsarowicz))

## Version [0.1.10](https://github.com/davidalger/warden/tree/0.1.10) (2019-09-23)

* Added native support to Warden for using the [split-database system](https://devdocs.magento.com/guides/v2.3/config-guide/multi-master/multi-master.html) in Magento Commerce during local development ([#5](https://github.com/davidalger/warden/pull/5) by [navarr](https://github.com/navarr))
* Added support for optional Blackfire profiling which can be enabled via settings in the project's `.env` file ([#12](https://github.com/davidalger/warden/pull/12) by [navarr](https://github.com/navarr))

## Version [0.1.9](https://github.com/davidalger/warden/tree/0.1.9) (2019-09-19)

* Pinned image for Traefik to use `traefik:v1.7` imgae vs `traefik:latest` to resolve issues caused by Traefik 2.0 having breaking changes in the configuration API

## Version [0.1.8](https://github.com/davidalger/warden/tree/0.1.8) (2019-09-06)

* Introduced `NODE_VERSION` environment variable to specify which version of NodeJS to install in FPM images during container startup (by default v10 is now pre-installed in `mage1-fpm` and `mage2-fpm` images at the time of this release; latest images must be pulled from Docker Hub for this to work).
* Fixed issue where if sub-directory included a relative symlink pointing `.env` at parent project's `.env` file, `--project-dir` passed to `docker-compose` could be specified incorrectly when running warden from within the given sub-directory.

## Version [0.1.7](https://github.com/davidalger/warden/tree/0.1.7) (2019-08-23)

* All published ports now listen on `127.0.0.1` by default as opposed to `0.0.0.0` for a local environment that is fully inaccessible to the outside world apart from using a proxy (such as [Charles](https://www.charlesproxy.com/)).

## Version [0.1.6](https://github.com/davidalger/warden/tree/0.1.6) (2019-08-10)

* Changed the default value `env-init` uses for `TRAEFIK_SUBDOMAIN` to `app` (previously it would match the environment type)
* Added mount of `~/.warden/ssl/rootca/certs:/etc/ssl/warden-rootca-cert:ro` to each env type's `php-fpm` and `php-debug` containers to support FPM images appending this CA root to the trusted ca-bundle on container start
* Added `extra_hosts` entry to set an entry in `/etc/hosts` within `php-fpm` and `php-debug` containers pointing the project's primary domain to the Traefik service IP address so `curl` and `SoapClient` (for example) may work inside a project's FPM services
* Added FPM containers to the "warden" network so they'll be able to route http requests to Traefik

## Version [0.1.5](https://github.com/davidalger/warden/tree/0.1.5) (2019-07-19)

* Changed Mutagen polling interval from 20 to 10 seconds
* Removed `generated` directory from exclusions in Mutagen sync configuration (having this ignored breaks ability to step into generated class files during Xdebug sessions)
* Fixed issue with Mutagen sync cofiguration causing `pub/static` (and other files) to have incorrect permissions resulting in 404'ing static resources
* Fixed issue causing `warden env` to break when run from a path which contained a space (issue [#3](https://github.com/davidalger/warden/issues/3))

## Version [0.1.4](https://github.com/davidalger/warden/tree/0.1.4) (2019-07-15)

* Removed exclusion of 'node_modules' from Mutagen sync for Magento 2 to avoid breaking Dotdigitalgroup_Email module in vendor directory (this module includes a node_modules dir pre-installed).

## Version [0.1.3](https://github.com/davidalger/warden/tree/0.1.3) (2019-07-10)

* Added ability on linux to prevent warden from touching dns configuration when `~/.warden/nodnsconfig` is present.
* Updated install routine to properly trust CA root on Ubuntu (previously warden install would simply fail)
* Updated DNS auto-configuration on linux systems to handle systemd-resolved usage.
* Fixed issue on Ubuntu where dnsmasq container would fail to bind to port 53.
* Fixed issue where lack of `~/.composer` dir (resulting in creation by docker) can cause permissions error inside containers.
* Fixed issue with `bin/magento setup:install` allowing it to pass permissions checks ([#2](https://github.com/davidalger/warden/pull/2) by [fooman](https://github.com/fooman))
* Fixed issue where `env` and `env-init` commands failed to reset shell colors when printing error messages (issue [#4](https://github.com/davidalger/warden/issues/4))

## Version [0.1.2](https://github.com/davidalger/warden/tree/0.1.2) (2019-07-03)

* Added `warden shell` command for easily dropping into the `php-fpm` container (container name is configurable for supporting "local" environment types)
* Added `max_allowed_packet=1024M` to `db` containers for M1 and M2 environments to avoid imports or upgrade routines from failing on large packets.
* Changed `php-fpm` and `php-debug` to use custom images based on `centos:7` as opposed to the `alpine3.9` based official php-fpm images to avoid seg-faults when Source Guardian loader is installed alongside Xdebug.
* Fixed issue with DEFINER stripping in `db import` allowing it to correctly strip from both TRIGGERS and ALGORITHM clauses.

## Version [0.1.1](https://github.com/davidalger/warden/tree/0.1.1) (2019-06-27)

* Fixed bug where 'db' commands broke due to template overhaul in 0.1.0 release.

## Version [0.1.0](https://github.com/davidalger/warden/tree/0.1.0) (2019-06-27)

* Changed the env type setup to automatically include additional configuration based on $OSTYPE.
* Changed the environment template structure to utilize per-OSTYPE docker-compose config additions where environments differ from one host OS to another (such as `magento2` env type, which uses plain mounts on `linux-gnu` but sync sessions on `darwin`)
* Fixed a few error messages so they won't change shell text color permanently when they output.
* Fixed sync command to output error message when any sub-command is run on an env lacking a mutagen configuration.

## Version [0.1.0-beta7](https://github.com/davidalger/warden/tree/0.1.0-beta7)

* Added Xdebug support via additional `php-debug` container which Nginx routes to based on presence of `XDEBUG_SESSION` cookie.
* Fixed Elasticsearch images used in Magento 2 environment templates and configured for lower overall memory utilization upon container start for a smaller env footprint.

## Version [0.1.0-beta6](https://github.com/davidalger/warden/tree/0.1.0-beta6)

* Added support for extending environment configuration on a per-project basis via `.warden/warden-env.yml` and `.warden/warden-env.<WARDEN_ENV_TYPE>.yml` files
* Added `local` env type to support projects which do not conform to any of the templated environments suppoprted out-of-the-box
* Changed Traefik configuration to automatically use the warden docker network (eliminates need for `traefik.docker.network=warden` label on all proxied containers
* Changed Traefik configuration to require containers be explicitly enabled for Traefik via the label `traefik.enable=true`
* Changed docker-compose environment type templates to version 3.5 for better extendability in project override files
* Fixed bug where resolver setup on macOS would fail if `/etc/resolver` dir was already present during install ([#1](https://github.com/davidalger/warden/pull/1) by [fooman](https://github.com/fooman))

## Version [0.1.0-beta5](https://github.com/davidalger/warden/tree/0.1.0-beta5)

* Fixed issue with docker-compose exit codes would result in error messages from global trap
* Added auto-install of mutagen where not already present when any sync command is run
* Added support for WARDEN_WEB_ROOT env setting to publish a sub-dir into /var/www/html
* Changed images for php-fpm to use environment type specfic images from davidalger/warden repository

## Version [0.1.0-beta4](https://github.com/davidalger/warden/tree/0.1.0-beta4)

* Added "env" command for controlling docker based per-project environments (currently this simply passes all commands and arguments through to docker-compose).
* Added "env-init" to add `.env` file with Warden configuration to the current working directory.
* Added "sync" command with start/stop/list sub-commands for controlling per-project mutagen sessions.
* Added "db" command for connecting to mysql and importing databases into the db service.
* Added three environment types: `magento1`, `magento2-mutagen`, `magento2-native` with auto-selecting the correct M2 environment on Linux/macOS.
* Fixed dnsmasq setup on Linux (nameserver is now configured on Linux when NetworkManager service is active during install; tested on Fedora 29)

## Version [0.1.0-beta3](https://github.com/davidalger/warden/tree/0.1.0-beta3)

* Fixed infinite loop on initial setup routine.

## Version [0.1.0-beta2](https://github.com/davidalger/warden/tree/0.1.0-beta2)

* Updated assertion to automatically execute "warden install" if installed metadata indicator is older than bin/warden.
* Fixed issue on Linux hosts where ssh_key.pub was unusable inside tunnel container due to bad permissions.

## Version [0.1.0-beta1](https://github.com/davidalger/warden/tree/0.1.0-beta1)

* Initial beta release.
