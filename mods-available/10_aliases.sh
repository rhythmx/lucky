# If not running interactively, don't do anything
[[ "$-" != *i* ]] && return

logmsg aliases::debug setting some handy aliases

alias ls='ls --color=auto'
alias mz='mplayer -zoom -fs'
alias gl='git log --graph --color --branches --remotes --decorate=full'
alias mktags="GTAGSFORCECPP=1 gtags -I"

alias k="kubectl"
