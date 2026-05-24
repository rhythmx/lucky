logmsg nvim::debug setting up nvim integration

function lucky-nvim-install() {
    local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
    local dotfiles="$LUCKY_DIR/dotfiles/nvim"

    if [ ! -d "$dotfiles" ]; then
        logmsg nvim::error "lucky nvim dotfiles missing at $dotfiles"
        return 1
    fi

    if [ -e "$config_dir" ] || [ -L "$config_dir" ]; then
        logmsg nvim::error "$config_dir already exists — refusing to overwrite"
        return 1
    fi

    mkdir -p "$config_dir" || {
        logmsg nvim::error "could not create $config_dir"
        return 1
    }

    # Symlink individual tracked items so plugin managers (lazy.nvim writes
    # lazy-lock.json) and per-user state land in the writable real directory.
    for item in init.lua lua; do
        ln -sf "$dotfiles/$item" "$config_dir/$item" || {
            logmsg nvim::error "failed to symlink $config_dir/$item"
            return 1
        }
    done

    logmsg nvim::info "set up $config_dir (writable, files symlinked from $dotfiles)"
}

if ! command -v nvim >/dev/null; then
    logmsg nvim::debug nvim not installed, skipping
    return
fi

if [ ! -e "${XDG_CONFIG_HOME:-$HOME/.config}/nvim" ]; then
    logmsg nvim::warn "nvim installed but ${XDG_CONFIG_HOME:-$HOME/.config}/nvim missing — run lucky-nvim-install"
    return
fi

logmsg nvim::debug nvim config present

# Past here we just nudge interactive vim users toward nvim.
[[ "$-" != *i* ]] && return

# Route vim to nvim, but make the redirect visible so the habit eventually
# sticks. stderr (not logmsg) so the nudge always shows regardless of verbosity.
alias vim='printf "You should type nvim next time\n" >&2; sleep 0.3; nvim'
