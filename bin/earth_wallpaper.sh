#!/bin/bash

# Desired GOES resolution
# GOES_RESOLUTION="21696x21696"   # 54 MB ea.
GOES_RESOLUTION="10848x10848" # 18 MB ea.
# GOES_RESOLUTION="5424x5424"
# GOES_RESOLUTION="1808x1808"
# GOES_RESOLUTION="678x678"
# GOES_RESOLUTION="339x339"
GOES_PATH="https://cdn.star.nesdis.noaa.gov/GOES16/ABI/FD/GEOCOLOR"

# Temporary file to store the downloaded image
TEMP_IMAGES=$(mktemp -d)

# Target dimensions
DIM_SCREEN1="5120x1440"
DIM_SCREEN1X2="10240x2880"
DIM_SCREEN2="1920x1200"


function GOES_image_name() {
  local n=$1
  local fname="_GOES16-ABI-FD-GEOCOLOR-${GOES_RESOLUTION}.jpg"
  local then=$(date -u -d "$n seconds ago" +"%Y%j%H%M")
  local secs=${then: -2}
  secs=$(( secs / 10 * 10))
  printf "%s%02d%s" "${then%??}" "$secs" "$fname"
}

# Main loop
while true; do
  IMAGE_NAME=$(GOES_image_name 1800) # add 15 minute delay to give time for it to show up
  IMAGE_URL="$GOES_PATH/$IMAGE_NAME"
  TEMP_IMAGE="$TEMP_IMAGES/$IMAGE_NAME"

  # Download the image (if it's not already downloaded)
  if find "$TEMP_IMAGE" -mmin -5 | grep -q .; then
    echo "Reusing current image"
  else
    curl -o "$TEMP_IMAGE" "$IMAGE_URL"
  fi

  # Resize and recenter the image (TODO: recenter based off input resolution)
  SCREEN1IMG="$TEMP_IMAGE.screen1.jpg"
  SCREEN2IMG="$TEMP_IMAGE.screen2.jpg"
  # STEP1IMG="$TEMP_IMAGE.step1.jpg"
  # test -f "$STEP1IMG" || convert "$TEMP_IMAGE" -interpolative-resize 10848x10848  -interpolate average9 "$STEP1IMG"
  test -f "$SCREEN1IMG" || convert "$TEMP_IMAGE" -gravity center -crop ${DIM_SCREEN1}-2045-3100 +repage "$SCREEN1IMG"
  test -f "$SCREEN2IMG" || convert "$TEMP_IMAGE" -gravity center -crop ${DIM_SCREEN2}-2045-3100 +repage "$SCREEN2IMG"

  # order is important, check output of `xrandr --listmonitors` to see what order the files should be in
  # Set the wallpaper with feh
  feh --bg-center --no-fehbg "$SCREEN2IMG" "$SCREEN1IMG"
  
  # Wait for 5 minutes (300 seconds) before repeating
  sleep 300
done
