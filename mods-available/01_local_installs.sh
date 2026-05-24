# Stuff installed per user should prefix itself here
PATH=$PATH:$LUCKY_BINDIR:$LUCKY_DIR/bin
export PATH

LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$LUCKY_USER_DIR/local/lib
export LD_LIBRARY_PATH

logmsg local_installs::debug Loaded paths for local installations
