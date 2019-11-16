logmsg rvm::debug setting up Ruby/RVM environment

if [ -f "$HOME/.rvm/scripts/rvm" ]
then
	  source "$HOME/.rvm/scripts/rvm"
    export PATH="$PATH:$HOME/.rvm/bin"
fi
