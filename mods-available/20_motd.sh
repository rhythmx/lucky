# If not running interactively, don't do anything
[[ "$-" != *i* ]] && return

if [ -e /etc/motd ]; then
    # uname -a >&2
    cat /etc/motd >&2
fi