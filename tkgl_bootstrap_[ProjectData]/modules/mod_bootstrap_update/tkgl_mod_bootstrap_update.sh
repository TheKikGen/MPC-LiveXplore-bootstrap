#!/bin/sh
#
# __ __| |           |  /_) |     ___|             |           |
#    |   __ \   _ \  ' /  | |  / |      _ \ __ \   |      _` | __ \   __|
#    |   | | |  __/  . \  |   <  |   |  __/ |   |  |     (   | |   |\__ \
#   _|  _| |_|\___| _|\_\_|_|\_\\____|\___|_|  _| _____|\__,_|_.__/ ____/
#
# BOOTSTRAP script for MPC device.
# Bootstrap autoupdate from the github repository
#------------------------------------------------------------------------------
# Update can be done manually with the following command :
#
#  ssh root@192.168.2.25 "sh /media/TKGL_BOOTSTRAP/tkgl_bootstrap_[ProjectData]/modules/mod_bootstrap_update/tkgl_mod_bootstrap_update.sh force"


SCRIPT_NAME=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_NAME")

# TKGL_ Context variables
MOUNT_POINT="$SCRIPT_DIR/../../.."
TKGL_BIN="$SCRIPT_DIR/../../bin"
TKGL_LOGO="$SCRIPT_DIR/../../conf/tkgl_logo"
DOER_LIST="$SCRIPT_DIR/../../doer_list"

UPDATE_FLAG_FILE=$MOUNT_POINT/"Tkupdate.mpcpattern"
UPDATE_DIR=$SCRIPT_DIR/update
UPDATE_URL="https://github.com/TheKikGen/MPC-LiveXplore-bootstrap/archive/refs/heads/main.zip"
UPDATE_PACK_FILE=$SCRIPT_DIR/bootstrap-update.zip

#IamForce2 assets download
IAMFORCE_ROOTFS_IMG_GOOGLE_ID="15cWYw1HbnDBlseqmlPB4_l7IqChBX27I"
IAMFORCE_ROOTFS_IMG_FILE_NAME="$SCRIPT_DIR/../mod_iamforce2/force-assets/rootfs_force-3.2.3.3-update.img"

# The user can export an empty pattern in the MPC app with that exact name
# to trig the update
# if the first paramter is "force" the update will go

[ -f "$UPDATE_FLAG_FILE" ] || [ "x$1" == "xforce" ] || exit

# Script starts here
cat $TKGL_LOGO
echo ""
echo "TKGL BOOTSTRAP UPDATE SCRIPT"
echo "----------------------------------------------------------------------------------------"

# Check TKGL environment. We need curl...
if [ ! -f "$TKGL_BIN/curl" ]; then
  echo "Error : $TKGL_BIN/curl is missing. Can't proceed with the bootstrap update."
  exit 1
fi

# Clean function
clean () {
  [ -f "$UPDATE_PACK_FILE" ] && rm $UPDATE_PACK_FILE
  [ -d "$UPDATE_DIR" ] && rm -rf $UPDATE_DIR
  [ -f "$UPDATE_FLAG_FILE" ] && rm $UPDATE_FLAG_FILE
  [ -f "$DOER_LIST.bak" ] && rm $DOER_LIST.bak
}

echo ">> Stop MPC application..."

# stop MPC application
systemctl stop inmusic-mpc

clean

# Make a backup of doer_list
cp $DOER_LIST $DOER_LIST.bak 

# temp directory for downloads
mkdir -p $UPDATE_DIR

echo ">> Downloading update from Github, please wait..."

$TKGL_BIN/curl -L $UPDATE_URL --output $UPDATE_PACK_FILE
if [ $? -ne 0 ]; then
  echo "Curl error while attempting to download update package at $UPDATE_URL"
  clean
  exit 1
fi

echo ">> Decompressing files. Please wait..."

unzip $UPDATE_PACK_FILE -o -d $UPDATE_DIR
if [ $? -ne 0 ]; then
  echo "Error while attempting to unzip package file $UPDATE_PACK_FILE"
  clean
  exit 1
fi

echo ">> Copying files to the bootstrap directories. Please wait..."

echo "$UPDATE_DIR/MPC-LiveXplore-bootstrap-main/tkgl_bootstrap_[ProjectData]" "$MOUNT_POINT/"

cp -a "$UPDATE_DIR/MPC-LiveXplore-bootstrap-main/tkgl_bootstrap_[ProjectData]" "$MOUNT_POINT/"
if [ $? -ne 0 ]; then
  echo "Error while copying bootstrap update files"
  #clean
  exit 1
fi

#ls -l -R "$UPDATE_DIR/MPC-LiveXplore-bootstrap-main"/*

# Restore the doer_list file
cp $DOER_LIST.bak $DOER_LIST 
if [ $? -ne 0 ]; then
  echo "Error while restoring bootstrap $DOER_LIST file. The process will continue."
fi

clean

echo ""

if [ ! -f $IAMFORCE_ROOTFS_IMG_FILE_NAME ]; then
  echo ">> IamForce2 assets download from Google drive..."
  $TKGL_BIN/curl -o $IAMFORCE_ROOTFS_IMG_FILE_NAME -L "https://drive.google.com/uc?export=download&confirm=yes&id=$IAMFORCE_ROOTFS_IMG_GOOGLE_ID"
else
  echo "IamForce2 assets $IAMFORCE_ROOTFS_IMG_FILE_NAME already on smartcard."
fi
echo ""
echo ""
echo "Update finished correctly. Rebooting MPC..."
echo "May the IamForce be with you !"

reboot
