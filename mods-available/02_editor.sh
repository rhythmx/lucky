# EDITOR=emacsclient

# NOTE these are in reverse order of preference

which vi          >/dev/null 2>&1 && EDITOR=vi
which emacsclient >/dev/null 2>&1 && EDITOR=emacsclient
which vim         >/dev/null 2>&1 && EDITOR=vim

export EDITOR

logmsg editor::debug set default editor to $EDITOR
