function rand_password() {
    case "$1" in
        64bit_human)
            five_four_char_words=$(grep -P '^\w{4}$' /usr/share/dict/american-english | sort -R | head -n 5)
            joined_by_nums=$(for w in $five_four_char_words; do echo -n ${w}$(( $RANDOM % 10 )); done)
            echo $joined_by_nums | sed -e 's/[[:digit:]]*$//g'
            ;;
        96bit)
            head -c 12 /dev/urandom | base64
            ;;
        120bit)
            head -c 15 /dev/urandom | base64
            ;;
        240bit)
            head -c 30 /dev/urandom | base64
            ;;
        *)
            echo "syntax: rand_password [type]"
            echo "  avail generators:"
            echo "      64bit_human"
            echo "      96bit"
            echo "      120bit"
            echo "      240bit"
            ;;
    esac
}
