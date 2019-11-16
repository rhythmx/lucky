logmsg mkgif::debug setting up mkgif 

# Convert MP4 into gif suitable for web
function mkgif() {
    if [ -f "$1" ]; then
	dirn=$(dirname "$1")
	filen=$(basename "$1")
	tmpd="${dirn}/tmpdir.${filen}"
	outf="${dirn}/${filen}.gif"
	#mkdir "$tmpd"

	# _mkgif_ffmpeg "$dirn" "$filen" "$outf"
	ffmpeg -i "${dirn}/${filen}" -r 20 -vf scale=640:-1 -f image2pipe -vcodec ppm  - | convert -delay 5 -loop 0 - "$outf"
	
	#rmdir -rf "${tmpd}"
    else
	echo "file not found: $1"
    fi
}

function _mkgif_ffmpeg() {
    dirn=$1
    filen=$2
    outf=$3
}
