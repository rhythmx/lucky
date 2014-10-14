
# Just a quicky set of functions for dealing with ip addresses on the cmd line

function rand_ip() {
    ip=$1
    mask=$2

    echo $( int_to_ip $(( $(ip_to_int $ip) + (~($(ip_to_int $mask)) & $(rand32) ) )) )
}

function ip_to_int() {
    ctr=3
    sum=0
    for num in `echo $1 | tr '.' ' '`; do
	sum=$(( $sum + ( $num << ( $ctr * 8))))
	ctr=$(( $ctr - 1 ))
    done
    echo $sum
}

function int_to_ip() {
    echo -n $(( ($1 >> 24) & 255 ))
    echo -n '.'
    echo -n $(( ($1 >> 16) & 255 ))
    echo -n '.'
    echo -n $(( ($1 >>  8) & 255 ))
    echo -n '.'
    echo   $((  $1        & 255 ))
}

function rand32() {
    echo $(( ( ($RANDOM + $RANDOM) << 16) + $RANDOM + $RANDOM))
}
