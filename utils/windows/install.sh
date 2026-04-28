#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

# WSL/Windows bridge helpers used by install and doctor flows.

WINDOWS_MANAGED_HOSTS_BLOCK_START="# WARDEN WINDOWS HOSTS START"
WINDOWS_MANAGED_HOSTS_BLOCK_END="# WARDEN WINDOWS HOSTS END"

function isWsl () {
  command -v wslpath >/dev/null 2>&1 || return 1

  [[ -n "${WSL_DISTRO_NAME:-}" ]] && wslpath -w . >/dev/null 2>&1 && return 0
  [[ -r /proc/sys/kernel/osrelease ]] && grep -qiE '(microsoft|wsl)' /proc/sys/kernel/osrelease && wslpath -w . >/dev/null 2>&1 && return 0
  [[ -r /proc/version ]] && grep -qiE '(microsoft|wsl)' /proc/version && wslpath -w . >/dev/null 2>&1 && return 0
  return 1
}

function hasWindowsBridge () {
  isWsl && command -v powershell.exe >/dev/null 2>&1
}

function runWindowsPowerShellScript () {
  local script_path="${1}"
  shift

  powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "${script_path}" "$@" | tr -d '\r'
}

function toWindowsPath () {
  wslpath -w "$(realpath "${1}")"
}

function sendWindowsNotification () {
  local title="${1}"
  local message="${2}"
  local level="${3:-Info}"

  hasWindowsBridge || return 0

  powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden \
    -File "$(toWindowsPath "${WARDEN_DIR}/utils/windows/show-notification.ps1")" \
    -Title "${title}" \
    -Message "${message}" \
    -Level "${level}" >/dev/null 2>&1 || true
}

function getWindowsStatusValue () {
  local status_output="${1}"
  local key="${2}"

  printf '%s\n' "${status_output}" | sed -n "s/^${key}=//p" | head -n 1
}

function getWindowsGlobalHostsEntries () {
  local service_domain="${1}"

  printf '%s\n' \
    "127.0.0.1 traefik.${service_domain}" \
    "127.0.0.1 dnsmasq.${service_domain}" \
    "127.0.0.1 doh.${service_domain}" \
    "127.0.0.1 webmail.${service_domain}"
}

function getWindowsCertificateThumbprint () {
  local cert_path="${1}"
  local windows_cert_path thumbprint

  [[ -f "${cert_path}" ]] || return 1

  windows_cert_path="$(wslpath -w "${cert_path}")" || return 1
  thumbprint="$(runWindowsPowerShellScript "$(toWindowsPath "${WARDEN_DIR}/utils/windows/get-certificate-thumbprint.ps1")" -CertificatePath "${windows_cert_path}")" || return 1
  [[ -n "${thumbprint}" ]] || return 1

  echo "${thumbprint}"
}

function getWindowsRootCaStoreState () {
  local cert_path="${1}"
  local windows_cert_path store_state

  [[ -f "${cert_path}" ]] || return 1

  windows_cert_path="$(wslpath -w "${cert_path}")" || return 1
  store_state="$(runWindowsPowerShellScript "$(toWindowsPath "${WARDEN_DIR}/utils/windows/get-root-store-state.ps1")" -CertificatePath "${windows_cert_path}")" || return 1
  [[ -n "${store_state}" ]] || return 1

  echo "${store_state}"
}

function getWindowsDohTemplateState () {
  local service_domain="${1}"
  local state_output
  local script_path

  script_path="$(toWindowsPath "${WARDEN_DIR}/utils/windows/get-doh-template-state.ps1")" || return 1
  state_output="$(runWindowsPowerShellScript "${script_path}" \
    -ServerAddress "127.0.0.1" \
    -DohTemplate "https://doh.${service_domain}/dns-query" \
    -AllowFallbackToUdp 0 \
    -AutoUpgrade 1)" || return 1
  [[ -n "${state_output}" ]] || return 1

  echo "${state_output}"
}

function getWindowsManagedHostsState () {
  local service_domain="${1}"
  local script_path state_output
  local host_entries=()
  local host_entries_text

  while IFS= read -r entry; do
    host_entries+=("${entry}")
  done < <(getWindowsGlobalHostsEntries "${service_domain}")
  host_entries_text="$(printf '%s|' "${host_entries[@]}")"
  host_entries_text="${host_entries_text%|}"

  script_path="$(toWindowsPath "${WARDEN_DIR}/utils/windows/get-managed-hosts-state.ps1")" || return 1
  state_output="$(runWindowsPowerShellScript "${script_path}" \
    -BlockStart "${WINDOWS_MANAGED_HOSTS_BLOCK_START}" \
    -BlockEnd "${WINDOWS_MANAGED_HOSTS_BLOCK_END}" \
    -EntriesText "${host_entries_text}")" || return 1
  [[ -n "${state_output}" ]] || return 1

  echo "${state_output}"
}

function probeWindowsDnsResolution () {
  local hostname="${1}"
  local script_path state_output

  script_path="$(toWindowsPath "${WARDEN_DIR}/utils/windows/test-dns-resolution.ps1")" || return 1
  state_output="$(runWindowsPowerShellScript "${script_path}" -Hostname "${hostname}")" || return 1
  [[ -n "${state_output}" ]] || return 1

  echo "${state_output}"
}

function trustRootCaInWindowsStore () {
  local cert_path="${1}"
  local store_location="${2}"
  local windows_cert_path trust_status

  [[ -f "${cert_path}" ]] || return 1
  [[ "${store_location}" =~ ^(CurrentUser|LocalMachine)$ ]] || return 1

  windows_cert_path="$(wslpath -w "${cert_path}")" || return 1
  trust_status="$(runWindowsPowerShellScript "$(toWindowsPath "${WARDEN_DIR}/utils/windows/trust-root-store.ps1")" -CertificatePath "${windows_cert_path}" -StoreLocation "${store_location}")" || return 1
  [[ "${trust_status}" =~ ^(present|imported|replaced|access_denied|policy_blocked|store_error)$ ]] || return 1

  echo "${trust_status}"
}

function installWindowsDohTemplate () {
  local service_domain="${1}"
  local state_output state script_path install_status

  state_output="$(getWindowsDohTemplateState "${service_domain}")" || return 1
  state="$(getWindowsStatusValue "${state_output}" "State")"

  if [[ "${state}" == "present" ]]; then
    echo "==> Windows DoH template already registered for 127.0.0.1"
    sendWindowsNotification "Warden DoH" "Windows DNS over HTTPS is already registered for 127.0.0.1." "Info"
    return 0
  fi

  echo "==> Registering Windows DoH template for 127.0.0.1"
  script_path="$(toWindowsPath "${WARDEN_DIR}/utils/windows/install-doh-template-elevated.ps1")" || return 1
  install_status="$(runWindowsPowerShellScript "${script_path}" \
    -ServerAddress "127.0.0.1" \
    -DohTemplate "https://doh.${service_domain}/dns-query" \
    -AllowFallbackToUdp 0 \
    -AutoUpgrade 1)" || return 1

  case "${install_status}" in
    installed)
      echo "==> Windows DoH template registered for 127.0.0.1"
      sendWindowsNotification "Warden DoH" "Windows DNS over HTTPS was registered for 127.0.0.1." "Info"
      ;;
    updated)
      echo "==> Windows DoH template updated for 127.0.0.1"
      sendWindowsNotification "Warden DoH" "Windows DNS over HTTPS was updated for 127.0.0.1." "Info"
      ;;
    elevation_cancelled)
      warning "Administrator approval was canceled while registering the Warden Windows DoH template."
      sendWindowsNotification "Warden DoH" "Administrator approval was canceled while registering Windows DNS over HTTPS." "Warning"
      ;;
    elevation_failed)
      warning "Unable to register the Warden Windows DoH template automatically."
      sendWindowsNotification "Warden DoH" "Unable to register Windows DNS over HTTPS automatically." "Warning"
      ;;
    *)
      return 1
      ;;
  esac
}

function installWindowsGlobalHosts () {
  local service_domain="${1}"
  local state_output state script_path install_status
  local host_entries=()
  local host_entries_text

  state_output="$(getWindowsManagedHostsState "${service_domain}")" || return 1
  state="$(getWindowsStatusValue "${state_output}" "State")"

  if [[ "${state}" == "present" ]]; then
    echo "==> Windows hosts entries already present for Warden global services"
    sendWindowsNotification "Warden Hosts" "Windows hosts entries are already present for Warden global services." "Info"
    return 0
  fi

  while IFS= read -r entry; do
    host_entries+=("${entry}")
  done < <(getWindowsGlobalHostsEntries "${service_domain}")
  host_entries_text="$(printf '%s|' "${host_entries[@]}")"
  host_entries_text="${host_entries_text%|}"

  echo "==> Installing Windows hosts entries for Warden global services"
  script_path="$(toWindowsPath "${WARDEN_DIR}/utils/windows/install-managed-hosts-elevated.ps1")" || return 1
  install_status="$(runWindowsPowerShellScript "${script_path}" \
    -BlockStart "${WINDOWS_MANAGED_HOSTS_BLOCK_START}" \
    -BlockEnd "${WINDOWS_MANAGED_HOSTS_BLOCK_END}" \
    -EntriesText "${host_entries_text}")" || return 1

  case "${install_status}" in
    installed)
      echo "==> Windows hosts entries installed for Warden global services"
      sendWindowsNotification "Warden Hosts" "Windows hosts entries were installed for Warden global services." "Info"
      ;;
    updated)
      echo "==> Windows hosts entries updated for Warden global services"
      sendWindowsNotification "Warden Hosts" "Windows hosts entries were updated for Warden global services." "Info"
      ;;
    present)
      echo "==> Windows hosts entries already present for Warden global services"
      sendWindowsNotification "Warden Hosts" "Windows hosts entries are already present for Warden global services." "Info"
      ;;
    elevation_cancelled)
      warning "Administrator approval was canceled while updating the Windows hosts file for Warden."
      sendWindowsNotification "Warden Hosts" "Administrator approval was canceled while updating the Windows hosts file for Warden." "Warning"
      ;;
    elevation_failed)
      warning "Unable to update the Windows hosts file for Warden automatically."
      sendWindowsNotification "Warden Hosts" "Unable to update the Windows hosts file for Warden automatically." "Warning"
      ;;
    *)
      return 1
      ;;
  esac
}

function trustRootCaInWindowsLocalMachineElevated () {
  local cert_path="${1}"
  local windows_cert_path cert_thumbprint elevate_status
  local elevated_script_path import_script_path

  [[ -f "${cert_path}" ]] || return 1

  windows_cert_path="$(wslpath -w "${cert_path}")" || return 1
  cert_thumbprint="$(getWindowsCertificateThumbprint "${cert_path}")" || return 1
  elevated_script_path="$(toWindowsPath "${WARDEN_DIR}/utils/windows/import-root-localmachine-elevated.ps1")" || return 1
  import_script_path="$(toWindowsPath "${WARDEN_DIR}/utils/windows/import-root-localmachine.ps1")" || return 1

  elevate_status="$(runWindowsPowerShellScript "${elevated_script_path}" \
    -CertificatePath "${windows_cert_path}" \
    -Thumbprint "${cert_thumbprint}" \
    -ImportScriptPath "${import_script_path}")" || return 1
  [[ "${elevate_status}" =~ ^(imported|elevation_cancelled|elevation_failed|policy_blocked)$ ]] || return 1

  echo "${elevate_status}"
}

function trustRootCaInWindows () {
  local cert_path="${1}"
  local local_machine_status elevated_status current_user_status

  local_machine_status="$(trustRootCaInWindowsStore "${cert_path}" "LocalMachine")" || return 1

  if [[ "${local_machine_status}" == "policy_blocked" ]] || [[ "${local_machine_status}" == "store_error" ]]; then
    current_user_status="$(trustRootCaInWindowsStore "${cert_path}" "CurrentUser")" || return 1
    echo "localmachine_${local_machine_status}_${current_user_status}"
  elif [[ "${local_machine_status}" == "access_denied" ]]; then
    elevated_status="$(trustRootCaInWindowsLocalMachineElevated "${cert_path}")" || return 1
    if [[ "${elevated_status}" == "imported" ]]; then
      echo "localmachine_imported_via_elevation"
      return 0
    fi

    current_user_status="$(trustRootCaInWindowsStore "${cert_path}" "CurrentUser")" || return 1
    echo "localmachine_${elevated_status}_${current_user_status}"
  else
    echo "localmachine_${local_machine_status}"
  fi
}

function installWindowsRootCa () {
  local cert_path="${1}"
  local windows_trust_status

  echo "==> Trusting root certificate in Windows Root store"
  if ! windows_trust_status="$(trustRootCaInWindows "${cert_path}")"; then
    warning "Unable to trust the Warden root certificate in Windows. Windows browsers may continue to warn until it is imported manually."
    sendWindowsNotification "Warden Certificate" "Unable to trust the Warden root certificate in Windows. Manual import may still be required." "Error"
    return 0
  fi

  case "${windows_trust_status}" in
    localmachine_present)
      echo "==> Root certificate already present in Windows LocalMachine Root store"
      ;;
    localmachine_imported)
      echo "==> Root certificate imported into Windows LocalMachine Root store"
      sendWindowsNotification "Warden Certificate" "Warden root certificate installed in Windows LocalMachine Root." "Info"
      ;;
    localmachine_replaced)
      echo "==> Root certificate replaced in Windows LocalMachine Root store"
      sendWindowsNotification "Warden Certificate" "Warden root certificate was rotated in Windows LocalMachine Root." "Info"
      ;;
    localmachine_imported_via_elevation)
      echo "==> Root certificate imported into Windows LocalMachine Root store after administrator approval"
      sendWindowsNotification "Warden Certificate" "Warden root certificate installed in Windows LocalMachine Root after administrator approval." "Info"
      ;;
    localmachine_policy_blocked_present)
      warning "Windows policy may be preventing installation of the Warden root certificate into Windows LocalMachine Root. The certificate is already present in Windows CurrentUser Root store. Contact your administrator if Windows system services still reject the certificate."
      sendWindowsNotification "Warden Certificate" "Windows policy may be preventing LocalMachine Root installation. The certificate is present in CurrentUser Root." "Warning"
      ;;
    localmachine_policy_blocked_imported)
      warning "Windows policy may be preventing installation of the Warden root certificate into Windows LocalMachine Root. Imported into Windows CurrentUser Root store instead. Contact your administrator if Windows system services still reject the certificate."
      sendWindowsNotification "Warden Certificate" "Windows policy may be preventing LocalMachine Root installation. The certificate was imported into CurrentUser Root instead." "Warning"
      ;;
    localmachine_policy_blocked_replaced)
      warning "Windows policy may be preventing installation of the Warden root certificate into Windows LocalMachine Root. Replaced in Windows CurrentUser Root store instead. Contact your administrator if Windows system services still reject the certificate."
      sendWindowsNotification "Warden Certificate" "Windows policy may be preventing LocalMachine Root installation. The certificate was rotated in CurrentUser Root instead." "Warning"
      ;;
    localmachine_store_error_present)
      warning "Windows rejected installation of the Warden root certificate into Windows LocalMachine Root for a reason other than access denial. The certificate is already present in Windows CurrentUser Root store. Windows policy or endpoint security may be blocking this operation."
      sendWindowsNotification "Warden Certificate" "Windows rejected LocalMachine Root installation. The certificate is present in CurrentUser Root." "Warning"
      ;;
    localmachine_store_error_imported)
      warning "Windows rejected installation of the Warden root certificate into Windows LocalMachine Root for a reason other than access denial. Imported into Windows CurrentUser Root store instead. Windows policy or endpoint security may be blocking this operation."
      sendWindowsNotification "Warden Certificate" "Windows rejected LocalMachine Root installation. The certificate was imported into CurrentUser Root instead." "Warning"
      ;;
    localmachine_store_error_replaced)
      warning "Windows rejected installation of the Warden root certificate into Windows LocalMachine Root for a reason other than access denial. Replaced in Windows CurrentUser Root store instead. Windows policy or endpoint security may be blocking this operation."
      sendWindowsNotification "Warden Certificate" "Windows rejected LocalMachine Root installation. The certificate was rotated in CurrentUser Root instead." "Warning"
      ;;
    localmachine_elevation_cancelled_present)
      warning "Administrator approval was canceled while importing the Warden root certificate into Windows LocalMachine Root. The certificate is already present in Windows CurrentUser Root store."
      sendWindowsNotification "Warden Certificate" "Administrator approval was canceled. The certificate is already present in Windows CurrentUser Root." "Warning"
      ;;
    localmachine_elevation_cancelled_imported)
      warning "Administrator approval was canceled while importing the Warden root certificate into Windows LocalMachine Root. Imported into Windows CurrentUser Root store instead."
      sendWindowsNotification "Warden Certificate" "Administrator approval was canceled. The certificate was imported into Windows CurrentUser Root instead." "Warning"
      ;;
    localmachine_elevation_cancelled_replaced)
      warning "Administrator approval was canceled while importing the Warden root certificate into Windows LocalMachine Root. Replaced in Windows CurrentUser Root store instead."
      sendWindowsNotification "Warden Certificate" "Administrator approval was canceled. The certificate was rotated in Windows CurrentUser Root instead." "Warning"
      ;;
    localmachine_elevation_failed_present)
      warning "Administrator-approved import into Windows LocalMachine Root did not complete successfully. The certificate is already present in Windows CurrentUser Root store."
      sendWindowsNotification "Warden Certificate" "Administrator-approved import into Windows LocalMachine Root did not complete. The certificate is already present in Windows CurrentUser Root." "Warning"
      ;;
    localmachine_elevation_failed_imported)
      warning "Administrator-approved import into Windows LocalMachine Root did not complete successfully. Imported into Windows CurrentUser Root store instead."
      sendWindowsNotification "Warden Certificate" "Administrator-approved import into Windows LocalMachine Root did not complete. The certificate was imported into Windows CurrentUser Root instead." "Warning"
      ;;
    localmachine_elevation_failed_replaced)
      warning "Administrator-approved import into Windows LocalMachine Root did not complete successfully. Replaced in Windows CurrentUser Root store instead."
      sendWindowsNotification "Warden Certificate" "Administrator-approved import into Windows LocalMachine Root did not complete. The certificate was rotated in Windows CurrentUser Root instead." "Warning"
      ;;
    localmachine_policy_blocked_unreadable|localmachine_store_error_unreadable)
      warning "Windows policy or endpoint security may be preventing Warden from checking or updating Windows CurrentUser Root after the LocalMachine Root install was blocked."
      ;;
  esac
}
