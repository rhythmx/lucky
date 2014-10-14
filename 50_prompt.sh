# Setup a snazzy dynamic prompt

PS1='[\u@\h \W]\$ ' # <== not so snazzy default

# Define this empty here to avoid not found errors if git is not present
function __git_ps1() {}

# Git should come with some handy prompt-fu
if [ -e /usr/share/git/completion/git-prompt.sh ]; then
    source /usr/share/git/completion/git-prompt.sh
fi

# [/path/to/full/dir GITINFO(info)]

global_err=''

function prompt_init() {
    # Must come first!
    global_err=$?

    # Clear the slate
    PS1=''


    # Directory info
    PS1+=$(prompt_statusline)
    PS1+="\n"

    PS1+="${bldgrn}\u@\h${bldblu} (\A)\$ ${txtrst}"
}

function prompt_statusline() {
    if [[ $global_err == 0 ]]; then
	c=${bldgrn}
    else
	c=${bldred}
	err=" ${bldred}(failed with code=${bldylw}${bakred}${?}${txtrst}${bldred})"
    fi

    GIT_PS1_SHOWDIRTYSTATE=1
    GIT_PS1_SHOWSTASHSTATE=1
    GIT_PS1_SHOWUNTRACKEDFILES=1
    # Explicitly unset color (default anyhow). Use 1 to set it.
    GIT_PS1_SHOWCOLORHINTS=1
    GIT_PS1_DESCRIBE_STYLE="branch"
    GIT_PS1_SHOWUPSTREAM="auto git"

    echo "${c}-=<[ $(prompt_dir)${err}${bldcyn}$(__git_ps1)${c} ]>=-${txtrst}"
}

function prompt_dir() {
    echo "${bldylw}$(pwd)"
}

PROMPT_COMMAND='prompt_init'
