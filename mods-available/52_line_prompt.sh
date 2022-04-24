function setbg_truecolor_rgb() {
    local r=$(rgb_r $1)
    local g=$(rgb_g $2)
    local b=$(rgb_b $3)
    echo -ne "\\e[48:2:$r:$g:${b}m"
}

function setfg_truecolor_rgb() {
    local r=$(rgb_r $1)
    local g=$(rgb_g $2)
    local b=$(rgb_b $3)
    echo -ne "\\e[38:2:$r:$g:${b}m"
}

function rgb_r() {
    echo $1 | cut -d' ' -f 1
}

function rgb_g() {
    echo $1 | cut -d' ' -f 2
}

function rgb_b() {
    echo $1 | cut -d' ' -f 3
}

function hsl_to_rgb() {
    local h=$1
    local s=$2
    local l=$3

    awk -v h="$1" -v s="$2" -v l="$3" '
        function abs(x){return ((x < 0.0) ? -x : x)}
        BEGIN {
            h = h % 360
            c = ( 1.0 - abs( 2.0*l - 1.0))*s
            x = c*(1.0 - abs((h / 60.0)%2.0-1.0))
            m = l - c/2.0

            if (h <= 60) {
                rp=c
                gp=x
                bp=0
            } else if (h <= 120) {
                rp=x
                gp=c
                bp=0
            } else if (h <= 180) {
                rp=0
                gp=c
                bp=x
            } else if (h <= 240) {
                rp=0
                gp=x
                bp=c
            } else if (h <= 300) {
                rp=x
                gp=0
                bp=c
            } else {
                rp=c
                gp=0
                bp=x
            }

            # print c, x, m

            r=int((rp+m)*255)
            g=int((gp+m)*255)
            b=int((bp+m)*255)
            print r, g, b
        }
    '
}

hue_start=$(( RANDOM % 360 ))
hue_step=8

# Set fg hsl
function fgc() {
    echo -n "\\[" 
    setfg_truecolor_rgb $(hsl_to_rgb $1 $2 $3)
    echo -n "\\]" 
}

# Gradient iterator
function g() {
    local i=$1
    echo -n "\\[" 
    setfg_truecolor_rgb $(hsl_to_rgb $(( hue_start + i*hue_step )) 1 0.5 )
    echo -n "\\]"
}

# reset color
function r() {
   echo -ne "\\[\x1b[0m\\]" 
}




# 3 line prompt
# PS1="\n$(g 3)╭$(g 4)─$(g 5)─$(g 6)─$(g 7)─$(g 8)─$(g 9)╼$(r) \@ $(g 10)╾─╼$(r) \w \n$(g 2)│$(r)\n$(g 1)╰$(g 0)╼$(r) \u@\h \$ "

# 2 line prompt

function prompt_pyenv() {
    if [ -n "$VIRTUAL_ENV_PROMPT" ]; then
        echo $VIRTUAL_ENV_PROMPT
    fi
}

function prompt_helper() {
    echo "$(prompt_pyenv)\$"
}

function two_line() {
    hue_start=$(( RANDOM % 360 ))
    hue_step=8
    PS1="\n$(g 2)╭$(g 3)─$(g 4)─$(g 5)─$(g 6)─$(g 7)─$(g 8)╼$(r) $(fgc 0 0 0.5)\@$(r) $(g 9)╾─╼ \w\n$(g 1)╰$(g 0)╼$(r) $(g 0)\u@\h$(r) $(fgc 0 0 0.5)$(prompt_helper)$(r) "
}

export PROMPT_COMMAND="two_line"
