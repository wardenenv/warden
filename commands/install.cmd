#!/usr/bin/env bash
[[ ! ${WARDEN_COMMAND} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

source "${WARDEN_DIR}/utils/core.sh"
source "${WARDEN_DIR}/utils/install.sh"

if ! ( hash docker-compose 2>/dev/null); then
    echo -e "\033[31mdocker-compose is not installed" && exit 1
fi

DOCKER_COMPOSE_VERSION="$(docker-compose -v | grep -oE '[0-9\.]+' | head -n1)"
if ! test $(version ${DOCKER_COMPOSE_VERSION}) -ge $(version ${WARDEN_REQUIRED_DOCKER_COMPOSE}); then
    echo -e "\033[31mdocker-compose version should be $WARDEN_REQUIRED_DOCKER_COMPOSE or higher ($DOCKER_COMPOSE_VERSION installed)" && exit 1
fi

if [[ ! -d "${WARDEN_SSL_DIR}/rootca" ]]; then
    mkdir -p "${WARDEN_SSL_DIR}/rootca"/{certs,crl,newcerts,private}

    touch "${WARDEN_SSL_DIR}/rootca/index.txt"
    echo 1000 > "${WARDEN_SSL_DIR}/rootca/serial"
fi

# create CA root certificate if none present
if [[ ! -f "${WARDEN_SSL_DIR}/rootca/private/ca.key.pem" ]]; then
  echo "==> Generating private key for local root certificate"
  openssl genrsa -out "${WARDEN_SSL_DIR}/rootca/private/ca.key.pem" 2048
fi

if [[ ! -f "${WARDEN_SSL_DIR}/rootca/certs/ca.cert.pem" ]]; then
  echo "==> Signing root certificate 'Warden Proxy Local CA ($(hostname -s))'"
  openssl req -new -x509 -days 7300 -sha256 -extensions v3_ca \
    -config "${WARDEN_DIR}/config/openssl/rootca.conf"        \
    -key "${WARDEN_SSL_DIR}/rootca/private/ca.key.pem"        \
    -out "${WARDEN_SSL_DIR}/rootca/certs/ca.cert.pem"         \
    -subj "/C=US/O=Warden.dev/CN=Warden Proxy Local CA ($(hostname -s))"
fi

## trust root ca differently on Fedora, Ubuntu and macOS
if [[ "$OSTYPE" =~ ^linux ]] \
  && [[ -d /etc/pki/ca-trust/source/anchors ]] \
  && [[ ! -f /etc/pki/ca-trust/source/anchors/warden-proxy-local-ca.cert.pem ]] \
  ## Fedora/CentOS
then
  echo "==> Trusting root certificate (requires sudo privileges)"  
  sudo cp "${WARDEN_SSL_DIR}/rootca/certs/ca.cert.pem" /etc/pki/ca-trust/source/anchors/warden-proxy-local-ca.cert.pem
  sudo update-ca-trust
  sudo update-ca-trust enable
elif [[ "$OSTYPE" =~ ^linux ]] \
  && [[ -d /usr/local/share/ca-certificates ]] \
  && [[ ! -f /usr/local/share/ca-certificates/warden-proxy-local-ca.crt ]] \
  ## Ubuntu/Debian
then
  echo "==> Trusting root certificate (requires sudo privileges)"
  sudo cp "${WARDEN_SSL_DIR}/rootca/certs/ca.cert.pem" /usr/local/share/ca-certificates/warden-proxy-local-ca.crt
  sudo update-ca-certificates
elif [[ "$OSTYPE" == "darwin"* ]] \
  && ! security dump-trust-settings -d | grep 'Warden Proxy Local CA' >/dev/null \
  ## Apple macOS
then
  echo "==> Trusting root certificate (requires sudo privileges)"
  sudo security add-trusted-cert -d -r trustRoot \
    -k /Library/Keychains/System.keychain "${WARDEN_SSL_DIR}/rootca/certs/ca.cert.pem"
fi

## configure resolver for .test domains; allow linux machines to prevent warden
## from touching dns configuration if need be since unlike macOS there is not
## support for resolving only *.test domains via /etc/resolver/test settings
if [[ "$OSTYPE" =~ ^linux ]] && [[ ! -f "${WARDEN_HOME_DIR}/nodnsconfig" ]]; then
  if systemctl status NetworkManager | grep 'active (running)' >/dev/null \
    && ! grep '^nameserver 127.0.0.1$' /etc/resolv.conf >/dev/null
  then
    echo "==> Configuring resolver for .test domains (requires sudo privileges)"
    if ! sudo grep '^prepend domain-name-servers 127.0.0.1;$' /etc/dhcp/dhclient.conf >/dev/null 2>&1; then
      echo "  + Configuring dhclient to prepend dns with 127.0.0.1 resolver (requires sudo privileges)"

      ## Ensure /etc/dhcp exists before writing dhclient.conf (on ArchLinux this may not pre-exist)
      if [[ ! -d /etc/dhcp ]]; then
        sudo mkdir /etc/dhcp
      fi

      DHCLIENT_CONF=$'\n'"$(sudo cat /etc/dhcp/dhclient.conf 2>/dev/null)" || DHCLIENT_CONF=
      DHCLIENT_CONF="prepend domain-name-servers 127.0.0.1;${DHCLIENT_CONF}"
      echo "${DHCLIENT_CONF}" | sudo tee /etc/dhcp/dhclient.conf
      sudo systemctl restart NetworkManager
    fi

    ## When systemd-resolvd is used (as it is on Ubuntu by default) check the resolv config mode
    if systemctl status systemd-resolved | grep 'active (running)' >/dev/null \
      && [[ -L /etc/resolv.conf ]] \
      && [[ "$(readlink /etc/resolv.conf)" != "../run/systemd/resolve/resolv.conf" ]]
    then
      echo "  + Configuring systemd-resolved to use dhcp settings (requires sudo privileges)"
      echo "    by pointing /etc/resolv.conf at resolv.conf vs stub-resolv.conf"
      sudo ln -fsn ../run/systemd/resolve/resolv.conf /etc/resolv.conf
    fi
  fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
  if [[ ! -f /etc/resolver/test ]]; then
    echo "==> Configuring resolver for .test domains (requires sudo privileges)"
    if [[ ! -d /etc/resolver ]]; then
        sudo mkdir /etc/resolver
    fi
    echo "nameserver 127.0.0.1" | sudo tee /etc/resolver/test >/dev/null
  fi
elif [[ -f "${WARDEN_HOME_DIR}/nodnsconfig" ]]; then
  echo -e "\033[33m==> WARNING: The flag '${WARDEN_HOME_DIR}/nodnsconfig' is present; skipping DNS configuration\033[0m"
else
  echo -e "\033[33m==> WARNING: Use of dnsmasq is not supported on this system; entries in /etc/hosts will be required\033[0m"
fi

## generate rsa keypair for authenticating to warden sshd service
if [[ ! -f "${WARDEN_HOME_DIR}/tunnel/ssh_key" ]]; then
  echo "==> Generating rsa key pair for tunnel into sshd service"
  mkdir -p "${WARDEN_HOME_DIR}/tunnel"
  ssh-keygen -b 2048 -t rsa -f "${WARDEN_HOME_DIR}/tunnel/ssh_key" -N "" -C "user@tunnel.warden.test"
fi

## if host machine does not have composer installed, this directory will otherwise be created by docker with root:root
## causing problems so it's created as current user to avoid composer issues inside environments given it is mounted
if [[ ! -d ~/.composer ]]; then
  mkdir ~/.composer
fi

## since bind mounts are native on linux to use .pub file as authorized_keys file in tunnel it must have proper perms
if [[ "$OSTYPE" =~ ^linux ]] && [[ "$(stat -c '%U' "${WARDEN_HOME_DIR}/tunnel/ssh_key.pub")" != "root" ]]; then
  sudo chown root:root "${WARDEN_HOME_DIR}/tunnel/ssh_key.pub"
fi

## append settings for tunnel.warden.test in /etc/ssh/ssh_config
installSshConfig
