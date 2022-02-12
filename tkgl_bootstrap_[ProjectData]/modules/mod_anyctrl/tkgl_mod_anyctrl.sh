#!/bin/sh
#
# __ __| |           |  /_) |     ___|             |           |
#    |   __ \   _ \  ' /  | |  / |      _ \ __ \   |      _` | __ \   __|
#    |   | | |  __/  . \  |   <  |   |  __/ |   |  |     (   | |   |\__ \
#   _|  _| |_|\___| _|\_\_|_|\_\\____|\___|_|  _| _____|\__,_|_.__/ ____/
#
# BOOTSTRAP script for ANYCTRL LD_PRELOAD LIBRARY.

SCRIPT_NAME=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_NAME")
source "$SCRIPT_DIR/../../scripts/tkgl_path"

# This "low-level" library allows you to set up any controller as a control
# surface to drive the MPC standalone application (FULL PRIVATE AND PUBLIC PORTS).
#------------------------------------------------------------------------------

# Enter here the name (or a substring)  of your external midi controller.
# You can use the command 'amidi -l' to find it

export ANYCTRL_NAME="nanoKEY Studio"

#------------------------------------------------------------------------------

# Launch MPC application as usual, but take command line difference in account
# The Force has one.., MPCs haven't. Don't know if this is important.
ARGV=""
[ "$DEVICE" == "Force" ] && ARGV="$@"

#------------------ original script start here---------------------------------
# find dfu util info
DFUUTILINFO=$(dfu-util -l | grep "0x08000000")

#if in dfu-update mode run firmware update script
[ "x$DFUUTILINFO" != "x" ] && sh /usr/share/Akai/SME0/Firmware/update.sh

export LD_PRELOAD=$TKGL_LIB/tkgl_anyctrl.so

if type systemd-inhibit >/dev/null 2>&1
then
    exec systemd-inhibit --what=handle-power-key /usr/bin/MPC $ARGV
else
    # Reduce the soft stack size limit to 1MiB (from the default 8MiB).  This
    # is used as the default stack size for new threads and since MPC is
    # locked in memory this memory is allocated.  Since the limit is read
    # before main, we cannot set it in the application and must do so here.
    ulimit -S -s 1024
    exec /usr/bin/MPC $ARGV
fi
