#
# ~/.bashrc
#

# NOTE: Each subscript should decide if it needs to be run in non-interactive

# Load up the custom foo
for script in $(find ~/.bashrc.d/ -maxdepth 1 -type f -name "*.sh" 2>/dev/null | sort); do
    source $script
done
