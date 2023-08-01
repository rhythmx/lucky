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
    echo "      locate [mod]:   print location of script file for mod"
    echo "      reload [mod]:   reload script source (if enabled)"
}

function install() {
    if [ -z "$LUCKY_DIR" ]; then
	      echo "LUCKY_DIR is not set!"
    fi
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

    source "$HOME/.bash_profile"

    echo "lucky.sh has been installed. Enjoy!"
    exit 0
}

function en_path_for() {
    p=$(find "$LUCKY_DIR/mods-enabled" -regex ".*[0-9][0-9]_${1}.sh" | head -n 1)
    [ -e "$p" ] && echo $p
}

function av_path_for() {
    p=$(find "$LUCKY_DIR/mods-available" -regex ".*[0-9][0-9]_${1}.sh" | head -n 1)
    [ -e "$p" ] && echo $p
}

function prio_for() {
    $(basename $(av_path_for $1) | cut -d_ -f1)
}

function enable_mod() {
    if [ -e "$(en_path_for $1)" ]; then
        echo "$1 is already enabled"
        return
    fi
    ap=$(av_path_for $1)
    if [ ! -e "$ap" ]; then
        echo "$1 is not a valid module. see '$0 list-all'"
        return
    fi
    rp=$(realpath --relative-to="$LUCKY_DIR/mods-enabled" "$ap")
    (cd "$LUCKY_DIR/mods-enabled" && ln -sf "$rp" .)
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

if [ "$1" == "install" ]; then
    banner
    LUCKY_DIR=$(readlink -f "$(dirname ${BASH_SOURCE[0]})")
    install
fi

if [ -z "$LUCKY_DIR" ]; then
    echo "lucky.sh has not yet been installed. Run \"lucky.sh install\" first"
    exit 255
fi

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
        for f in $(find $LUCKY_DIR/mods-enabled -maxdepth 1 -name '*.sh' | sort); do
            basename $f| sed -E "s/^([0-9]+)_(.*)\.sh/\2 \1/" | xargs printf "%-20s (prio: %s)\n"
        done
        ;;
    list-all)
        for f in $(find $LUCKY_DIR/mods-available -maxdepth 1 -name '*.sh' | sort); do
            basename $f| sed -E "s/^([0-9]+)_(.*)\.sh/\2 \1/" | xargs printf "%-20s (prio: %s)\n"
        done
        ;;
    enabl[e])
        enable_mod $2
        ;;
    disable)
        disable_mod $2
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

