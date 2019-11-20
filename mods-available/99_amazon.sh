if [ -d "$HOME/code/aws-helpers" ]; then
	for script in $(find "$HOME/code/aws-helpers" -iname '*-tools.sh'); do
		logmsg debug "loading amazon helper $(basename $script)"
		source "$script"
	done
fi
