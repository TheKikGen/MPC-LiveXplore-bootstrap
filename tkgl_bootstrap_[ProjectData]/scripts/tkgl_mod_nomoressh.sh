#!/bin/sh
#
# __ __| |           |  /_) |     ___|             |           |
#    |   __ \   _ \  ' /  | |  / |      _ \ __ \   |      _` | __ \   __|
#    |   | | |  __/  . \  |   <  |   |  __/ |   |  |     (   | |   |\__ \
#   _|  _| |_|\___| _|\_\_|_|\_\\____|\___|_|  _| _____|\__,_|_.__/ ____/
#
# BOOTSTRAP script for MPC device.
# Disable temporariy the ssh server

source $TKGL_PATH_FILE

echo "*** $0 module">>$TKGL_LOG

systemctl stop sshd.service
echo "systemctl stop sshd.service done !">>$TKGL_LOG
