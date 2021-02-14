#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

source "${WARDEN_DIR}/utils/install.sh"

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

## configure resolver for .test domains on Mac OS only as Linux lacks support
## for BSD like per-TLD configuration as is done at /etc/resolver/test on Mac
if [[ "$OSTYPE" == "darwin"* ]]; then
  if [[ ! -f /etc/resolver/test ]]; then
    echo "==> Configuring resolver for .test domains (requires sudo privileges)"
    if [[ ! -d /etc/resolver ]]; then
        sudo mkdir /etc/resolver
    fi
    echo "nameserver 127.0.0.1" | sudo tee /etc/resolver/test >/dev/null
  fi
else
  warning "Manual configuration required for Automatic DNS resolution: https://docs.warden.dev/configuration/dns-resolver.html"
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
