# Setup a snazzy dynamic prompt

PS1='[\u@\h \W]\$ ' # <== not so snazzy default

# If not running interactively, don't do anything
[[ $- != *i* ]] && return


global_err=''

# Dynamically build a Bash Prompt (i.e, result stored in PS1)
function prompt_builder() {
    
    # Must come first, save last exit code for later use. Any other
    # commands run will overwrite it.
    global_err=$?

    # Clear the slate
    PS1=''

    # Prompt is divided into two lines, a status line and a simple prompt
    
    PS1+="\n$(prompt_statusline)\n\n$(prompt_promptline)"

}

function prompt_promptline() {
    echo "[\u@\h] \$ "
}

function prompt_statusline() {

    time=$(date +"%H:%M %a")
    wdir=$(pwd)
    gitp=$(prompt_git)
    len=$(expr length "${wdir} ${gitp}")
    len=$((len+6))
    line=$(printf '═%.s' $(seq 1 $len))
    top="${bldblk}╔═${txtcyn}[${bldcyn}${time}${txtcyn}]${bldblk}$line╗"
    bot="${bldblk}╚═════════════${txtgrn}[ ${bldgrn}${wdir} ${bldylw}${gitp}${bldgrn} ${txtgrn}]${bldblk}═╝${txtrst}" 
    
    if [[ $global_err == 0 ]]; then
	c=${bldgrn}
    else
	c=${bldred}
	err=" ${bldred}(failed with code=${bldylw}${bakred}${global_err}${txtrst}${bldred})"
    fi

    # echo "${c}-=<[ $(prompt_dir)${err}${bldcyn}$(__git_ps1)${c} ]>=-${txtrst}"
    echo $top
    echo $bot
}

function prompt_dir() {
    echo "${bldylw}$(pwd)"
}

function prompt_git() {
    GIT_PS1_SHOWDIRTYSTATE=1
    GIT_PS1_SHOWSTASHSTATE=1
    GIT_PS1_SHOWUNTRACKEDFILES=1
    # Explicitly unset color (default anyhow). Use 1 to set it.
    GIT_PS1_SHOWCOLORHINTS=1
    GIT_PS1_DESCRIBE_STYLE="branch"
    GIT_PS1_SHOWUPSTREAM="auto git"

    echo $(__git_ps1)
}
# ╔═(00:46 Thu)══════════════════════════════╗
# ╚═══════════ ~/code/lim/cxxlean (master<) ═╝
#     
# sean@scruffy $

# Define this empty here to avoid not found errors if git is not present
function __git_ps1() {
    false
}

# Git should come with some handy prompt-fu
if [ -e /usr/share/git/completion/git-prompt.sh ]; then
    source /usr/share/git/completion/git-prompt.sh
fi

# [/path/to/full/dir GITINFO(info)]

PROMPT_COMMAND='prompt_builder'

