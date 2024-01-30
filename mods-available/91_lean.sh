logmsg lean::debug "loading lean development tools"

unset LEAN_PATH
if which lean >/dev/null 2>&1
then
	# path must be unset before calling so that compile time path is output
	LEAN_PATH=`lean --path`
fi

export LEAN_PATH
