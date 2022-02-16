#!/bin/sh
#
# __ __| |           |  /_) |     ___|             |           |
#    |   __ \   _ \  ' /  | |  / |      _ \ __ \   |      _` | __ \   __|
#    |   | | |  __/  . \  |   <  |   |  __/ |   |  |     (   | |   |\__ \
#   _|  _| |_|\___| _|\_\_|_|\_\\____|\___|_|  _| _____|\__,_|_.__/ ____/
#
# BOOTSTRAP module smbnetfs.

# This module mounts smb windows shares at the
# internal sdcard "Network (share name)" directory.
# smbnetfs is a specific distribution statically compiled for arm.
#------------------------------------------------------------------------------

SCRIPT_NAME=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_NAME")
source "$SCRIPT_DIR/../../scripts/tkgl_path"

# Settings ---------------------------------------------------------------------

# Source the configuration file
if [ -f "$SCRIPT_DIR/conf/tkgl_smb.conf" ]
then
  echo "$SCRIPT_DIR/conf/tkgl_smb.conf found" >> $TKGL_LOG
  cat "$SCRIPT_DIR/conf/tkgl_smb.conf" >> $TKGL_LOG
  source "$SCRIPT_DIR/conf/tkgl_smb.conf"
else
  echo "$SCRIPT_DIR/conf/tkgl_smb.conf missing." >> $TKGL_LOG
  exit 1
fi

# To show the network within the MPC app, we use the internal sd card
SYMLINK_PREFIX="/media/az01-internal-sd/Network"

# Our internal smbnetfs mount point
mkdir -p $SCRIPT_DIR/Network

# Mount the home overlay if not already mounted
if [ -d "$HOME/.smb" ]
then
  echo "Home overlay already mounted. " >> $TKGL_LOG
else
# mount the overlay

mkdir -p "$SCRIPT_DIR/home/.work"

mount -t overlay overlay -o \
lowerdir="$HOME",\
upperdir="$SCRIPT_DIR/home/overlay",\
workdir="$SCRIPT_DIR/home/.work" \
"$HOME"

fi

# The static binary needs the "./libs"  in the current directory
umount $SCRIPT_DIR/Network
cd $SCRIPT_DIR/bin
./smbnetfs  -o log_file=$TKGL_LOG $SCRIPT_DIR/Network

if ps | grep smbnetfs | grep -v grep ; then echo "smbnetfs is running" >> $TKGL_LOG ; fi

# Prepare the smb share mouting point

rm "$SYMLINK_PREFIX $SMB_SHARE"
SHARE_PATH=$SCRIPT_DIR/Network/$SMB_DOMAIN:$SMB_USER_NAME:$SMB_USER_PWD@$SMB_SERVER_IP/$SMB_SHARE

# "cd" to the smb share
cd $SHARE_PATH

if [ -d "$SHARE_PATH" ]
then
  ln -sf $PWD "$SYMLINK_PREFIX $SMB_SHARE"
else
  echo "Impossible to mount $SHARE_PATH"
fi
