#!/bin/bash

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

function usage() {
    echo "${0}: [command] (args ...)"
    echo "      help:           display this message"
    echo "      install:        setup autoloading"
    echo "      list:           list available modules"
    echo "      enable [mod]:   enable the given module"
    echo "      disable [mod]:  disable the given module"
}

function install() {
    if [ -e "${HOME}/.bashrc" ]; then
        if [ -f "${HOME}/.bashrc" ]; then
            cp -a "${HOME}/.bashrc" "${HOME}/.bashrc.$(date +%s).bak"
        fi
        rm "${HOME}/.bashrc"
    fi
    ln -sf "${HOME}/.bashrc.d/dotfiles/bashrc" "${HOME}/.bashrc"

    if [ -e "${HOME}/.bash_profile" ]; then
        if [ -f "${HOME}/.bash_profile" ]; then
            cp -a "${HOME}/.bash_profile" "${HOME}/.bash_profile.$(date +%s).bak"
        fi
        rm "${HOME}/.bash_profile"
    fi
    ln -sf "${HOME}/.bashrc.d/dotfiles/bash_profile" "${HOME}/.bash_profile"

    source "$HOME/.bash_profile"

    echo "lucky.sh has been installed. Enjoy!"
    exit 0
}

if [ "$1" == "install" ]; then
    install
fi

if [ -z "$LUCKYDIR" ]; then
    echo "lucky.sh has not yet been installed. Run \"lucky.sh --install\" first"
    exit 255
fi

# Not bash or zsh?
if [ -z "$BASH_VERSION" -a -z "$ZSH_VERSION" ]; then
    echo "lucky does not support plain sh. use bash"
    exit 255
fi

# Handle arguments
case "$1" in
    help)
        usage
        ;;
    list)
        for f in $(find $LUCKYDIR/mods-available -maxdepth 1 -name *.sh | sort); do
            basename $f| sed -E "s/^([0-9]+)_(.*)\.sh/\2 \1/" | xargs printf "%-20s (prio: %s)\n"
        done
        ;;
    *)
        echo "Unrecognized command: $1"
        usage
        exit 255
esac

