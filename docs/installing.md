Installing Warden
==================================

### Prerequisites

* [Docker for Mac](https://hub.docker.com/editions/community/docker-ce-desktop-mac) or [Docker for Linux](https://docs.docker.com/install/) (Warden has been tested on Fedora 29 and Ubuntu 18.10)
* `docker-compose` available in your `$PATH` (can be installed via `brew`, `apt`, `dnf`, or `pip3`)
* [Mutagen](https://mutagen.io/) v0.10.3 or later installed via Homebrew (required on macOS only; Warden will attempt to install this via `brew` if not present when running `warden sync start`).

**Warning: By default Docker Desktop allocates 2GB memory.** This leads to extensive swapping, killed processed and extremely high CPU usage during some Magento actions, like for example running sampledata:deploy and/or installing the application. It is recommended to assign at least 6GB RAM to Docker Desktop prior to deploying any Magento environments on Docker Desktop. This can be corrected via Preferences -> Advanced -> Memory. While you are there, it wouldn't hurt to let Docker have the use of a few more vCPUs (keep it at least 4 less than the maximum CPU allocation however to avoid having macOS contend with Docker for use of cores)

### Installing via Homebrew

Warden may be installed via [Homebrew](https://brew.sh/) on both macOS and Linux hosts:

    brew install davidalger/warden/warden
    warden up

### Alternative Installation

Warden may be installed by cloning the repository to the directory of your choice and adding it to your `$PATH`. This method of installation may be when Homebrew does not already exist on your system or when preparing contributions to the Warden project.

    sudo mkdir /opt/warden
    sudo chown $(whoami) /opt/warden
    git clone -b master https://github.com/davidalger/warden.git /opt/warden
    echo 'export PATH="/opt/warden/bin:$PATH"' >> ~/.bashrc
    PATH="/opt/warden/bin:$PATH"
    warden up

### Recommended Additions

* `pv` installed and available in your `$PATH` (you can install this via `brew install pv`) for use sending database files to `warden db import` and providing determinate progress indicators for the import. Alternatively `cat` may be used where `pv` is referenced in documentation but will not provide progress indicators.
* On macOS it is **highly recommended** to install `docker-compose` via `pip3 install --user docker-compose` adding `~/Library/Python/3.7/bin/` to your `$PATH` vs relying on the `docker-compose` binary installed by Docker for Mac (or installing via brew, which Docker for Mac overwrites each time it starts); the binary installed by Docker for Mac out of the box takes roughly 8 to 20 times as long to initialize due to entropy related code (for example a `docker-compose version` command will take 2 to 5 seconds vs what should be a fraction of a second). Installing `docker-compose` via a third-party package manager such as `pip3` to a location other than `/usr/local/bin` (which Docker for Mac overwrites on startup) will resolve the slowness caused by Warden using `docker-compose` under the hood.
