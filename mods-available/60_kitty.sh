logmsg kitty::debug setting up kitty integration

if ! command -v kitty >/dev/null; then
    logmsg kitty::debug kitty not installed, skipping
    return
fi

if [ -e "${XDG_CONFIG_HOME:-$HOME/.config}/kitty" ]; then
    logmsg kitty::debug kitty config present
    return
fi

logmsg kitty::warn "kitty installed but ${XDG_CONFIG_HOME:-$HOME/.config}/kitty missing — run lucky-kitty-install"

function lucky-kitty-install() {
    local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/kitty"
    local dotfiles="$LUCKY_DIR/dotfiles/kitty"

    if [ ! -d "$dotfiles" ]; then
        logmsg kitty::error "lucky kitty dotfiles missing at $dotfiles"
        return 1
    fi

    if [ -e "$config_dir" ] || [ -L "$config_dir" ]; then
        logmsg kitty::error "$config_dir already exists — refusing to overwrite"
        return 1
    fi

    mkdir -p "$config_dir" || {
        logmsg kitty::error "could not create $config_dir"
        return 1
    }

    # Symlink only kitty.conf so per-user state (sessions, user.conf) can live
    # alongside it in the writable real directory.
    ln -sf "$dotfiles/kitty.conf" "$config_dir/kitty.conf" || {
        logmsg kitty::error "failed to symlink $config_dir/kitty.conf"
        return 1
    }

    logmsg kitty::info "set up $config_dir (writable, kitty.conf symlinked from $dotfiles)"
}
