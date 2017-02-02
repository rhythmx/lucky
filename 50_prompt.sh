# Setup a snazzy dynamic prompt

PS1='[\u@\h \W]\$ ' # <== not so snazzy default

# If not running interactively, don't do anything
[[ $- != *i* ]] && return


global_err=''


# Colors & Config 
line_color="$bldblk"
time_color="$bldcny"
gitp_color="$bldylw"
wdir_color="$bldgrn"
err_color="$bldred"
updates_color="$bldylw"
updates_file="${HOME}/.prompt_update_checks"
top_status_color="$txtcyn"
bottom_status_color="$txtgrn"

prompt_width=80

# Default color wont appear in emacs
if [ "$EMACS" == "t" ]; then
    line_color="$bldwht"
fi


# Example: 
#
# ╔═[16:44 Thu (224 pkg updates)]════════════════════════════════════════════════╗
# ╚═══════════════════════════════════════════════════════════════[ /home/sean ]═╝
#
# [sean@fry] $ 

# Dynamically build a Bash Prompt (i.e, result stored in PS1)
function prompt_builder() {
    
    # Must come first, save last exit code for later use. Any other
    # commands run will overwrite it.
    global_err=$?

    # Clear the slate
    PS1=''

    # Prompt is divided into two lines, a status line and a simple prompt
    
    PS1+="\n$(prompt_statuslines)\n\n$(prompt_promptline)"

}

function prompt_promptline() {
    echo "[\u@\h] \$ "
}

function prompt_time() {
    echo "${time_color}$(date +'%H:%M %a')"
}

function prompt_wdir() {
    echo "${wdir_color}$(pwd)"
}

function prompt_git() {
    GIT_PS1_SHOWDIRTYSTATE=1
    GIT_PS1_SHOWSTASHSTATE=1
    GIT_PS1_SHOWUNTRACKEDFILES=1
    GIT_PS1_SHOWCOLORHINTS=1
    GIT_PS1_DESCRIBE_STYLE="branch"
    GIT_PS1_SHOWUPSTREAM="auto git"
    echo "${gitp_color}$(__git_ps1)"
}

function prompt_battery_info() {
    test -x /usr/bin/acpi || return
    (acpi -a | grep on-line >/dev/null 2>&1 ) && echo -n "AC" && return

    part=$(acpi -b | grep -Po '\d+%' | tr '%' ' ' | tr '\n' '+' | sed -e 's/+$//g' )
    tot=$(acpi -b | grep -Po '\d+%' | tr '%' ' ' | wc -l)
    batt_lvl=$((  $part / $tot ))
    state=""
    if ( acpi -b | grep -i discharging  >/dev/null 2>&1 ); then
	state=discharging
    else
	state=charging
    fi
    echo -n "(${batt_lvl}%-${state})"
}

function prompt_last_err() {
    if [[ $global_err != 0 ]]; then
	echo "${err_color}(exit ${global_err})"
    fi
}

function prompt_updates() {
    # TODO: detect arch and do something useful for each
    test -x /usr/bin/checkupdates || return

    # Update at most once every few hours
    if ! find $updates_file -mmin -360 >/dev/null 2>&1 ; then
	echo -ne "${BWhite} * Updating list of packages, please wait...${Color_Off}" >&2
	num=`checkupdates | wc -l > $updates_file`
	echo -ne "${BGreen} ok!${Color_Off}" >&2
    fi

    num=$(cat $updates_file)
    
    if [ $num -gt 0 ]; then
	echo "${updates_color}($num pkg updates)"
    fi
}

function prompt_bottom_status() {
    echo $(join_strings_color "$top_status_color" "$(prompt_time)" "$(prompt_last_err)" "$(prompt_updates)")
}

function prompt_top_status() {
    echo $(join_strings_color "$bottom_status_color" "$(prompt_wdir)" "$(prompt_battery_info)" "$(prompt_git)")
}

function prompt_top_line() {
    content=$(prompt_top_status)
    content_nc=`strip_colors $content`
    content_len=$(expr length "$content_nc")
    padding_len=$(( $prompt_width - $content_len ))
    padding_len=$(( $padding_len - 7 )) # account for static chars
    padding=$(printf '═%.s' $(seq 1 $padding_len))
    echo "${line_color}╔═${top_status_color}[ ${content} ${top_status_color}]${line_color}$padding╗${txtrst}"
}

function prompt_bottom_line() {
    content=$(prompt_bottom_status)
    content_nc=`strip_colors $content`
    content_len=$(expr length "$content_nc")
    padding_len=$(( $prompt_width - $content_len ))
    padding_len=$(( $padding_len - 7 )) # account for static chars
    padding=$(printf '═%.s' $(seq 1 $padding_len))
    echo "${line_color}╚${padding}${bottom_status_color}[ ${content} ${bottom_status_color}]${line_color}═╝${txtrst}"
}

function prompt_statuslines() {
    echo $(prompt_top_line)
    echo $(prompt_bottom_line)
}

# Strips bash color strings (e.g. \[\e[1;31m\] not raw escape codes) from given string
function strip_colors() {
    echo $* | sed -e 's/\\\[\([^\\]\|\\e\)*\\\]//g'
}

# Join several strings together with spaces in between
function join_strings() {
    ret=""
    while test $# -gt 0
    do
	printable=$(strip_colors $1)
	if [ "$printable" != "" ]
	then
	    if [ "$ret" != "" ]
	    then
		ret="${ret} "
	    fi
	    ret="${ret}${1}"
	fi
	shift
    done
    echo $ret
}

# Join several strings together with spaces in between with a default color
function join_strings_color() {
    ret=""
    color=$1
    shift
    while test $# -gt 0
    do
	printable=$(strip_colors $1)
	if [ "$printable" != "" ]
	then
	    if [ "$ret" != "" ]
	    then
		ret="${ret} "
	    fi
	    ret="${ret}${color}${1}"
	fi
	shift
    done
    echo $ret
}

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

