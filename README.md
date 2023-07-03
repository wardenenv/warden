# Warden

Warden is a CLI utility for orchestrating Docker based developer environments, and enables multiple local environments to run simultaneously without port conflicts via the use of a few centrally run services for proxying requests into the correct environment's containers.

<!-- include_open_stop -->

* [Warden Website](https://warden.dev/)
* [Warden Documentation](https://docs.warden.dev/)
* [Installing Warden](https://docs.warden.dev/installing.html)
* [Environment Types](https://docs.warden.dev/environments.html)
* [Docker Images](https://docs.warden.dev/images.html)

## Features

* Traefik for SSL termination and routing/proxying requests into the correct containers.
* Portainer for quick visibility into what's running inside the local Docker host.
* Dnsmasq to serve DNS responses for `.test` domains eliminating manual editing of `/etc/hosts`
* An SSH tunnel for connecting from Sequel Pro or TablePlus into any one of multiple running database containers.
* Warden issued wildcard SSL certificates for running https on all local development domains.
* Full support for Magento 1, Magento 2, Laravel, Symfony 4, Shopware 6 on both macOS and Linux.
* Ability to override, extend, or setup completely custom environment definitions on a per-project basis.

## Contributing

All contributions to the Warden project are welcome: use-cases, documentation, code, patches, bug reports, feature requests, etc. Any and all contributions may be made by submitting [Issues](https://github.com/davidalger/warden/issues) and [Pull Requests](https://github.com/davidalger/warden/pulls) here on Github.

Please note that by submitting a pull request or otherwise contributing to the Warden project, you warrant that each of your contributions is an original work and that you have full authority to grant rights to said contribution and by so doing you grant the owners of the Warden project, and those who receive the contribution directly or indirectly, a perpetual, worldwide, non-exclusive, royalty-free, irrevocable license to make, have made, use, offer to sell, sell and import or otherwise dispose of the contributions alone or with the Warden project in it's entirety.

## Where to Contribute

* [warden](https://github.com/wardenenv/warden) - `warden` commands and docker-compose files
* [images](https://github.com/wardenenv/images) - Docker images to be used by the docker-compose files
* [docs](https://github.com/wardenenv/docs) - Documentation (docs.warden.dev)
* [homebrew-warden](https://github.com/wardenenv/homebrew-warden) - Mac's Homebrew installation instructions and requirements

## License

This work is licensed under the MIT license. See [LICENSE](https://github.com/davidalger/warden/blob/develop/LICENSE) file for details.

## Author Information

This project was started in 2019 by [David Alger](https://davidalger.com/).

# Gold Sponsors
[![SwiftOtter](https://warden.dev/img/sponsors/swiftotter.svg)](https://www.swiftotter.com/)  
[![Sansec.io](https://warden.dev/img/sponsors/sansec.svg)](https://www.sansec.io/)  
[![Hyvä](https://user-images.githubusercontent.com/145128/226427529-53483968-c9ab-484a-9ae3-c6abb58f81c9.png)](https://www.hyva.io/)

Support Warden Development on <a href="https://opencollective.com/warden" rel="me" class="link">OpenCollective</a> or <a href="https://github.com/sponsors/wardenenv" rel="me" class="link">Github Sponsors</a>
