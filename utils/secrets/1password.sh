#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

function resolveOpItemsPath {
    echo "${WARDEN_ENV_PATH}/.env.op"
}

function secretsProviderRequireConfig {
    local itemsPath
    itemsPath="$(resolveOpItemsPath)"

    if [[ -n "${WARDEN_OP_ENVIRONMENT_ID:-}" ]] && [[ -f "${itemsPath}" ]]; then
        warning "Both WARDEN_OP_ENVIRONMENT_ID and .env.op are configured; use one of them. Skipping secret injection."
        return 1
    fi

    if [[ -n "${WARDEN_OP_ENVIRONMENT_ID:-}" ]]; then
        if [[ ! "${WARDEN_OP_ENVIRONMENT_ID}" =~ ^[A-Za-z0-9_-]+$ ]]; then
            warning "WARDEN_OP_ENVIRONMENT_ID is not a valid 1Password Environment ID; skipping secret injection."
            return 1
        fi

        return 0
    fi

    if [[ ! -f "${itemsPath}" ]]; then
        warning "Set WARDEN_OP_ENVIRONMENT_ID or add a .env.op file with secret references; skipping secret injection."
        return 1
    fi
}

function secretsProviderRead {
    if ! command -v op >/dev/null 2>&1; then
        warning "1Password CLI (op) could not be found; skipping secret injection."
        return 1
    fi

    if [[ -z "${WARDEN_OP_ENVIRONMENT_ID:-}" ]]; then
        readOpItems
        return $?
    fi

    local opArgs=(environment read "${WARDEN_OP_ENVIRONMENT_ID}" --no-masking)
    [[ -n "${WARDEN_OP_ACCOUNT:-}" ]] && opArgs+=(--account "${WARDEN_OP_ACCOUNT}")

    local output line
    if ! output="$(op "${opArgs[@]}")"; then
        warning "Could not read 1Password Environment '${WARDEN_OP_ENVIRONMENT_ID}' (Environments require 1Password CLI 2.33.0-beta.02 or later); skipping secret injection."
        return 1
    fi

    while IFS= read -r line || [[ -n "${line}" ]]; do
        line="${line%$'\r'}"
        if [[ "${line}" =~ ^[A-Za-z_][A-Za-z0-9_]*=(.*)$ ]] \
            && [[ "${BASH_REMATCH[1]}" == "<concealed by 1Password>" ]]
        then
            warning "1Password returned masked values; skipping secret injection."
            return 1
        fi
    done <<< "${output}"

    printf '%s\n' "${output}"
}

function readOpItems {
    local itemsPath
    itemsPath="$(resolveOpItemsPath)"

    local line lineno=0 key value
    local -a ignored=() keys=() refs=()

    while IFS= read -r line || [[ -n "${line}" ]]; do
        lineno=$(( lineno + 1 ))
        line="${line%$'\r'}"
        [[ -z "${line}" ]] && continue
        [[ "${line}" =~ ^[[:space:]]*# ]] && continue

        if [[ "${line}" != *=* ]]; then
            ignored+=("${lineno}")
            continue
        fi

        key="${line%%=*}"
        value="${line#*=}"

        if [[ ! "${key}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
            ignored+=("${lineno}")
            continue
        fi

        if [[ "${value}" =~ ^\"(.*)\"$ ]] || [[ "${value}" =~ ^\'(.*)\'$ ]]; then
            value="${BASH_REMATCH[1]}"
        fi

        if [[ "${value}" != op://* ]] || [[ "${value}" =~ [[:cntrl:]] ]]; then
            ignored+=("${lineno}")
            continue
        fi

        keys+=("${key}")
        refs+=("${value}")
    done < "${itemsPath}"

    if (( ${#ignored[@]} > 0 )); then
        warning "Ignored .env.op lines that are not KEY=op://… references: ${ignored[*]}"
    fi

    local readValue
    local -a outKeys=() outValues=() lineBreakKeys=()
    local i
    for (( i = 0; i < ${#keys[@]}; i++ )); do
        local opArgs=(read --no-newline)
        [[ -n "${WARDEN_OP_ACCOUNT:-}" ]] && opArgs+=(--account "${WARDEN_OP_ACCOUNT}")
        opArgs+=("${refs[$i]}")

        if ! readValue="$(op "${opArgs[@]}")"; then
            warning "Could not read 1Password secret reference for ${keys[$i]}; skipping secret injection."
            return 1
        fi

        if [[ "${readValue}" == *$'\n'* || "${readValue}" == *$'\r'* ]]; then
            lineBreakKeys+=("${keys[$i]}")
            continue
        fi

        outKeys+=("${keys[$i]}")
        outValues+=("${readValue}")
    done

    if (( ${#lineBreakKeys[@]} > 0 )); then
        warning "1Password values with line breaks cannot be injected and were skipped: ${lineBreakKeys[*]}"
    fi

    for (( i = 0; i < ${#outKeys[@]}; i++ )); do
        printf '%s=%s\n' "${outKeys[$i]}" "${outValues[$i]}"
    done
}
