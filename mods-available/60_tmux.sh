logmsg tmux::debug setting up tmux integration

if ! command -v tmux >/dev/null; then
    logmsg tmux::debug tmux not installed, skipping
    return
fi

if [ -e "${XDG_CONFIG_HOME:-$HOME/.config}/tmux" ]; then
    logmsg tmux::debug tmux config present
else
    logmsg tmux::warn "tmux installed but ${XDG_CONFIG_HOME:-$HOME/.config}/tmux missing — run lucky-tmux-install"
fi

function lucky-tmux-install() {
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

    mkdir -p "$config_dir" || {
        logmsg tmux::error "could not create $config_dir"
        return 1
    }

    # Symlink only tmux.conf so TPM can install plugins to the writable real dir.
    ln -sf "$dotfiles/tmux.conf" "$config_dir/tmux.conf" || {
        logmsg tmux::error "failed to symlink $config_dir/tmux.conf"
        return 1
    }

    logmsg tmux::info "set up $config_dir (writable, tmux.conf symlinked from $dotfiles)"
}
