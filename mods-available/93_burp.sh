logmsg burp::debug setting up BurpSuite if available

if [ -d "$LUCKY_PREFIX/BurpSuitePro" ]; then
    export BURP_INSTALL_DIR="$LUCKY_PREFIX/BurpSuitePro"
    export PATH=$PATH:$BURP_INSTALL_DIR
    logmsg burp::debug "Burp installation found at $BURP_INSTALL_DIR"
else
    logmsg burp::debug "No Burp installation found, login to https://portswigger.net/ to download BurpSuitePro and install it in $LUCKY_PREFIX/BurpSuitePro"
fi
