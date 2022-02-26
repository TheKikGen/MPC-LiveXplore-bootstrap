#!/bin/sh
#
# _ __| |           |  /) |     ___|             |           |
#    |   _ \   _ \  ' /  | |  / |      _ \ _ \   |      ` | _ \   __|
#    |   | | |  _/  . \  |   <  |   |  __/ |   |  |     (   | |   |\_ \
#   |  _| |_|\___| _|\_\_|_|\_\\____|\___|_|  _| _____|\_,_|_.__/ ____/
#
# BOOTSTRAP script for MPCMAPPER LD_PRELOAD LIBRARY.

# This "low-level" library allows you to run a Force binary on a MPC hardware
# with all features enabled (and vice versa).

#------------------------------------------------------------------------------

SCRIPT_NAME=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_NAME")

source "$SCRIPT_DIR/../../scripts/tkgl_path"

# Overlay mounting function : make_overlay(low,up)
make_overlay() {

  target=$3
  [ "x$target" == "x" ] && target=$1

  #umount $target

  mount -t overlay overlay -o lowerdir=$1,upperdir=$2/merged,workdir=$2/work $target
  if [ $? -ne 0 ]; then
    echo "Error while mounting overlay (l=$1,u=$2) $target . Abort." >>$TKGL_LOG
    return 1
  fi
  echo "Overlay (l=$1,u=$2) $target mounted !" >> $TKGL_LOG

}

# Do not launch the mod if we are running on a Force
[ "$DEVICE" == "Force" ] && exit 0

# Check if the MPC process is already running, if so, exit

if  [ ! "x$(ps -a | grep "{MPC Main Thread} /usr/bin/MPC" | grep -v grep)" == "x" ]
then
  echo " MPC running...Aborting."
  exit 1
fi

# Settings ---------------------------------------------------------------------

# Where all force assets are
ASSETS_DIR=$SCRIPT_DIR/force-assets

# overlays
OVERLAY_DIR=$ASSETS_DIR/internal-overlay

# Settings directory. Used to protect the host settings
TKGL_SETTINGS_MPC=$ASSETS_DIR/Settings_MPC

# Virtual sd card
TKGL_AZ01_INTERNAL_SD=$ASSETS_DIR/az01-internal-sd

# Splash screen is different for the MPC X (90 degrees rotation)
SPLASH_SCREEN=$ASSETS_DIR/force_splash270_tkgl.data
[ "$DEVICE" == "MPC X" ] && SPLASH_SCREEN=$ASSETS_DIR/force_splash90_tkgl.data

# configuration file name of tkgl_mpcmapper.so
MPCMAPPER_CONFIG_FILE=$SCRIPT_DIR/conf/map_force.conf

# mpcmapper command line arguments
TKGL_ARGV="--tkgl_iamForce --tkgl_configfile=$MPCMAPPER_CONFIG_FILE"

# Mounting point of the Force OS tkgl internal img
# Use the /run directory
ROOT_DIR=/run/tkgl_root

# ext4 root fs image name to mount
# Image must be copied at the root of the tkgl_bootstrap directory
ROOTFS_IMG_NAME="$ASSETS_DIR/rootfs_force-3.1.3.8.img"

# Crash info files
MPC_CRASHINFO=/media/az01-internal/Settings/MPC/*.crashinfo

# Message displayed in a popup when the MPC app start
MPC_MESSAGEINFO=/media/az01-internal/Settings/MPC/MPC.message


echo "-------------------------------------------------------------------------" >>  $TKGL_LOG
echo "Settings" >> $TKGL_LOG
echo "-------------------------------------------------------------------------" >>  $TKGL_LOG
echo "Assets directory                        : $ASSETS_DIR"  >> $TKGL_LOG
echo "Mounting point of the Force OS img      : $ROOT_DIR/mnt"  >> $TKGL_LOG
echo "Root fs Force img file (ro)             : $ROOTFS_IMG_NAME" >>  $TKGL_LOG
echo "-------------------------------------------------------------------------" >>  $TKGL_LOG



# Prepare Force context -------------------------------------------------

echo "Prepare Force context..." >>  $TKGL_LOG

# Show the splash screen
cat $SPLASH_SCREEN>/dev/fb0

# Mount force image, read only

mkdir -p $ROOT_DIR/work
mkdir -p $ROOT_DIR/merged
mkdir -p $ROOT_DIR/mnt

# Mount Force image
umount $ROOT_DIR/mnt
mount -o ro $ROOTFS_IMG_NAME $ROOT_DIR/mnt
if [ $? -ne 0 ]; then
  echo "Error while mounting $ROOTFS_IMG_NAME $ROOT_DIR/mnt. Abort." >>$TKGL_LOG
  exit 1
fi
echo "Mounting rootfs img done ! mount -o ro $ROOTFS_IMG_NAME $ROOT_DIR/mnt" >> $TKGL_LOG

# Make an overlay with the 2 file systems
# but with Force fs as upper read-only  on top off MPC fs

# Force unmounting of existing /etc /var overlays
#umount -l /etc
#umount -l /var


#mount --rbind  "$ROOT_DIR/merged/run" /run
#mount --rbind  "$ROOT_DIR/merged/tmp" /tmp
#mount --rbind  "$ROOT_DIR/merged/dev" /dev

# Make our etc ovr on top of existing etc ovr at internal-sd
make_overlay "/etc" "$OVERLAY_DIR/etc"
make_overlay "/var" "$OVERLAY_DIR/var"

# Bind to separate settings from our host settings
mkdir -p $TKGL_SETTINGS_MPC
mount --bind $TKGL_SETTINGS_MPC /media/az01-internal/Settings/MPC

# Bind a virtual sd card
mkdir -p $TKGL_AZ01_INTERNAL_SD
mkdir -p /media/az01-internal-sd
mount --rbind $TKGL_AZ01_INTERNAL_SD  /media/az01-internal-sd

#  Mount read-only fs
mount --bind  "$ROOT_DIR/mnt/boot" /boot
mount --bind  "$ROOT_DIR/mnt/usr/bin" /usr/bin
mount --bind  "$ROOT_DIR/mnt/usr/lib" /usr/lib
mount --bind  "$ROOT_DIR/mnt/usr/share" /usr/share



# rebind all ro directories
# mount --rbind  "$ROOT_DIR/merged/boot" /boot
# mount --rbind  "$ROOT_DIR/merged/usr/bin" /usr/bin
# mount --rbind  "$ROOT_DIR/merged/usr/lib" /usr/lib
# mount --rbind  "$ROOT_DIR/merged/usr/share" /usr/share
# systemctl daemon-reload
#
# make_overlay "$ROOT_DIR/mnt:/" "$ROOT_DIR"  "$ROOT_DIR/merged"
#
#
# exit

# start Force  -------------------------------------------

# Prepare a welcome message
echo "Welcome to The Kikgen Labs world !">$MPC_MESSAGEINFO
LD_PRELOAD=$TKGL_LIB/tkgl_mpcmapper.so exec /usr/bin/MPC $ARGV $TKGL_ARGV > $TKGL_LOGS/iamforce.log
#LD_PRELOAD=$TKGL_LIB/tkgl_mpcmapper.so /usr/bin/MPC $ARGV $TKGL_ARGV > $TKGL_LOGS/iamforce.log
