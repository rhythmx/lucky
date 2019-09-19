# CYGWIN only after this
uname -a | grep CFYGWIN_NT >/dev/null 2>&1 || return

# TODO
unset EDITOR

GVIM="/cygdrive/c/Program Files (x86)/Vim/vim80/gvim.exe"

function gvim() {
    "${GVIM}" $(cygpath -aw $1) &
}


export CYGWIN=t
