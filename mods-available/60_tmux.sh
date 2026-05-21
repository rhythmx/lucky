logmsg tmux::debug setting up tmux integration

if ! command -v tmux >/dev/null; then
    logmsg tmux::debug tmux not installed, skipping
    return
fi

if [ -e "${XDG_CONFIG_HOME:-$HOME/.config}/tmux" ]; then
    logmsg tmux::debug tmux config present
    return
fi

logmsg tmux::info "tmux installed but ${XDG_CONFIG_HOME:-$HOME/.config}/tmux missing — run lucky-install-tmux"

function lucky-install-tmux() {
    local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/tmux"
    local dotfiles="$LUCKY_DIR/dotfiles/tmux"

    if [ ! -d "$dotfiles" ]; then
        logmsg tmux::error "lucky tmux dotfiles missing at $dotfiles"
        return 1
    fi

    if [ -e "$config_dir" ] || [ -L "$config_dir" ]; then
        logmsg tmux::error "$config_dir already exists — refusing to overwrite"
        return 1
    fi

    mkdir -p "$(dirname "$config_dir")" || {
        logmsg tmux::error "could not create $(dirname "$config_dir")"
        return 1
    }

    ln -s "$dotfiles" "$config_dir" || {
        logmsg tmux::error "failed to symlink $config_dir -> $dotfiles"
        return 1
    }

    logmsg tmux::info "linked $config_dir -> $dotfiles"

    local tpm_dir="$config_dir/plugins/tpm"
    if [[ -d "$tpm_dir/.git" ]]; then
        logmsg tmux::debug "tpm already present at $tpm_dir"
        return 0
    fi

    if ! command -v git >/dev/null; then
        logmsg tmux::error "git not available, cannot clone tpm"
        return 1
    fi

    git clone --quiet https://github.com/tmux-plugins/tpm "$tpm_dir" || {
        logmsg tmux::error "failed to clone tpm into $tpm_dir"
        return 1
    }

    logmsg tmux::info "cloned tpm to $tpm_dir"
}
