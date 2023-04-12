#!/bin/sh
#
# __ __| |           |  /_) |     ___|             |           |
#    |   __ \   _ \  ' /  | |  / |      _ \ __ \   |      _` | __ \   __|
#    |   | | |  __/  . \  |   <  |   |  __/ |   |  |     (   | |   |\__ \
#   _|  _| |_|\___| _|\_\_|_|\_\\____|\___|_|  _| _____|\__,_|_.__/ ____/
#
# BOOTSTRAP module playlogo.

# This module streams the framebuffer kms to a listening udp client
#
# $1 is destination client ipaddress and port e.g. : 192.168.2.1:23000.
# Can be specified in doer_list as "ffstream@192.168.2.1:23000"
#
# Command line at client could be : ffplay -f mpegts udp://(host ip):23000
#------------------------------------------------------------------------------

SCRIPT_NAME=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_NAME")
source "$SCRIPT_DIR/../../scripts/tkgl_path"

# Settings ---------------------------------------------------------------------

[ "$1x" == "x" ] && exit 1

# temporary script to be launched separately
TEMP_SCRIPT=/tmp/ffstream.tmp.sh

# Time before launching the ffmpeg command within the temp script
WAIT_TIME=30

# Destination URL
URL=$1

# Create the temporary script in tmp
echo "PATH=$PATH:$TKGL_BIN">$TEMP_SCRIPT
echo "LD_LIBRARY_PATH=$TKGL_LIB:usr/lib">>$TEMP_SCRIPT

# 0 = 90 counter-clockwise and vertical flip (default)
# 1 = 90 clockwise
# 2 = 90 counter-clockwise
# 3 = 90 clockwise and vertical flip
# No sound

# MPC X orientation is different
ROTATE=,transpose=1
[ "$DEVICE" == "MPC X" ] && ROTATE=

FILTER=hwdownload,format=bgr0$ROTATE

CMDLINE="-y -f kmsgrab -fflags nobuffer -i - -vf $FILTER -c:v libx264rgb -preset ultrafast -an -f mpegts udp://$URL"
#echo "ffmpeg command line parameters : $CMDLINE">>$TKGL_LOG

echo "sleep $WAIT_TIME">>$TEMP_SCRIPT
echo "ffmpeg -nostats -loglevel 0 $CMDLINE">>$TEMP_SCRIPT
echo "Temporary $TEMP_SCRIPT script created :">>$TKGL_LOG
cat $TEMP_SCRIPT>>$TKGL_LOG

# Launch script
sh $TEMP_SCRIPT &

#ffmpeg -y -f kmsgrab -fflags nobuffer -i - -vf $FILTER -c:v libx264rgb -preset ultrafast -an -f mpegts udp://$1
