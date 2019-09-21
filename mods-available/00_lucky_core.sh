if [ -z "$LUCKY_DIR" ]; then
    echo "lucky.sh has not yet been installed. Run \"lucky.sh --install\" first"
    exit 255
fi

export LUCKY_DIR

LUCKY_PREFIX="$LUCKY_DIR/local"
LUCKY_RUNDIR="$LUCKY_PREFIX/run"
LUCKY_BINDIR="$LUCKY_PREFIX/bin"

export LUCKY_PREFIX LUCKY_RUNDIR LUCKY_BINDIR

function create_and_chmod() {
    dirname=$1
    if [ ! -d "$dirname" ]; then
        mkdir -p "$dirname"
    fi
    chmod 700 "$dirname"
}

create_and_chmod "$LUCKY_DIR"
create_and_chmod "$LUCKY_PREFIX"
create_and_chmod "$LUCKY_RUNDIR"
create_and_chmod "$LUCKY_BINDIR"

LUCKY_VERBOSITY=4 # of 5

function loghdg() {
    echo -ne '\e[1;37m[\e[0m '
    echo -ne "$1"
    echo -ne ' \e[1;37m]\e[0m '
}

function logmsg() {
    case $1 in
        error)
            if [ "$LUCKY_VERBOSITY" -ge 1 ]; then
                shift
                loghdg '\e[0;31mLucky::error\e[0m'
                echo "$@"
            fi
            ;;
        warn)
            if [ "$LUCKY_VERBOSITY" -ge 2 ]; then
                shift
                loghdg "\e[0;33mLucky::warn\e[0m"
                echo "$@"
            fi
            ;;
        info)
            if [ "$LUCKY_VERBOSITY" -ge 3 ]; then
                shift
                loghdg "\e[0;32mLucky::info\e[0m"
                echo "$@"
            fi
            ;;
        debug)
            if [ "$LUCKY_VERBOSITY" -ge 4 ]; then
                shift
                loghdg "\e[0;36mLucky::debug\e[0m"
                echo "$@"
            fi
            ;;
    esac
}

logmsg debug Loaded lucky_core.sh
