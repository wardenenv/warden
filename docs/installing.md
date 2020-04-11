Installing Warden
==================================

### Prerequisites

* [Docker Desktop for Mac
](https://hub.docker.com/editions/community/docker-ce-desktop-mac) 2.2.0.0 or later; or [Docker for Linux](https://docs.docker.com/install/) (Warden has been tested on Fedora 29 and Ubuntu 18.10)
* `docker-compose` available in your `$PATH` (can be installed via `brew`, `apt`, `dnf`, or `pip3`)
* [Mutagen](https://mutagen.io/) v0.10.3 or later installed via Homebrew (required on macOS only; Warden will attempt to install this via `brew` if not present)

``` warning::
    **By default Docker Desktop allocates 2GB memory.** This leads to extensive swapping, killed processed and extremely high CPU usage during some Magento actions, like for example running sampledata:deploy and/or installing the application. It is recommended to assign at least 6GB RAM to Docker Desktop prior to deploying any Magento environments on Docker Desktop. This can be corrected via Preferences -> Resources -> Advanced -> Memory. While you are there, it wouldn't hurt to let Docker have the use of a few more vCPUs (keep it at least 4 less than the maximum CPU allocation however to avoid having macOS contend with Docker for use of cores)
```

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
