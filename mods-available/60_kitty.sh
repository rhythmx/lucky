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

    mkdir -p "$(dirname "$config_dir")" || {
        logmsg kitty::error "could not create $(dirname "$config_dir")"
        return 1
    }

    ln -s "$dotfiles" "$config_dir" || {
        logmsg kitty::error "failed to symlink $config_dir -> $dotfiles"
        return 1
    }

    logmsg kitty::info "linked $config_dir -> $dotfiles"
}
