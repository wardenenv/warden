#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

function secretsProviderRequireConfig {
    WARDEN_VAULT_MOUNT="${WARDEN_VAULT_MOUNT:-secret}"

    if [[ ! "${WARDEN_VAULT_PATH:-}" =~ ^[A-Za-z0-9_./-]+$ ]] \
        || [[ "${WARDEN_VAULT_PATH}" == *".."* ]] \
        || [[ "${WARDEN_VAULT_PATH}" == /* ]]
    then
        warning "WARDEN_VAULT_PATH is not a valid Vault secret path; skipping secret injection."
        return 1
    fi

    if [[ ! "${WARDEN_VAULT_MOUNT}" =~ ^[A-Za-z0-9_-]+$ ]]; then
        warning "WARDEN_VAULT_MOUNT is not a valid Vault mount; skipping secret injection."
        return 1
    fi

    if [[ -n "${WARDEN_VAULT_NAMESPACE:-}" ]] && [[ ! "${WARDEN_VAULT_NAMESPACE}" =~ ^[A-Za-z0-9_./-]+$ ]]; then
        warning "WARDEN_VAULT_NAMESPACE is not a valid Vault namespace; skipping secret injection."
        return 1
    fi

    if [[ -n "${WARDEN_VAULT_ADDR:-}" ]] && [[ ! "${WARDEN_VAULT_ADDR}" =~ ^https?://[A-Za-z0-9.-]+(:[0-9]+)?(/.*)?$ ]]; then
        warning "WARDEN_VAULT_ADDR is not a valid Vault address; skipping secret injection."
        return 1
    fi
}

## KV v2 wraps the pairs under .data.data with a sibling .data.metadata; KV v1
## keeps them directly under .data
function secretsProviderRead {
    if ! command -v vault >/dev/null 2>&1; then
        warning "Vault CLI (vault) could not be found; skipping secret injection."
        return 1
    fi

    if ! command -v jq >/dev/null 2>&1; then
        warning "jq could not be found; skipping secret injection."
        return 1
    fi

    local vaultArgs=(kv get -format=json "-mount=${WARDEN_VAULT_MOUNT}")
    [[ -n "${WARDEN_VAULT_ADDR:-}" ]] && vaultArgs+=("-address=${WARDEN_VAULT_ADDR}")
    [[ -n "${WARDEN_VAULT_NAMESPACE:-}" ]] && vaultArgs+=("-namespace=${WARDEN_VAULT_NAMESPACE}")
    vaultArgs+=("${WARDEN_VAULT_PATH}")

    local output secrets skipped
    if ! output="$(vault "${vaultArgs[@]}")"; then
        warning "Could not read Vault secret '${WARDEN_VAULT_MOUNT}/${WARDEN_VAULT_PATH}'; skipping secret injection."
        return 1
    fi

    local jqKV='
        def kv:
            if ((.data.data | type) == "object") and ((.data.metadata | type) == "object")
            then .data.data
            else .data
            end;
        def identkey: test("^[A-Za-z_][A-Za-z0-9_]*$");
        (kv // {}) | with_entries(select(.key | identkey))
    '

    if ! secrets="$(jq -r "${jqKV}"'
        | to_entries
        | map(select(
            (.value | type) as $t
            | ($t == "string" or $t == "number" or $t == "boolean")
              and (if $t == "string" then (.value | test("[\n\r]") | not) else true end)
        ))
        | .[]
        | "\(.key)=\(.value)"
    ' <<< "${output}")"; then
        warning "Could not parse the Vault secret '${WARDEN_VAULT_MOUNT}/${WARDEN_VAULT_PATH}'; skipping secret injection."
        return 1
    fi

    skipped="$(jq -r "${jqKV}"'
        | to_entries
        | map(select(
            (.value | type) as $t
            | ($t == "object" or $t == "array" or $t == "null")
              or ($t == "string" and (.value | test("[\n\r]")))
        ))
        | .[]
        | .key
    ' <<< "${output}" | tr '\n' ' ')"

    if [[ -n "${skipped}" ]]; then
        warning "Vault values that cannot be injected (objects, arrays, null or multiline strings) were skipped: ${skipped% }"
    fi

    printf '%s\n' "${secrets}"
}
