
# Random utility functions that can probably be reused go here

function rand_ip() {
    net=${1:-0.0.0.0}
    mask=${2:-255.255.255.0}
    net_n=$(ip_to_int $net)
    mask_n=$(ip_to_int $mask)
    mask_inv_n=$(( ~($mask_n) ))

    temp_ip=$(( $(rand32) & $mask_inv_n ))
		temp_net=$(( $net_n & $mask_n ))
    echo $(int_to_ip $(( $temp_ip + $temp_net )))
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
    echo    $((  $1        & 255 ))
}

function rand32() {
    echo $(( ( ($RANDOM + $RANDOM) << 16) + $RANDOM + $RANDOM))
}

rand_hexchar() {
    printf "%02x" $(( $RANDOM % 256 ))
}

rand_hexstr() {
    len=$1
    for i in $(seq 1 $len); do
        rand_hexchar
    done
}

rand_uuid() {
    echo "$(rand_hexstr 4)-$(rand_hexstr 2)-$(rand_hexstr 2)-$(rand_hexstr 2)-$(rand_hexstr 6)"
}
