# Setup a snazzy dynamic prompt
# Example:

# ╔═[ 18:09 Fri /home/sean/code/lucky ]══════════════════════════════════════════╗
# ╚═══════════════════════════════════════[ (84%-discharging) (18 pkg updates) ]═╝
#
# [sean@kor] $

PS1='[\u@\h \W]\$ ' # <== not so snazzy default

# If not running interactively, don't do anything
[[ "$-" != *i* ]] && return

logmsg prompt::debug setting up custom prompt system

global_err=''

# TODO: Under heavy load or on shitty platforms it can take a while to generate
# the fancy prompt. Some of these building blocks could be memoized to speed
# things up. Otherwise, if the whole process takes too long, it should
# automatically fall back to a faster method. Timeouts (vs fallbacks) would be
# nice, but I'm not sure I like the idea of asynchronous processes running at
# every prompt.

# Colors & Config 
line_color="$txtpur"
time_color=""
gitp_color="$bldylw"
wdir_color="$txtgrn"
err_color="$bldred"
batt_color=""
updates_color="$bldylw"
updates_file="${HOME}/.prompt_update_checks"
top_status_color="$txtcyn"
bottom_status_color="$txtcyn"

prompt_width=80

# Default color wont appear in emacs
if [ "$EMACS" == "t" ]; then
    line_color="$bldwht"
fi



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
    return
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
    echo -n "${batt_color}(${batt_lvl}%-${state})"
}

function prompt_last_err() {
    if [[ $global_err != 0 ]]; then
	echo "${err_color}(${global_err})"
    fi
}

function prompt_updates_archlinux() {
    # TODO: detect os/distro and do something useful for each
    test -x /usr/bin/checkupdates || return

    # Update at most once every few hours
    if ! ( find $updates_file -mmin -360 2>/dev/null | egrep '.*' >/dev/null ) ; then
	      echo -ne "${BWhite} * Updating list of packages, please wait...${Color_Off}" >&2
	      num=`checkupdates | wc -l > $updates_file`
	      echo -ne "${BGreen} ok!${Color_Off}" >&2
    fi

    num=$(cat $updates_file)

    if [ $num -gt 0 ]; then
	      echo "${updates_color}($num pkg updates)"
    fi
}

function prompt_updates_ubuntu() {
    num=$(apt list --upgradable 2>/dev/null | grep upgradable | wc -l)
    if [ ${num} -gt 0 ]; then
        echo "${updates_color}($num pkg updates)"
    fi
}

#
# Displays message number of available updates for the local system
#
function prompt_updates() {
    if test -x /usr/bin/checkupdates; then
        prompt_updates_archlinux
        return
    fi

    if which apt >/dev/null; then
        prompt_updates_ubuntu
        return
    fi

    # TODO: others
}

function prompt_bottom_status() {
    echo $(join_strings_color "$bottom_status_color" "$(prompt_battery_info)" "$(prompt_updates)"  "$(prompt_git)")
}

function prompt_top_status() {
    echo $(join_strings_color "$top_status_color" "$(prompt_time)" "$(prompt_last_err)" "$(prompt_wdir)")
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
    local ret=""
    local color=$1
    shift
    while test $# -gt 0
    do
	      local printable=$(strip_colors $1)
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

# If it is not already defined, define this empty function here to avoid not
# found errors if git is not present
if ! declare -f __git_ps1 >/dev/null; then
    function __git_ps1() {
        false
    }
fi

# Git should come with some handy prompt-fu
if [ -e /usr/share/git/completion/git-prompt.sh ]; then
    source /usr/share/git/completion/git-prompt.sh
fi

# [/path/to/full/dir GITINFO(info)]

PROMPT_COMMAND='prompt_builder'
