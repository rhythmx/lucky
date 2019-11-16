# This function provides a few different kinds of password generators and approximate number of bits of entropy provided.

logmsg passwd_gen::debug loaded password generation function

function rand_password() {
    case "$1" in
        64bit_d)
            # tested with 3156 4-char words (* 3156 3156 3156 3156 3156 10 10 10 10)
            n5words=$(grep -P '^\w{4}$' /usr/share/dict/american-english | sort -u | wc -l)
            if [ ${n5words} -lt 3000 ]; then
                logmsg passwd_gen::error not enough unique dict words \($n5words\) to generate password
                return
            fi
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
            echo "    64bit_d: dict words with numbers (ex: jaws4both5cram7Cook0limp)"
            echo "    96bit:   base64-encoded          (ex: nl8N8CEby5KRjupi)"
            echo "    120bit:  base64-encoded          (ex: WzdM2dOprg8AVeTFUhKl)"
            echo "    240bit:  base64-encoded          (ex: PrWBrBA+vfX34eAUMW1owbTvmNcwPVW8+W9U8fgu)"
            ;;
    esac
}
