#!/usr/bin/env bash
[[ ! ${WARDEN_COMMAND} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!" && exit 1

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
  echo "==> Signing root certificate (Warden Proxy Local CA)"
  openssl req -new -x509 -days 7300 -sha256 -extensions v3_ca \
    -config "${WARDEN_DIR}/config/openssl/rootca.conf"        \
    -key "${WARDEN_SSL_DIR}/rootca/private/ca.key.pem"        \
    -out "${WARDEN_SSL_DIR}/rootca/certs/ca.cert.pem"         \
    -subj "/C=US/O=Warden Proxy Local CA"
fi

if ! security dump-trust-settings -d | grep 'Warden Proxy Local CA' >/dev/null; then
  echo "==> Trusting root certificate (requires sudo privileges)"
  sudo security add-trusted-cert -d -r trustRoot \
      -k /Library/Keychains/System.keychain "${WARDEN_SSL_DIR}/rootca/certs/ca.cert.pem"
fi

if [[ ! -f "${WARDEN_SSL_DIR}/certs/warden.test.crt.pem" ]]; then
  "${WARDEN_DIR}/bin/warden" sign-certificate warden.test
fi

## configure resolver for .test domains
if [[ ! -d /etc/resolver ]] || [[ ! -f /etc/resolver/test ]]; then
  echo "==> Configuring resolver for .test domains (requires sudo privileges)"
  sudo mkdir /etc/resolver
  echo "nameserver 127.0.0.1" | sudo tee /etc/resolver/test >/dev/null
fi

## generate rsa keypair for authenticating to warden sshd service
if [[ ! -f "${WARDEN_HOME_DIR}/sshd/tunnel" ]]; then
  echo "==> Generating rsa key pair for tunnel into sshd service"
  mkdir -p "${WARDEN_HOME_DIR}/sshd"
  ssh-keygen -b 2048 -t rsa -f "${WARDEN_HOME_DIR}/sshd/tunnel" -N "" -C "tunnel@sshd.warden.test"
fi

## TODO: Add following to the global ssh config at /etc/ssh/ssh_config (will require sudo)
# Host sshd.warden.test
#   HostName 127.0.0.1
#   User tunnel
#   Port 2222
#   IdentityFile ~/.warden/sshd/tunnel
#
