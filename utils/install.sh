#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

function isWsl () {
  [[ -n "${WSL_DISTRO_NAME:-}" ]] && return 0
  [[ -r /proc/sys/kernel/osrelease ]] && grep -qiE '(microsoft|wsl)' /proc/sys/kernel/osrelease && return 0
  [[ -r /proc/version ]] && grep -qiE '(microsoft|wsl)' /proc/version && return 0
  return 1
}

function hasWindowsCertificateBridge () {
  isWsl && command -v powershell.exe >/dev/null 2>&1
}

function trustRootCaInWindows () {
  local cert_path="${1}"
  local windows_cert_path powershell_script trust_status

  [[ -f "${cert_path}" ]] || return 1

  windows_cert_path="$(wslpath -w "${cert_path}")" || return 1
  windows_cert_path="${windows_cert_path//\'/\'\'}"

  read -r -d '' powershell_script <<-EOT || true
		& {
		  \$certPath = '${windows_cert_path}'
		  if (-not (Test-Path \$certPath)) {
		    throw "Certificate path not found: \$certPath"
		  }

		  \$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2(\$certPath)
		  \$store = New-Object System.Security.Cryptography.X509Certificates.X509Store('Root', 'CurrentUser')
		  \$store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)

		  try {
		    \$existing = \$store.Certificates | Where-Object { \$_.Thumbprint -eq \$cert.Thumbprint }
		    if (\$existing) {
		      Write-Output 'present'
		      return
		    }

		    \$staleWardenRoots = @(
		      \$store.Certificates | Where-Object {
		        \$_.Thumbprint -ne \$cert.Thumbprint -and
		        \$_.Subject -like '*O=Warden.dev*' -and
		        \$_.Subject -like '*CN=Warden Proxy Local CA*'
		      }
		    )
		    foreach (\$staleCert in \$staleWardenRoots) {
		      \$store.Remove(\$staleCert)
		    }

		    \$store.Add(\$cert)
		    if (\$staleWardenRoots.Count -gt 0) {
		      Write-Output 'replaced'
		    } else {
		      Write-Output 'imported'
		    }
		  } finally {
		    \$store.Close()
		  }
		}
	EOT

  trust_status="$(powershell.exe -NoProfile -NonInteractive -Command "${powershell_script}" | tr -d '\r')" || return 1
  [[ "${trust_status}" =~ ^(present|imported|replaced)$ ]] || return 1

  echo "${trust_status}"
}

function installSshConfig () {
  if ! grep '## WARDEN START ##' /etc/ssh/ssh_config >/dev/null; then
    echo "==> Configuring sshd tunnel in host ssh_config (requires sudo privileges)"
    echo "    Note: This addition to the ssh_config file can sometimes be erased by a system"
    echo "    upgrade requiring reconfiguring the SSH config for tunnel.warden.test."
    cat <<-EOT | sudo tee -a /etc/ssh/ssh_config >/dev/null

			## WARDEN START ##
			Host tunnel.warden.test
			HostName 127.0.0.1
			User user
			Port 2222
			IdentityFile ~/.warden/tunnel/ssh_key
			## WARDEN END ##
			EOT
  fi
}

function assertWardenInstall {
  if [[ ! -f "${WARDEN_HOME_DIR}/.installed" ]] \
    || [[ "${WARDEN_HOME_DIR}/.installed" -ot "${WARDEN_DIR}/bin/warden" ]]
  then
    [[ -f "${WARDEN_HOME_DIR}/.installed" ]] && echo "==> Updating warden" || echo "==> Starting initialization"

    "${WARDEN_DIR}/bin/warden" install

    [[ -f "${WARDEN_HOME_DIR}/.installed" ]] && echo "==> Update complete" || echo "==> Initialization complete"
    date > "${WARDEN_HOME_DIR}/.installed"
  fi

  ## append settings for tunnel.warden.test in /etc/ssh/ssh_config
  #
  # NOTE: This function is called on every invocation of this assertion in an attempt to ensure
  # the ssh configuration for the tunnel is present following it's removal following a system
  # upgrade (macOS Catalina has been found to reset the global SSH configuration file)
  #

  installSshConfig
}
