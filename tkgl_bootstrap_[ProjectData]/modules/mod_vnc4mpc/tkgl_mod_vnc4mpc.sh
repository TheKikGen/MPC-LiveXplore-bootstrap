#!/bin/sh
#
# __ __| |           |  /_) |     ___|             |           |
#    |   __ \   _ \  ' /  | |  / |      _ \ __ \   |      _` | __ \   __|
#    |   | | |  __/  . \  |   <  |   |  __/ |   |  |     (   | |   |\__ \
#   _|  _| |_|\___| _|\_\_|_|\_\\____|\___|_|  _| _____|\__,_|_.__/ ____/
#
# VNC4MPC : BOOTSTRAP module VNC server for MPC.

# This module redirects kms plane buffer to the framebuffer 
# /dev/fb0 in realtime with ffmpeg , and launch a special VNC server on the port 5900.
# Any VNC client can connect (VNCviewer, TightVNC, UltraVNC, ....)
#------------------------------------------------------------------------------

SCRIPT_NAME=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_NAME")
source "$SCRIPT_DIR/../../scripts/tkgl_path"

# Settings ---------------------------------------------------------------------

TOUCH_DEVICE="-t /dev/input/event1"
KBD_DEVICE_NODE="/dev/input/event2"
KBD_DEVICE=""

# keyboard events are at event2 usually...

if [ -e "$KBD_DEVICE_NODE" ]
then
  echo "Keyboard found at $KBD_DEVICE_NODE">>$TKGL_LOG
  KBD_DEVICE="-k $KBD_DEVICE_NODE"
fi

# temporary script to be launched separately
TEMP_SCRIPT=/tmp/vnc4mpc.tmp.sh

# Time before launching the ffmpeg command within the temp script
WAIT_TIME=30

# Create the temporary ffmpeg script in tmp
echo "export PATH=$PATH:$TKGL_BIN">$TEMP_SCRIPT
echo "export LD_LIBRARY_PATH=$TKGL_LIB:$LD_LIBRARY_PATH">>$TEMP_SCRIPT

# wait before launching everything
echo "sleep $WAIT_TIME">>$TEMP_SCRIPT

# Launch VNC server
# This is a special frame buffer version for 32 bits color depth + rotation
# Do not rotate if MPC X (90 degrees rotation)
ROTATE="90"
[ "$DEVICE" == "MPC X" ] && ROTATE="0"

echo "framebuffer-vncserver -r $ROTATE $TOUCH_DEVICE $KBD_DEVICE&">>$TEMP_SCRIPT

# kms grab to frame buffer with ffmpeg. In the future, we could avoid that by reading kms directly...the lazy way
echo "ffmpeg -y -nostats -loglevel 0 -nostdin -f kmsgrab -framerate 100 -fflags nobuffer  -i - -vf 'hwdownload,format=bgr0' -pix_fmt bgra -f fbdev /dev/fb0">>$TEMP_SCRIPT

echo "Temporary $TEMP_SCRIPT script created :">>$TKGL_LOG
cat $TEMP_SCRIPT>>$TKGL_LOG

# Launch script
sh $TEMP_SCRIPT &
