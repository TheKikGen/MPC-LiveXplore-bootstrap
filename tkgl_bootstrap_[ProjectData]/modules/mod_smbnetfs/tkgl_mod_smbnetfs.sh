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
# Parameters are mandatory in the following order :
# 
# ex : smbnetfs@"anonymous","","WORKGROUP","192.168.2.100","TERA4_2T"

# User name on the smb network (ex : "anonymous")
SMB_USER_NAME=$1

# Password (ex "" for empty)
SMB_USER_PWD=$2

# Domain name (ex : "WORKGROUP")
SMB_DOMAIN=$3

# SMB server IP or dns name (ex : "192.168.2.10")
SMB_SERVER_IP=$4

# SMB share (ex : "DISK1")
SMB_SHARE=$5

# Check parameters
if [ "x$SMB_USER_NAME" == "''x" ]
then
  echo "Fatal : parameter #1 (SMB_USER_NAME) missing.">>$TKGL_LOG
  echo $1
  exit
fi

if [ "x$SMB_USER_PWD" == "''x" ]
then
  echo "Warning : parameter #2 (SMB_USER_PWD) is empty.">>$TKGL_LOG
fi

if [ "x$SMB_DOMAIN" == "''x" ]
then
  echo "Fatal : parameter #3 (SMB_DOMAIN) missing.">>$TKGL_LOG
  exit
fi

if [ "x$SMB_SERVER_IP" == "''x" ]
then
  echo "Fatal : parameter #4 (SMB_SERVER_IP) missing.">>$TKGL_LOG
  exit
fi

if [ "x$SMB_SHARE" == "''x" ]
then
  echo "Fatal : parameter #5 (SMB_SHARE) missing.">>$TKGL_LOG
  exit
fi

echo "Parameters : $SMB_USER_NAME $SMB_USER_PWD $SMB_DOMAIN $SMB_SERVER_IP $SMB_SHARE">>$TKGL_LOG

# remove single quote
SMB_USER_NAME=$(echo $SMB_USER_NAME | tr -d '\047')
SMB_USER_PWD=$(echo $SMB_USER_PWD | tr -d '\047')
SMB_DOMAIN=$(echo $SMB_DOMAIN | tr -d '\047')
SMB_SERVER_IP=$(echo $SMB_SERVER_IP | tr -d '\047')
SMB_SHARE=$(echo $SMB_SHARE | tr -d '\047')

# To show the network within the MPC app, we use the sdcard root dir
NETWORK_MNT="$SCRIPT_DIR/SMBNet-internal"
NETWORK_SHARE="$MOUNT_POINT/SMBNet-$SMB_SHARE"
umount $NETWORK_MNT
umount $NETWORK_SHARE

# Clean previous shares
rmdir $MOUNT_POINT/SMBNet-*

mkdir -p $NETWORK_MNT
mkdir -p $NETWORK_SHARE

# Mount the home overlay if not already mounted
if [ -d "$HOME/.smb" ]
then
  echo "Home overlay already mounted. " >> $TKGL_LOG
else
# mount the HOME overlay (user is root and fs is read only)
mkdir -p "$SCRIPT_DIR/home/.work"
mount -t overlay overlay -o \
lowerdir="$HOME",\
upperdir="$SCRIPT_DIR/home/overlay",\
workdir="$SCRIPT_DIR/home/.work" \
"$HOME"

fi

# fix auth directive error if any
chmod 600 "$HOME/.smb/smbnetfs.auth"
killall -9 smbnetfs

# Launch smbnetfs
# NB : The static binary needs the "./libs"  in the current directory. Do not move them.

# Our internal smbnetfs mount point
umount $NETWORK_MNT
cd $SCRIPT_DIR/bin
./smbnetfs  -o log_file=$TKGL_LOG $NETWORK_MNT
if ps | grep smbnetfs | grep -v grep 
then 
  echo "smbnetfs successfully loaded">>$TKGL_LOG
else
  echo "Error while loading smbnetfs">>$TKGL_LOG
  exit 1
fi

# Prepare the smb share mouting point
SHARE_PATH="$NETWORK_MNT/$SMB_DOMAIN:$SMB_USER_NAME:$SMB_USER_PWD@$SMB_SERVER_IP/$SMB_SHARE"
echo "Share path is $SHARE_PATH">>$TKGL_LOG

# "cd" to the smb share to launch the smb share, then bind to root of sd card
cd "$SHARE_PATH"
if [ $? -ne 0 ]; then
  echo "Error while cd to $SHARE_PATH">> $TKGL_LOG
  umount $NETWORK_MNT
  umount $NETWORK_SHARE
  killall -9 smbnetfs
  exit 1
fi

mount --bind $PWD $NETWORK_SHARE
if [ $? -ne 0 ]; then
  echo "Fatal while binding $PWD with $NETWORK_SHARE">> $TKGL_LOG
  exit 1
fi

echo "SMB share available at $NETWORK_SHARE">>$TKGL_LOG 
