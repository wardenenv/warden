#compdef warden

# Installation
# ============
#
# Copy this file, `warden.plugin.zsh`, to `~/.oh-my-zsh/plugins/custom/warden/`
#
# Enable the plugin by adding `warden` to `plugins=(… warden)` in `~/.zshrc`
#
# Reload your zsh session, or source `~/.zshrc`

_warden_get_command_list() {
    warden | sed -n '/Commands:/,$p' | sed '1d' | awk '{print $1}'
}

_warden() {
    compadd `_warden_get_command_list`
}

compdef _warden warden
