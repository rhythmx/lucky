logmsg ghidra::debug setting up ghidra if available

if [ -d "$LUCKY_PREFIX/ghidra" ]; then
    export GHIDRA_INSTALL_DIR="$LUCKY_PREFIX/ghidra"
    export PATH=$PATH:$GHIDRA_INSTALL_DIR
    logmsg ghidra::debug "Ghidra installation found at $GHIDRA_INSTALL_DIR"
else
    logmsg ghidra::debug "No Ghidra installation found"
fi
