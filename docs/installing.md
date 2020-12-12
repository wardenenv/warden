Installing Warden
==================================

### Prerequisites

* [Docker Desktop for Mac
](https://hub.docker.com/editions/community/docker-ce-desktop-mac) 2.2.0.0 or later or [Docker for Linux](https://docs.docker.com/install/) (Warden has been tested on Fedora 29 and Ubuntu 18.10)
* `docker-compose` version 1.25.0 or later is required (this can be installed via `brew`, `apt`, `dnf`, or `pip3` as needed)
* [Mutagen](https://mutagen.io/) 0.11.4 or later is required for environments leveraging sync sessions on Mac OS. Warden will attempt to install this via `brew` if not present.

``` warning::
    **By default Docker Desktop allocates 2GB memory.** This leads to extensive swapping, killed processed and extremely high CPU usage during some Magento actions, like for example running sampledata:deploy and/or installing the application. It is recommended to assign at least 6GB RAM to Docker Desktop prior to deploying any Magento environments on Docker Desktop. This can be corrected via Preferences -> Resources -> Advanced -> Memory. While you are there, it wouldn't hurt to let Docker have the use of a few more vCPUs (keep it at least 4 less than the maximum CPU allocation however to avoid having macOS contend with Docker for use of cores)
```

### Installing via Homebrew

Warden may be installed via [Homebrew](https://brew.sh/) on both macOS and Linux hosts:

    brew install davidalger/warden/warden
    warden svc up

### Alternative Installation

Warden may be installed by cloning the repository to the directory of your choice and adding it to your `$PATH`. This method of installation may be when Homebrew does not already exist on your system or when preparing contributions to the Warden project.

    sudo mkdir /opt/warden
    sudo chown $(whoami) /opt/warden
    git clone -b master https://github.com/davidalger/warden.git /opt/warden
    echo 'export PATH="/opt/warden/bin:$PATH"' >> ~/.bashrc
    PATH="/opt/warden/bin:$PATH"
    warden svc up

### Next Steps

#### Automatic DNS Resolution

On Linux environments, you will need to configure your DNS to resolve `*.test` to `127.0.0.1` or use `/etc/hosts` entries. On Mac OS this configuration is automatic via the BSD per-TLD resolver configuration found at `/etc/resolver/test`.

For more information see the configuration page for [Automatic DNS Resolution](configuration/dns-resolver.html)

#### Trusted CA Root Certificate

In order to sign SSL certificates that may be trusted by a developer workstation, Warden uses a CA root certificate with CN equal to `Warden Proxy Local CA (<hostname>)` where `<hostname>` is the hostname of the machine the certificate was generated on at the time Warden was first installed. The CA root can be found at `~/.warden/ssl/rootca/certs/ca.cert.pem`.

On MacOS this root CA certificate is automatically added to a users trust settings as can be seen by searching for 'Warden Proxy Local CA' in the Keychain application. This should result in the certificates signed by Warden being trusted by Safari and Chrome automatically. If you use Firefox, you will need to add this CA root to trust settings specific to the Firefox browser per the below.

On Ubuntu/Debian this CA root is copied into `/usr/local/share/ca-certificates` and on Fedora/CentOS (Enterprise Linux) it is copied into `/etc/pki/ca-trust/source/anchors` and then the trust bundle is updated appropriately. For new systems, this typically is all that is needed for the CA root to be trusted on the default Firefox browser, but it may not be trusted by Chrome or Firefox automatically should the browsers have already been launched prior to the installation of Warden (browsers on Linux may and do cache CA bundles)

``` note::
    If you are using **Firefox** and it warns you the SSL certificate is invalid/untrusted, go to Preferences -> Privacy & Security -> View Certificates (bottom of page) -> Authorities -> Import and select ``~/.warden/ssl/rootca/certs/ca.cert.pem`` for import, then reload the page.

    If you are using **Chrome** on **Linux** and it warns you the SSL certificate is invalid/untrusted, go to Chrome Settings -> Privacy And Security -> Manage Certificates (see more) -> Authorities -> Import and select ``~/.warden/ssl/rootca/certs/ca.cert.pem`` for import, then reload the page.
```
