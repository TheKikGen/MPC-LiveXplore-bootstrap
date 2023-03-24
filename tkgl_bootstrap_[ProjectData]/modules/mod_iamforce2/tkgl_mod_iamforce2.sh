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

# the driver id can be passed in a command line argument in the DOER_LIST
# e.g. iamforce2@APCKEY25MK2

if [ "x$1" != "x" ]
then
  #remove parameter value from module name
  IAMFORCE_DRIVER_ID=$1
  echo "Parameter of $MODULE module is $1">>$TKGL_LOG
fi

# Midimapper Plugin - dummy
#IAMFORCE_DRIVER_ID="NONE"

# Midimapper Plugin for Akai APC Key 25 mk2
# IAMFORCE_DRIVER_ID="APCKEY25MK2"

# Midimapper Plugin for Akai APC Mii mk2
#IAMFORCE_DRIVER_ID="APCMINIMK2"

# Midimapper Plugin for Launchpad Mini Mk3
# IAMFORCE_DRIVER_ID="LPMK3"

# Midimapper Plugin for Launchpad X
#IAMFORCE_DRIVER_ID="LPX"

# Image file name (must be copied to force-assets directory)
FORCE_ROOTFS_IMAGE="rootfs_force-3.2.3.3-update.img"

# Overlay mounting function : make_overlay(low,up)
make_overlay() {

  target=$3
  [ "x$target" == "x" ] && target=$1

  #umount $target
  mkdir -p $1
  mkdir -p $2/merged
  mkdir -p $2/work
  
  mount -t overlay overlay -o lowerdir=$1,upperdir=$2/merged,workdir=$2/work $target
  if [ $? -ne 0 ]; then
    echo "Error while mounting overlay (l=$1,u=$2) $target . Abort." >>$TKGL_LOG
    return 1
  fi
  echo "Overlay (l=$1,u=$2) $target mounted !" >> $TKGL_LOG

}

# Do not launch the mod if we are running on a Force
# This is made for MPCs only.
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
# Will be created if not existing
OVERLAY_DIR=$ASSETS_DIR/internal-overlay

# Virtual sd card
# Will be created if not existing
TKGL_AZ01_INTERNAL_SD=$ASSETS_DIR/az01-internal-sd

# Settings directory. Used to protect the host settings
# Will be created if not existing
TKGL_SETTINGS_MPC=$ASSETS_DIR/Settings_MPC

# Splash screen is different for the MPC X (90 degrees rotation)
SPLASH_SCREEN=$ASSETS_DIR/force_splash270.data
[ "$DEVICE" == "MPC X" ] && SPLASH_SCREEN=$ASSETS_DIR/force_splash90.data

# Midimapper library
# Copied directly in the module directory
TMMBIN="$SCRIPT_DIR/tkgl_midimapper.so"

PLUGIN="$SCRIPT_DIR/tmm-IamForce-$IAMFORCE_DRIVER_ID.so"

# midimapper command line arguments
TKGL_ARGV="--tkplg=$PLUGIN"

# Mounting point of the Force OS tkgl internal img
# Use the /run directory
ROOT_DIR=/run/tkgl_root

# ext4 root fs Force update image
ROOTFS_IMG_NAME="$ASSETS_DIR/$FORCE_ROOTFS_IMAGE"

# Crash info files
MPC_CRASHINFO=/media/az01-internal/Settings/MPC/*.crashinfo

# Message displayed in a popup when the MPC app start
MPC_MESSAGEINFO=/media/az01-internal/Settings/MPC/MPC.message

# MPC_START sub shell
MPC_START_SHELL=/run/MPC_START

# MPC binary to run (relatively to mounted img)
MPCBIN="$ROOT_DIR/mnt/usr/bin/MPC"

echo "-------------------------------------------------------------------------" >>  $TKGL_LOG
echo "Settings" >> $TKGL_LOG
echo "-------------------------------------------------------------------------" >>  $TKGL_LOG
echo "Assets directory                        : $ASSETS_DIR"  >> $TKGL_LOG
echo "Mounting point of the Force OS img      : $ROOT_DIR/mnt"  >> $TKGL_LOG
echo "MPC binary                              : $MPCBIN" >>  $TKGL_LOG
echo "Root fs Force img file (ro)             : $ROOTFS_IMG_NAME" >>  $TKGL_LOG
echo "Midimapper path                         : $TMMBIN" >>  $TKGL_LOG
echo "Midimapper arguments                    : $TKGL_ARGV" >>  $TKGL_LOG
echo "-------------------------------------------------------------------------" >>  $TKGL_LOG

# Prepare Force context -------------------------------------------------

echo "Prepare Force context..." >>  $TKGL_LOG

# Show the splash screen
cat $SPLASH_SCREEN>/dev/fb0

# Mount force image, read only
mkdir -p $ROOT_DIR/mnt
umount $ROOT_DIR/mnt
mount -o ro $ROOTFS_IMG_NAME $ROOT_DIR/mnt
if [ $? -ne 0 ]; then
  echo "Error while mounting $ROOTFS_IMG_NAME $ROOT_DIR/mnt. Abort." >>$TKGL_LOG
  exit 1
fi
echo "Mounting rootfs img done ! mount -o ro $ROOTFS_IMG_NAME $ROOT_DIR/mnt" >> $TKGL_LOG

# Make our etc ovr on top of existing etc ovr at internal-sd

mkdir -p "$OVERLAY_DIR/etc"
mkdir -p "$OVERLAY_DIR/var"
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
#mount --bind  "$ROOT_DIR/mnt/boot" /boot
#  mount --bind  "$ROOT_DIR/mnt/usr" /usr
#mount --bind  "$ROOT_DIR/mnt/usr/lib" /usr/lib
#mount --bind  "$ROOT_DIR/mnt/usr/share" /usr/share
mount --bind "$ROOT_DIR/mnt/usr/share/Akai" "/usr/share/Akai"

# start Force  -------------------------------------------

# Prepare a welcome message
echo "Welcome to The Kikgen Labs world !">$MPC_MESSAGEINFO
echo "">>$MPC_MESSAGEINFO
echo "Rootfs image file    : $FORCE_ROOTFS_IMAGE">>$MPC_MESSAGEINFO
echo "Midimapper driver id : $IAMFORCE_DRIVER_ID">>$MPC_MESSAGEINFO

# Make a copy of our MPC binary
cp $MPCBIN /run/MPC

# Prepare a sub launch script
echo "#!/bin/sh">$MPC_START_SHELL
echo "LD_PRELOAD=$TMMBIN /run/MPC $ARGV $TKGL_ARGV">>$MPC_START_SHELL

# insure exec permission
chmod +x /run/MPC
chmod +x $TMMBIN
chmod +x $PLUGIN
chmod +x $MPC_START_SHELL

# Bind MPC with our launch script to continue
mount --bind $MPC_START_SHELL /usr/bin/MPC

# reload bus
#systemctl daemon-reload