# EDITOR=emacsclient

# NOTE these are in reverse order of preference

which vi          >/dev/null && EDITOR=vi
which emacsclient >/dev/null && EDITOR=emacsclient
which vim         >/dev/null && EDITOR=vim

export EDITOR

logmsg editor::debug set default editor to $EDITOR
