#!/bin/sh
#
# __ __| |           |  /_) |     ___|             |           |
#    |   __ \   _ \  ' /  | |  / |      _ \ __ \   |      _` | __ \   __|
#    |   | | |  __/  . \  |   <  |   |  __/ |   |  |     (   | |   |\__ \
#   _|  _| |_|\___| _|\_\_|_|\_\\____|\___|_|  _| _____|\__,_|_.__/ ____/
#
# BOOTSTRAP module playlogo.

# This module plays a video logo at boot time with ffmpeg
#------------------------------------------------------------------------------

SCRIPT_NAME=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_NAME")
source "$SCRIPT_DIR/../../scripts/tkgl_path"

# Settings ---------------------------------------------------------------------

LOGO_FILE=tkgl_logo.mp4

if [ -f "$SCRIPT_DIR/$LOGO_FILE" ]
then
  echo "Playing the logo file $SCRIPT_DIR/$LOGO_FILE." >> $TKGL_LOG
else
  echo "$SCRIPT_DIR/$LOGO_FILE logo file not found. Abort." >> $TKGL_LOG
  exit 1
fi

PATH=$PATH:$TKGL_BIN
LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$TKGL_LIB

# With sound
# ffmpeg -i $SCRIPT_DIR/$LOGO_FILE -f alsa default -pix_fmt bgra -f fbdev /dev/fb0 &

# No sound
ffmpeg -i $SCRIPT_DIR/$LOGO_FILE -pix_fmt bgra -f fbdev /dev/fb0 &