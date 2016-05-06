# Wrappers around youtube_dl for easy  watching and archiving of video links

[[ $- != *i* ]] && return

function youtuber-is-id() {
    id="$1"; shift
    echo $id | grep -Po '^[a-zA-Z0-9-_]{11}$' >/dev/null && return 0
    return 1
}

function youtuber-id-from-url() {
    url="$1"; shift
    
    # Example URLs
    # https://www.youtube.com/watch?v=IkS5rfptd3M
    # https://www.youtube.com/watch?v=ZbjyuDYtAtk&feature=youtu.be
    # https://www.youtube.com/watch?v=rvhrngjKWzw&list=WL&index=4
    if $(echo $url | grep 'youtu.be' >/dev/null ); then
	echo $(echo $url | grep -Po '.be/[^&\?]{11}' | sed -e 's/.be\///')
    else
	echo $(echo $url | grep -Po 'v=[^&\?]+' | sed -e 's/v=//')
    fi
}

function youtuber() {

    # Snag the id
    arg="$1"; shift
    if youtuber-is-id "$arg"; then
	id="$arg"
    else
	id=$(youtuber-id-from-url "$arg")
    fi

    format="${HOME}/Videos/%(extractor)s/%(uploader)s/%(upload_date)s - %(title)s [%(format)s] - %(id)s.%(ext)s"
    url="https://www.youtube.com/watch?v=${id}" 

    youtube-dl --no-overwrites --write-description --write-info-json --write-sub --output "$format" "$url" 2>&1 

}

function youtuber-output-file() {
    txt="$1"; shift

    file=$( echo $txt | grep -Po 'Destination:\s+.*\s*$' | sed -e 's/Destination: //')
    
    if [ -e "$file" ]; then
	echo "$file"
    else
	id=$( echo $txt | grep -Po '[a-zA-Z0-9-_]{11}: Extracting video information' | sed -e 's/:.*//')
	find "${HOME}/Videos/" -name "*${id}*" 2>/dev/null | grep -vP 'description$' | grep -vP 'info.json$' | grep -vP 'srt$'
    fi
}

function youtuber-watch() {
    res=$(youtuber "$*")
    file=$(youtuber-output-file "$res")
    mplayer "$file"
}

function youtuber-towatch() {
    res=$(youtuber "$*")
    file=$(youtuber-output-file "$res")
    echo "$file" >> $HOME/Videos/To\ Watch.txt
}

function ytw() {
    youtuber-watch "$(xclip -o)"
} 

function yttw() {
    youtuber-towatch "$(xclip -o)"
}
