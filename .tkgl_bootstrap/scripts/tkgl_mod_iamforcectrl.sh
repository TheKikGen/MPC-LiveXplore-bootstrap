#!/bin/sh
#
# __ __| |           |  /_) |     ___|             |           |
#    |   __ \   _ \  ' /  | |  / |      _ \ __ \   |      _` | __ \   __|
#    |   | | |  __/  . \  |   <  |   |  __/ |   |  |     (   | |   |\__ \
#   _|  _| |_|\___| _|\_\_|_|\_\\____|\___|_|  _| _____|\__,_|_.__/ ____/
#
# BOOTSTRAP script for ANYCTRL LD_PRELOAD LIBRARY.

# This "low-level" library allows you to run a Force binary with a mpc
# with all features enabled. We do not distribute the binary.

# Enter here the name (or a substring)  of your external midi controller.
# You can use the command 'amidi -l' to find it

export ANYCTRL_NAME="nanoKEY Studio"

#------------------------------------------------------------------------------
# NB : We totally ignore the DFU mode here.

source $TKGL_PATH_FILE
FORCE_BIN=/media/tkgl/MPCF-306

ARGV="$@"

export LD_PRELOAD=$TKGL_LIB/tkgl_iamforcectrl.so

if type systemd-inhibit >/dev/null 2>&1
then
    exec systemd-inhibit --what=handle-power-key $FORCE_BIN $ARGV $ARGV
else
    # Reduce the soft stack size limit to 1MiB (from the default 8MiB).  This
    # is used as the default stack size for new threads and since MPC is
    # locked in memory this memory is allocated.  Since the limit is read
    # before main, we cannot set it in the application and must do so here.
    ulimit -S -s 1024
    exec $FORCE_BIN $ARGV
fi