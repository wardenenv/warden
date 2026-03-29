#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

source "${WARDEN_DIR}/utils/install.sh"

## Disable immediate exit on failure (set in main warden bin), we use this to detect whether docker is running and continue.
set +e

## Allow return codes from sub-process to bubble up normally, necessary for command testing
trap '' ERR

if [[ ${WARDEN_VERBOSE} -eq 1 ]]; then
    echo -e "\033[31mWarden doctor is in verbose mode and will output environment variables to to the terminal, please do not copy any sensitive environment variable values into a bug report.\033[0m\n"
fi

# The warden doctor command is designed to collect information useful in reasoning about the state of a system and configuration Warden is running on.
if [[ ${OSTYPE} =~ ^darwin ]]; then
    echo -e "\033[032mHost information:\033[0m"
    sw_vers --productName
    sw_vers --productVersion
fi
echo

echo -e "\033[32mOS, version, architecture:\033[0m"
uname -orm
echo

command -v brew &>/dev/null
if [[ $? -eq 0 ]]; then
    echo -e "\033[32mHomebrew information:\033[0m"
    brew config
fi
echo

echo -e "\033[32mContainer runtime and compose information:\033[0m"
docker --version
${DOCKER_COMPOSE_COMMAND} version
echo

echo -e "\033[32mWarden version:\033[0m"
${WARDEN_BIN} version
echo

echo -e "\033[32mWarden global .env:\033[0m"
cat ${WARDEN_HOME_DIR}/.env
echo

if [[ -f "${WARDEN_HOME_DIR}/.env" ]]; then
    eval "$(grep "^WARDEN_SERVICE_DOMAIN" "${WARDEN_HOME_DIR}/.env")"
    eval "$(grep "^WARDEN_DNS_OVER_HTTPS_ENABLE" "${WARDEN_HOME_DIR}/.env")"
fi
WARDEN_SERVICE_DOMAIN="${WARDEN_SERVICE_DOMAIN:-warden.test}"
WARDEN_DNS_OVER_HTTPS_ENABLE="${WARDEN_DNS_OVER_HTTPS_ENABLE:-0}"

function probeHttpsUrl() {
    local curl_bin="${1}"
    local url="${2}"
    local null_target="${3}"
    local http_code_file stderr_file
    local http_code stderr_output rc

    command -v "${curl_bin}" >/dev/null 2>&1 || {
        echo "unavailable"
        return 0
    }

    http_code_file="$(mktemp)" || return 1
    stderr_file="$(mktemp)" || {
        rm -f "${http_code_file}"
        return 1
    }

    "${curl_bin}" \
        --silent \
        --show-error \
        --output "${null_target}" \
        --write-out "%{http_code}" \
        --connect-timeout 5 \
        --max-time 10 \
        "${url}" >"${http_code_file}" 2>"${stderr_file}"
    rc=$?
    http_code="$(tr -d '\r\n' < "${http_code_file}")"
    stderr_output="$(tr -d '\r' < "${stderr_file}")"
    rm -f "${http_code_file}" "${stderr_file}"

    if [[ ${rc} -eq 0 ]] && [[ "${http_code}" =~ ^[0-9]{3}$ ]] && [[ "${http_code}" != "000" ]]; then
        echo "reachable_${http_code}"
        return 0
    fi

    if [[ "${stderr_output}" == *"Could not resolve host"* ]] || [[ "${stderr_output}" == *"could not be resolved"* ]]; then
        echo "dns_failed"
    elif [[ ${rc} -eq 35 ]] || [[ ${rc} -eq 51 ]] || [[ ${rc} -eq 58 ]] || [[ ${rc} -eq 59 ]] || [[ ${rc} -eq 60 ]] || [[ "${stderr_output}" == *"SSL"* ]] || [[ "${stderr_output}" == *"certificate"* ]] || [[ "${stderr_output}" == *"schannel"* ]]; then
        echo "tls_failed"
    elif [[ ${rc} -eq 7 ]] || [[ ${rc} -eq 28 ]] || [[ ${rc} -eq 52 ]] || [[ ${rc} -eq 56 ]] || [[ "${stderr_output}" == *"Failed to connect"* ]] || [[ "${stderr_output}" == *"Connection refused"* ]] || [[ "${stderr_output}" == *"timed out"* ]] || [[ "${stderr_output}" == *"forcibly closed"* ]]; then
        echo "connect_failed"
    else
        echo "error_${rc}"
    fi
}

function formatHttpsProbeResult() {
    local label="${1}"
    local result="${2}"
    local expected_code="${3:-}"
    local actual_code

    case "${result}" in
        reachable_*)
            actual_code="${result#reachable_}"
            if [[ -n "${expected_code}" ]] && [[ "${actual_code}" != "${expected_code}" ]]; then
                echo -e "\033[33m${label}: reachable (${actual_code}, expected ${expected_code})\033[0m"
            else
                echo -e "\033[33m${label}: reachable (${actual_code})\033[0m"
            fi
            ;;
        disabled)
            echo -e "\033[33m${label}: disabled\033[0m"
            ;;
        unavailable)
            echo -e "\033[33m${label}: unavailable\033[0m"
            ;;
        dns_failed)
            echo -e "\033[31m${label}: DNS failed\033[0m"
            ;;
        tls_failed)
            echo -e "\033[31m${label}: TLS failed\033[0m"
            ;;
        connect_failed)
            echo -e "\033[31m${label}: connection failed\033[0m"
            ;;
        error_*)
            echo -e "\033[31m${label}: failed (${result#error_})\033[0m"
            ;;
        *)
            echo -e "\033[33m${label}: ${result}\033[0m"
            ;;
    esac
}

function probeHostDnsResolution() {
    local hostname="${1}"
    local result

    if command -v getent >/dev/null 2>&1; then
        result="$(getent ahostsv4 "${hostname}" 2>/dev/null | awk 'NR==1 {print $1}')"
        if [[ -n "${result}" ]]; then
            echo "resolved_${result}"
            return 0
        fi

        result="$(getent hosts "${hostname}" 2>/dev/null | awk 'NR==1 {print $1}')"
        if [[ -n "${result}" ]]; then
            echo "resolved_${result}"
            return 0
        fi

        echo "failed"
        return 0
    fi

    if command -v host >/dev/null 2>&1; then
        result="$(host "${hostname}" 2>/dev/null | awk '/has address/ {print $NF; exit}')"
        if [[ -n "${result}" ]]; then
            echo "resolved_${result}"
            return 0
        fi

        echo "failed"
        return 0
    fi

    echo "unavailable"
}

function formatDnsProbeResult() {
    local label="${1}"
    local result="${2}"

    case "${result}" in
        resolved_*)
            echo -e "\033[33m${label}: resolved (${result#resolved_})\033[0m"
            ;;
        failed)
            echo -e "\033[31m${label}: failed\033[0m"
            ;;
        unavailable)
            echo -e "\033[33m${label}: unavailable\033[0m"
            ;;
        *)
            echo -e "\033[33m${label}: ${result}\033[0m"
            ;;
    esac
}

function formatCertificateProbeResult() {
    local label="${1}"
    local result="${2}"
    local actual_code

    case "${result}" in
        reachable_*)
            actual_code="${result#reachable_}"
            echo -e "\033[33m${label}: trusted (${actual_code})\033[0m"
            ;;
        tls_failed)
            echo -e "\033[31m${label}: warning (TLS validation failed)\033[0m"
            ;;
        dns_failed)
            echo -e "\033[31m${label}: unavailable (DNS failed)\033[0m"
            ;;
        connect_failed)
            echo -e "\033[31m${label}: unavailable (connection failed)\033[0m"
            ;;
        unavailable)
            echo -e "\033[33m${label}: unavailable\033[0m"
            ;;
        error_*)
            echo -e "\033[31m${label}: unavailable (${result#error_})\033[0m"
            ;;
        *)
            echo -e "\033[33m${label}: ${result}\033[0m"
            ;;
    esac
}

if hasWindowsBridge; then
    echo -e "\033[32mWindows Warden root certificate store state:\033[0m"
    windows_store_state="$(getWindowsRootCaStoreState "${WARDEN_HOME_DIR}/ssl/rootca/certs/ca.cert.pem")"
    case "${windows_store_state}" in
        *"LocalMachine=present"* ) echo -e "\033[33mWindows LocalMachine Root: present\033[0m" ;;
        *"LocalMachine=missing"* ) echo -e "\033[31mWindows LocalMachine Root: missing\033[0m" ;;
        *"LocalMachine=unreadable"* ) echo -e "\033[31mWindows LocalMachine Root: unreadable\033[0m" ;;
    esac
    case "${windows_store_state}" in
        *"CurrentUser=present"* ) echo -e "\033[33mWindows CurrentUser Root: present\033[0m" ;;
        *"CurrentUser=missing"* ) echo -e "\033[31mWindows CurrentUser Root: missing\033[0m" ;;
        *"CurrentUser=unreadable"* ) echo -e "\033[31mWindows CurrentUser Root: unreadable\033[0m" ;;
    esac

    windows_doh_state="$(getWindowsDohTemplateState "${WARDEN_SERVICE_DOMAIN}")"
    case "$(getWindowsStatusValue "${windows_doh_state}" "State")" in
        present ) echo -e "\033[33mWindows DoH for 127.0.0.1: present ($(getWindowsStatusValue "${windows_doh_state}" "Template"))\033[0m" ;;
        different ) echo -e "\033[33mWindows DoH for 127.0.0.1: differs ($(getWindowsStatusValue "${windows_doh_state}" "Template"))\033[0m" ;;
        missing ) echo -e "\033[33mWindows DoH for 127.0.0.1: missing\033[0m" ;;
    esac

    windows_hosts_state="$(getWindowsManagedHostsState "${WARDEN_SERVICE_DOMAIN}")"
    case "$(getWindowsStatusValue "${windows_hosts_state}" "State")" in
        present ) echo -e "\033[33mWindows Warden hosts block: present\033[0m" ;;
        different ) echo -e "\033[33mWindows Warden hosts block: differs\033[0m" ;;
        missing ) echo -e "\033[33mWindows Warden hosts block: missing\033[0m" ;;
    esac
    windows_hosts_entries="$(getWindowsStatusValue "${windows_hosts_state}" "Entries")"
    if [[ -n "${windows_hosts_entries}" ]]; then
        echo -e "\033[33mWindows Warden hosts entries: ${windows_hosts_entries//|/, }\033[0m"
    fi
    echo
fi

echo -e "\033[32mDNS diagnostics:\033[0m"
random_wildcard_host="warden-doctor-$(date +%s)-${RANDOM}.${WARDEN_SERVICE_DOMAIN}"

host_traefik_probe="$(probeHttpsUrl "curl" "https://traefik.${WARDEN_SERVICE_DOMAIN}/" "/dev/null")"
formatHttpsProbeResult "Host traefik HTTPS" "${host_traefik_probe}"

host_webmail_probe="$(probeHttpsUrl "curl" "https://webmail.${WARDEN_SERVICE_DOMAIN}/" "/dev/null")"
formatHttpsProbeResult "Host webmail HTTPS" "${host_webmail_probe}"

if [[ "${WARDEN_DNS_OVER_HTTPS_ENABLE}" == "1" ]]; then
    host_doh_probe="$(probeHttpsUrl "curl" "https://doh.${WARDEN_SERVICE_DOMAIN}/dns-query" "/dev/null")"
    formatHttpsProbeResult "Host DoH endpoint" "${host_doh_probe}" "400"
else
    formatHttpsProbeResult "Host DoH endpoint" "disabled"
fi

host_wildcard_probe="$(probeHttpsUrl "curl" "https://${random_wildcard_host}/" "/dev/null")"
formatHttpsProbeResult "Host wildcard HTTPS" "${host_wildcard_probe}" "404"

host_dns_probe="$(probeHostDnsResolution "${random_wildcard_host}")"
formatDnsProbeResult "Host DNS-only lookup" "${host_dns_probe}"

host_trafik_tls_probe="${host_traefik_probe}"

if hasWindowsBridge; then
    if [[ "${WARDEN_DNS_OVER_HTTPS_ENABLE}" == "1" ]]; then
        windows_doh_probe="$(probeHttpsUrl "curl.exe" "https://doh.${WARDEN_SERVICE_DOMAIN}/dns-query" "NUL")"
        formatHttpsProbeResult "Windows DoH endpoint" "${windows_doh_probe}" "400"
    else
        formatHttpsProbeResult "Windows DoH endpoint" "disabled"
    fi

    windows_wildcard_probe="$(probeHttpsUrl "curl.exe" "https://${random_wildcard_host}/" "NUL")"
    formatHttpsProbeResult "Windows wildcard HTTPS" "${windows_wildcard_probe}" "404"

    windows_dns_probe="$(probeWindowsDnsResolution "${random_wildcard_host}")"
    case "$(getWindowsStatusValue "${windows_dns_probe}" "State")" in
        resolved)
            echo -e "\033[33mWindows DNS-only lookup: resolved ($(getWindowsStatusValue "${windows_dns_probe}" "Result"))\033[0m"
            ;;
        failed)
            windows_dns_message="$(getWindowsStatusValue "${windows_dns_probe}" "Message")"
            if [[ -n "${windows_dns_message}" ]]; then
                echo -e "\033[31mWindows DNS-only lookup: failed (${windows_dns_message})\033[0m"
            else
                echo -e "\033[31mWindows DNS-only lookup: failed\033[0m"
            fi
            ;;
        *)
            echo -e "\033[33mWindows DNS-only lookup: unavailable\033[0m"
            ;;
    esac
    windows_traefik_tls_probe="$(probeHttpsUrl "curl.exe" "https://traefik.${WARDEN_SERVICE_DOMAIN}/" "NUL")"
else
    formatHttpsProbeResult "Windows DoH endpoint" "unavailable"
    formatHttpsProbeResult "Windows wildcard HTTPS" "unavailable"
    echo -e "\033[33mWindows DNS-only lookup: unavailable\033[0m"
    windows_traefik_tls_probe="unavailable"
fi
echo

echo -e "\033[32mTLS certificate diagnostics:\033[0m"
formatCertificateProbeResult "Host traefik certificate" "${host_trafik_tls_probe}"
formatCertificateProbeResult "Windows traefik certificate" "${windows_traefik_tls_probe}"
echo

echo -e "\033[32mWarden service override via Docker compose file:\033[0m"
if [[ -f ${WARDEN_HOME_DIR}/docker-compose.yml ]]; then
    echo -e "\033[33mWarden services have additional service configuration added or overridden via ${WARDEN_HOME_DIR}/docker-compose.yml file.\033[0m"
else
    echo -e "\033[33mWarden services do not appear to be overridden via ${WARDEN_HOME_DIR}/docker-compose.yml file.\033[0m"
fi
echo

echo -e "\033[32mWarden service override via ${WARDEN_HOME_DIR}/warden-env.yml partial:\033[0m"
if [[ -f ${WARDEN_HOME_DIR}/warden-env.yml ]]; then
    echo -e "\033[33mWarden services have additional service configuration added or overridden via ${WARDEN_HOME_DIR}/warden-env.yml partial.\033[0m"
else
    echo -e "\033[33mWarden services do not appear to be overridden via ${WARDEN_HOME_DIR}/warden-env.yml partial.\033[0m"
fi
echo

echo -e "\033[32mWarden project .env:\033[0m"
if [[ -f ./.env ]]; then
    echo -e "\033[33mWarden project directory, detected.\033[0m"
    if [[ ${WARDEN_VERBOSE} -eq 1 ]]; then
        cat ./.env
    fi
else
    echo -e "\033[33mNot currently in a Warden project directory, no ./.env is present.\033[0m"
fi
echo

echo -e "\033[32mWarden project override via ./.warden/warden-env.yml:\033[0m"
if [[ -f ./.warden/warden-env.yml ]]; then
    cat ./.warden/warden-env.yml
else
    echo -e "\033[33mWarden and project services do not appear to be overridden via project level override ./.warden/warden-env.yml.\033[0m"
fi
echo

docker stats --no-stream &>/dev/null
# Docker is required to be running for the next set of commands
if [[ $? -eq 0 ]]; then
    echo -e "\033[32mWarden image, tag and architecture:\033[0m"

    WARDEN_IMAGES=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -i wardenenv)
    for img in ${WARDEN_IMAGES}; do
        echo $img:$(docker image inspect $img --format "{{.Architecture}}");
    done
    echo

    echo -e "\033[32mWarden environments and service configuration files:\033[0m"
    command -v jq >/dev/null
    if [[ $? -eq 0 ]]
    then
        ${WARDEN_BIN} svc ls -a --format json | jq '.[] | (.Name + " - " + .Status), (.ConfigFiles | split(","))'
    else
        ${WARDEN_BIN} svc ls -a --format table
    fi
    echo

    echo -e "\033[32mWarden status:\033[0m"
    ${WARDEN_BIN} status
else
    echo "Docker does not appear to be running. Start Docker and re-run this command to see Warden images, tags and architecture."
fi
echo

command -v mutagen &>/dev/null
if [[ $? -eq 0 ]]; then
    echo -e "\033[32mMutagen sync list\033[0m"
    mutagen sync list
fi
echo
