#!/bin/bash

function banner() {
    echo "┌───────────────────────────────┐"
    echo "│░█░░░█░█░█▀▀░█░█░█░█░░░░█▀▀░█░█│"
    echo "│░█░░░█░█░█░░░█▀▄░░█░░░░░▀▀█░█▀█│"
    echo "│░▀▀▀░▀▀▀░▀▀▀░▀░▀░░▀░░▀░░▀▀▀░▀░▀│"
    echo "│                               │"
    echo "│ Local User  Configuration Kit │"
    echo "│     (c) 2019, Sean Bradly     │"
    echo "│        version 0.9.0          │"
    echo "└───────────────────────────────┘"
    echo "                                 "
}

function usage() {
    echo "${0}: [command] (args ...)"
    echo "      help:           display this message"
    echo "      install:        setup autoloading"
    echo "      list:           list enabled modules"
    echo "      list-all:       list every available module"
    echo "      enable [mod]:   enable the given module"
    echo "      disable [mod]:  disable the given module"
    echo "      select:         interactively choose modules (whiptail/dialog)"
    echo "      locate [mod]:   print location of script file for mod"
    echo "      reload [mod]:   reload script source (if enabled)"
}

function install() {
    if [ -z "$LUCKY_DIR" ]; then
	      echo "LUCKY_DIR is not set!"
    fi

    # Always default to ~/.lucky.d; do NOT inherit LUCKY_USER_DIR from the
    # environment — an old shell may still have stale vars from a previous install.
    local user_dir="$HOME/.lucky.d"

    if [ -e "${HOME}/.bashrc" ]; then
        if [ -f "${HOME}/.bashrc" ]; then
            cp -a "${HOME}/.bashrc" "${HOME}/.bashrc.$(date +%s).bak"
        fi
        rm "${HOME}/.bashrc"
    fi
    cat "${LUCKY_DIR}/dotfiles/bashrc" | \
	      sed -e "s:%%LUCKY_DIR%%:$LUCKY_DIR:" \
	      > "${HOME}/.bashrc"

    if [ -e "${HOME}/.bash_profile" ]; then
        if [ -f "${HOME}/.bash_profile" ]; then
            cp -a "${HOME}/.bash_profile" "${HOME}/.bash_profile.$(date +%s).bak"
        fi
        rm "${HOME}/.bash_profile"
    fi
    ln -sf "${LUCKY_DIR}/dotfiles/bash_profile" "${HOME}/.bash_profile"

    # Populate per-user mods-enabled from the repo's mods-default set.
    # Symlinks are absolute so they work regardless of where LUCKY_USER_DIR lives.
    local mods_enabled_dir="$user_dir/mods-enabled"
    mkdir -p "$mods_enabled_dir"
    for src in "$LUCKY_DIR/mods-default/"*.sh; do
        [ -e "$src" ] || continue
        local mod
        mod=$(basename "$src")
        ln -sf "$LUCKY_DIR/mods-available/$mod" "$mods_enabled_dir/$mod"
    done

    echo "lucky.sh has been installed. Enjoy!"
    echo "Run 'source ~/.bash_profile' to apply the new configuration to your current shell."
    exit 0
}

function en_path_for() {
    p=$(find "$LUCKY_USER_DIR/mods-enabled" -regex ".*[0-9][0-9]_${1}.sh" | head -n 1)
    [ -e "$p" ] && echo $p
}

function av_path_for() {
    p=$(find "$LUCKY_DIR/mods-available" -regex ".*[0-9][0-9]_${1}.sh" | head -n 1)
    [ -e "$p" ] && echo $p
}

# All available module script paths, sorted by priority prefix.
function available_mod_files() {
    find "$LUCKY_DIR/mods-available" -maxdepth 1 -name '*.sh' 2>/dev/null | sort
}

# All enabled module script paths, sorted by priority prefix.
function enabled_mod_files() {
    find "$LUCKY_USER_DIR/mods-enabled" -maxdepth 1 -name '*.sh' 2>/dev/null | sort
}

# True if the given module basename (e.g. 50_prompt.sh) is enabled for this
# user. Matches dangling symlinks too, so stale links count as enabled.
function is_enabled() {
    local link="$LUCKY_USER_DIR/mods-enabled/$1"
    [ -L "$link" ] || [ -e "$link" ]
}

function prio_for() {
    $(basename $(av_path_for $1) | cut -d_ -f1)
}

function enable_mod() {
    if [ ! -d "$LUCKY_USER_DIR/mods-enabled" ]; then
        echo "User directory not initialized. Run 'lucky.sh install' first."
        return 1
    fi
    if [ -e "$(en_path_for $1)" ]; then
        echo "$1 is already enabled"
        return
    fi
    ap=$(av_path_for $1)
    if [ ! -e "$ap" ]; then
        echo "$1 is not a valid module. see '$0 list-all'"
        return
    fi
    # Use absolute symlink: mods-enabled is in LUCKY_USER_DIR (e.g. ~/.lucky.d)
    # while mods-available is in LUCKY_DIR (e.g. /opt/lucky), so relative links
    # can't work.
    ln -sf "$ap" "$LUCKY_USER_DIR/mods-enabled/$(basename "$ap")" || {
        echo "Failed to enable $1"
        return 1
    }
    echo "$1 is now enabled"
}

function disable_mod() {
    ep=$(en_path_for $1)
    if [ ! -e "$ep" ]; then
        echo "Module $1 is not enabled or does not exist. See '$0 list'"
        return
    fi
    rm "$ep"
    echo "$1 has been disabled"
}

# Strip the priority prefix and .sh suffix off a module filename to get the
# name that enable_mod/disable_mod expect (e.g. 50_prompt.sh -> prompt).
function mod_name_for() {
    echo "$1" | sed -E 's/^[0-9]+_(.*)\.sh$/\1/'
}

function select_mods() {
    if [ ! -d "$LUCKY_USER_DIR/mods-enabled" ]; then
        echo "User directory not initialized. Run '$0 install' first."
        return 1
    fi
    if [ ! -t 1 ]; then
        echo "select requires an interactive terminal."
        return 1
    fi

    local tui
    if command -v whiptail >/dev/null 2>&1; then
        tui=whiptail
    elif command -v dialog >/dev/null 2>&1; then
        tui=dialog
    else
        echo "The 'select' menu needs 'whiptail' or 'dialog' installed."
        echo "  Debian/Ubuntu:  apt install whiptail"
        echo "  Fedora/RHEL:    dnf install dialog"
        echo "Until then, use '$0 enable <mod>' / '$0 disable <mod>'."
        return 1
    fi

    # Build the checklist: one tag/description/state triple per module.
    local files=() args=()
    local f base
    for f in $(available_mod_files); do
        base=$(basename "$f")
        files+=("$base")
        args+=("$base" "$(mod_name_for "$base")")
        if is_enabled "$base"; then
            args+=("ON")
        else
            args+=("OFF")
        fi
    done

    local n=${#files[@]}
    if [ "$n" -eq 0 ]; then
        echo "No modules available."
        return
    fi

    local list_height=$n
    [ "$list_height" -gt 15 ] && list_height=15

    # --separate-output yields one selected tag per line (no quoting to parse).
    # The 3>&1 1>&2 2>&3 dance routes the result (normally on stderr) to stdout.
    local chosen status
    chosen=$("$tui" --title "lucky module selection" --separate-output \
        --checklist "space toggles, enter applies" \
        $(( list_height + 8 )) 60 "$list_height" \
        "${args[@]}" 3>&1 1>&2 2>&3)
    status=$?

    if [ "$status" -ne 0 ]; then
        echo "Cancelled. No changes made."
        return
    fi

    # Reconcile each module against the selection, delegating to the same
    # enable/disable helpers the CLI commands use.
    local i name changed=0
    for (( i=0; i<n; i++ )); do
        name=$(mod_name_for "${files[$i]}")
        case $'\n'"$chosen"$'\n' in
            *$'\n'"${files[$i]}"$'\n'*)
                if ! is_enabled "${files[$i]}"; then
                    enable_mod "$name"
                    changed=1
                fi
                ;;
            *)
                if is_enabled "${files[$i]}"; then
                    disable_mod "$name"
                    changed=1
                fi
                ;;
        esac
    done

    if [ "$changed" -eq 0 ]; then
        echo "No changes."
    else
        echo "Run 'source ~/.bash_profile' to apply changes to your current shell."
    fi
}

if [ "$1" == "install" ]; then
    banner
    LUCKY_DIR=$(readlink -f "$(dirname ${BASH_SOURCE[0]})")
    install
fi

if [ -z "$LUCKY_DIR" ]; then
    echo "lucky.sh has not yet been installed. Run \"lucky.sh install\" first"
    exit 255
fi

: "${LUCKY_USER_DIR:=$HOME/.lucky.d}"

# Not bash or zsh?
if [ -z "$BASH_VERSION" -a -z "$ZSH_VERSION" ]; then
    echo "lucky does not support plain sh. use bash"
    exit 255
fi

# Handle arguments
case "$1" in
    hel[p])
        banner
        usage
        ;;
    list)
        for f in $(enabled_mod_files); do
            basename $f| sed -E "s/^([0-9]+)_(.*)\.sh/\2 \1/" | xargs printf "%-20s (prio: %s)\n"
        done
        ;;
    list-all)
        for f in $(available_mod_files); do
            basename $f| sed -E "s/^([0-9]+)_(.*)\.sh/\2 \1/" | xargs printf "%-20s (prio: %s)\n"
        done
        ;;
    enabl[e])
        enable_mod $2
        ;;
    disable)
        disable_mod $2
        ;;
    select)
        select_mods
        ;;
    locate)
        av_path_for $2
        ;;
    reload)
        echo "source $(en_path_for $2)"
        ;;
    *)
        banner
        echo "Unrecognized command: $1"
        echo
        usage
        exit 255
esac

