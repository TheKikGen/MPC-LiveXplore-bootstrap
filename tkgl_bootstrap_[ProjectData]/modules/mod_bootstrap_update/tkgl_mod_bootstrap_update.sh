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

SCRIPT_NAME=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_NAME")
source "$SCRIPT_DIR/../../scripts/tkgl_path"

UPDATE_FLAG_FILE=$MOUNT_POINT/"Tkupdate.mpcpattern"
UPDATE_DIR=$SCRIPT_DIR/update
UPDATE_URL="https://github.com/TheKikGen/MPC-LiveXplore-bootstrap/archive/refs/heads/main.zip"
UPDATE_PACK_FILE=$SCRIPT_DIR/bootstrap-update.zip

# The user can export an empty pattern in the MPC app with that exact name
# to trig the update
# if the first paramter is "force" the update will go

[ -f "$UPDATE_FLAG_FILE" ] || [ "x$1" == "xforce" ] || exit

clean () {
  [ -f "$UPDATE_PACK_FILE" ] && rm $UPDATE_PACK_FILE
  [ -d "$UPDATE_DIR" ] && rm -rf $UPDATE_DIR
  [ -f "$UPDATE_FLAG_FILE" ] && rm $UPDATE_FLAG_FILE
}



clean
mkdir -p $UPDATE_DIR

$TKGL_BIN/curl -L $UPDATE_URL --output $UPDATE_PACK_FILE
if [ $? -ne 0 ]; then
  echo "Curl error when attempting to download update package at $UPDATE_URL" >>$TKGL_LOG
  clean
  exit 1
fi

unzip -o -d $UPDATE_DIR $UPDATE_PACK_FILE
if [ $? -ne 0 ]; then
  echo "Error when attempting to unzip package file $UPDATE_PACK_FILE" >>$TKGL_LOG
  clean
  exit 1
fi

cp -a "$UPDATE_DIR/MPC-LiveXplore-bootstrap-main"/* "$MOUNT_POINT"/
if [ $? -ne 0 ]; then
  echo "Error while copying bootstrap update files" >>$TKGL_LOG
  #clean
  exit 1
fi

ls -l -R "$UPDATE_DIR/MPC-LiveXplore-bootstrap-main"/* > $TKGL_LOGS/update.log

clean
reboot