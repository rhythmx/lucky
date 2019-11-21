logmsg rvm::debug setting up Ruby/RVM environment

if [ -f "$HOME/.rvm/scripts/rvm" ]
then
	  source "$HOME/.rvm/scripts/rvm"
    export PATH="$PATH:$HOME/.rvm/bin"
else
    logmsg rvm::warn RVM is not installed. You can do this automatically by running lucky_rvm_install

    function lucky_rvm_install() {
        # TODO: is any special handling needed for other platforms?
        logmsg rvm::info Installing rvm via web
        gpg --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
        curl -sSL https://get.rvm.io | bash -s stable
        source "$HOME/.rvm/scripts/rvm"
        export PATH="$PATH:$HOME/.rvm/bin"
        rvm install 2.6
    }
fi
