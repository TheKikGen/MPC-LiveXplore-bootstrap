#!/bin/sh
#
# __ __| |           |  /_) |     ___|             |           |
#    |   __ \   _ \  ' /  | |  / |      _ \ __ \   |      _` | __ \   __|
#    |   | | |  __/  . \  |   <  |   |  __/ |   |  |     (   | |   |\__ \
#   _|  _| |_|\___| _|\_\_|_|\_\\____|\___|_|  _| _____|\__,_|_.__/ ____/
#
# BOOTSTRAP module kms plane to frame buffer real time redirection with ffmpeg.

# This module redirects kms plane buffer to the framebuffer 
# /dev/fb0 in realtime with ffmpeg.
#------------------------------------------------------------------------------

SCRIPT_NAME=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_NAME")
source "$SCRIPT_DIR/../../scripts/tkgl_path"

# Settings ---------------------------------------------------------------------

# temporary script to be launched separately
TEMP_SCRIPT=/tmp/kms2fb.tmp.sh

# Time before launching the ffmpeg command within the temp script
WAIT_TIME=30

# Create the temporary script in tmp
echo "PATH=$PATH:$TKGL_BIN">$TEMP_SCRIPT
echo "LD_LIBRARY_PATH=$TKGL_LIB:$LD_LIBRARY_PATH">>$TEMP_SCRIPT

#ffmpeg -y -nostats -loglevel 0 -nostdin -f kmsgrab -framerate 60 -fflags nobuffer -i - -vf 'hwdownload,format=bgr0' -pix_fmt bgra -f fbdev /dev/fb0

echo "sleep $WAIT_TIME">>$TEMP_SCRIPT
echo "ffmpeg -y -nostats -loglevel 0 -nostdin -f kmsgrab -framerate 60 -fflags nobuffer  -i - -vf 'hwdownload,format=bgr0' -pix_fmt bgra -f fbdev /dev/fb0">>$TEMP_SCRIPT
echo "Temporary $TEMP_SCRIPT script created :">>$TKGL_LOG
cat $TEMP_SCRIPT>>$TKGL_LOG

# Launch script
sh $TEMP_SCRIPT &
