#!/usr/bin/env bash
# Bash completion for warden

_warden() {
    local cur prev words cword
    _init_completion || return

    # Resolve WARDEN_DIR from the warden binary location
    local warden_bin
    warden_bin="$(command -v warden 2>/dev/null)"
    local warden_dir=""
    if [[ -n "${warden_bin}" ]]; then
        local real_bin
        real_bin="$(readlink "${warden_bin}" 2>/dev/null || echo "${warden_bin}")"
        warden_dir="$(cd "$(dirname "${real_bin}")/.." 2>/dev/null && pwd)"
    fi

    local global_opts="-h --help -v --verbose"

    # Top-level: complete commands
    if [[ ${cword} -eq 1 ]]; then
        local commands=""
        if [[ -n "${warden_dir}" && -d "${warden_dir}/commands" ]]; then
            commands="$(ls "${warden_dir}/commands/"*.cmd 2>/dev/null \
                | xargs -I{} basename {} .cmd \
                | grep -v usage)"
        fi
        if [[ -z "${commands}" ]]; then
            commands="blackfire db debug doctor env env-init install redis shell sign-certificate spx status svc sync valkey version vnc"
        fi
        COMPREPLY=($(compgen -W "${commands} ${global_opts}" -- "${cur}"))
        return
    fi

    local cmd="${words[1]}"

    case "${cmd}" in
        db)
            if [[ ${cword} -eq 2 ]]; then
                COMPREPLY=($(compgen -W "connect import dump upgrade" -- "${cur}"))
            fi
            ;;
        sync)
            if [[ ${cword} -eq 2 ]]; then
                COMPREPLY=($(compgen -W "start stop list flush monitor pause reset resume" -- "${cur}"))
            fi
            ;;
        env|svc)
            if [[ ${cword} -eq 2 ]]; then
                COMPREPLY=($(compgen -W "up down start stop restart ps logs exec run build pull config" -- "${cur}"))
            fi
            ;;
        env-init)
            if [[ ${cword} -eq 3 ]]; then
                local env_types=""
                if [[ -n "${warden_dir}" && -d "${warden_dir}/environments" ]]; then
                    env_types="$(ls -d "${warden_dir}/environments/"*/ 2>/dev/null \
                        | xargs -I{} basename {} \
                        | grep -v includes)"
                fi
                if [[ -z "${env_types}" ]]; then
                    env_types="cakephp drupal laravel local magento1 magento2 shopware symfony wordpress"
                fi
                COMPREPLY=($(compgen -W "${env_types}" -- "${cur}"))
            fi
            ;;
    esac
}

complete -F _warden warden
