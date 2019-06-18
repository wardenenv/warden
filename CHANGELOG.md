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
