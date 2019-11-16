# CYGWIN only after this
uname -a | grep CFYGWIN_NT >/dev/null 2>&1 || return

# TODO: leaving this as warn because it hasn't been tested in while
logmsg cygwin::warn A cygwin environement was detected, setting up environment

# TODO: this should probably be refactored into an architecture.sh module

unset EDITOR

GVIM="/cygdrive/c/Program Files (x86)/Vim/vim80/gvim.exe"

function gvim() {
    "${GVIM}" $(cygpath -aw $1) &
}

export CYGWIN=t
