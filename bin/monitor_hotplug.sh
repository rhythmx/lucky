#!/bin/bash
#
# Do NOT install this file with regular user writable permissions. It
# will be called by root from udev events.
#
# Automatically call this script on changes to connected displays and
# xrandr will setup an appropriate config.

# Here we have two external displays that we use. DP-2 is the docking
# station display port, VGA1 is the projector port on the laptop
# itself.

# debug log
exec >> /var/log/monitor_hotplug.log
exec 2>&1
set -x

export DISPLAY=:0.0
export XAUTHORITY=/home/sean/.Xauthority

stat_file(){ printf "/sys/class/drm/card0-%s/status" $1; }

xr_args="--output LVDS1 --primary --auto"
d=$(cat $(stat_file "DP-2"))
if [ "$d" = disconnected ]; then
    xr_args="${xr_args} --output DP2 --off"
elif [ "$d" = connected ]; then
    xr_args="${xr_args} --output DP2 --preferred --left-of LVDS1"
fi
p=$(cat $(stat_file VGA-1))
if [ "$p" = disconnected ]; then
    xr_args="${xr_args} --output VGA1 --off"
elif [ "$p" = connected ]; then
    xr_args="${xr_args} --output VGA1 --above LVDS1 --auto"
fi

echo xrandr $xr_args

/usr/bin/xrandr $xr_args

