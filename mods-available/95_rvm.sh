logmsg rvm::debug setting up Ruby/RVM environment


function lucky_rvm_install() {
    # TODO: this install hook is probably way out of date
    # TODO: is any special handling needed for other platforms?
    logmsg rvm::info Installing rvm via web
    gpg --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
    curl -sSL https://get.rvm.io | bash -s stable
    source "$HOME/.rvm/scripts/rvm"
    export PATH="$PATH:$HOME/.rvm/bin"
    rvm install 2.6
}

if [[ -s "$HOME/.rvm/scripts/rvm" ]]; then
    source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
    eval "$(rbenv init - --no-rehash bash)"
else
    logmsg rvm::debug RVM is not installed. You can do this automatically by running lucky_rvm_install

fi
