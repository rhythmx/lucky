logmsg ssh::debug checking ssh config setup

function _lucky-ssh-installed() {
    local dotfile="$LUCKY_DIR/dotfiles/luckysshconfig"
    local link="$HOME/.ssh/luckysshconfig"
    local config="$HOME/.ssh/config"

    [ -L "$link" ] || return 1
    [ "$(readlink -f "$link" 2>/dev/null)" = "$(readlink -f "$dotfile" 2>/dev/null)" ] || return 1
    [ -f "$config" ] || return 1
    grep -qE '^[[:space:]]*Include[[:space:]]+.*luckysshconfig([[:space:]]|$)' "$config" 2>/dev/null
}

if ! _lucky-ssh-installed; then
    logmsg ssh::warn "lucky ssh config not linked — run lucky-ssh-install"
fi

function lucky-ssh-install() {
    local dotfile="$LUCKY_DIR/dotfiles/luckysshconfig"
    local ssh_dir="$HOME/.ssh"
    local link="$ssh_dir/luckysshconfig"
    local config="$ssh_dir/config"
    local include_line="Include ~/.ssh/luckysshconfig"

    if [ ! -f "$dotfile" ]; then
        logmsg ssh::error "lucky ssh dotfile missing at $dotfile"
        return 1
    fi

    if [ ! -d "$ssh_dir" ]; then
        mkdir -p "$ssh_dir" || {
            logmsg ssh::error "could not create $ssh_dir"
            return 1
        }
        chmod 700 "$ssh_dir"
    fi

    if [ -L "$link" ]; then
        if [ "$(readlink -f "$link" 2>/dev/null)" = "$(readlink -f "$dotfile" 2>/dev/null)" ]; then
            logmsg ssh::debug "$link already points to $dotfile"
        else
            logmsg ssh::error "$link exists but points elsewhere — refusing to overwrite"
            return 1
        fi
    elif [ -e "$link" ]; then
        logmsg ssh::error "$link already exists and is not a symlink — refusing to overwrite"
        return 1
    else
        ln -s "$dotfile" "$link" || {
            logmsg ssh::error "failed to symlink $link -> $dotfile"
            return 1
        }
        logmsg ssh::info "linked $link -> $dotfile"
    fi

    chmod 600 "$dotfile" || {
        logmsg ssh::error "failed to chmod 600 $dotfile"
        return 1
    }

    if [ -f "$config" ] && grep -qE '^[[:space:]]*Include[[:space:]]+.*luckysshconfig([[:space:]]|$)' "$config" 2>/dev/null; then
        logmsg ssh::debug "$config already has Include line"
    elif [ -f "$config" ]; then
        # Back the original up before touching it; leave the backup in place so
        # the user can restore manually if anything looks wrong.
        local backup="$config.lucky.bak.$(date +%s)"
        cp -a "$config" "$backup" || {
            logmsg ssh::error "failed to back up $config to $backup"
            return 1
        }
        # Include must come before any Host blocks to apply globally, so prepend.
        if ! { printf '%s\n' "$include_line"; cat "$backup"; } > "$config"; then
            logmsg ssh::error "failed to update $config — restoring from $backup"
            cp -a "$backup" "$config"
            return 1
        fi
        chmod 600 "$config"
        logmsg ssh::info "added '$include_line' to $config (backup at $backup)"
    else
        printf '%s\n' "$include_line" > "$config" || {
            logmsg ssh::error "failed to create $config"
            return 1
        }
        chmod 600 "$config"
        logmsg ssh::info "created $config with '$include_line'"
    fi
}
