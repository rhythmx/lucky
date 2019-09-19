#!/bin/bash

if [ -f "$HOME/.rvm/scripts/rvm" ]
then
	  source "$HOME/.rvm/scripts/rvm"
    # [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
    # TODO
    # Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
    export PATH="$PATH:$HOME/.rvm/bin"
fi
