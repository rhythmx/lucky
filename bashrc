#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Load up the custom foo
for script in $(find ~/.bashrc.d/ -maxdepth 1 -type f -name "*.sh" 2>/dev/null | sort); do
    source $script
done
