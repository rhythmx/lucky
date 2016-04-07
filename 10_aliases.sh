# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias gl='git log --graph --color --branches --remotes --decorate=full'
