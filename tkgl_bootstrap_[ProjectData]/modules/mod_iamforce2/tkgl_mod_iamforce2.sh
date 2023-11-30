#!/bin/sh
#
# _ __| |           |  /) |     ___|             |           |
#    |   _ \   _ \  ' /  | |  / |      _ \ _ \   |      ` | _ \   __|
#    |   | | |  _/  . \  |   <  |   |  __/ |   |  |     (   | |   |\_ \
#   |  _| |_|\___| _|\_\_|_|\_\\____|\___|_|  _| _____|\_,_|_.__/ ____/
#
# BOOTSTRAP script for MPCMAPPER LD_PRELOAD LIBRARY.

# This "low-level" library allows you to run a Force binary on a MPC hardware

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
FORCE_ROOTFS_IMAGE="rootfs_force-3.3.0.0-update.img"

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
MNT_DIR=$ASSETS_DIR/mnt

# ext4 root fs Force update image
ROOTFS_IMG_NAME="$ASSETS_DIR/$FORCE_ROOTFS_IMAGE"

# Crash info files
MPC_CRASHINFO=/media/az01-internal/Settings/MPC/*.crashinfo

# Remote screen. Not allowed for Force.
MPC_REMOTE_SCREEN=/media/az01-internal/Settings/MPC/remoteScreen

# Message displayed in a popup when the MPC app start
MPC_MESSAGEINFO=/media/az01-internal/Settings/MPC/MPC.message

# MPC_START sub shell
MPC_START_SHELL=$ASSETS_DIR/MPC_START

# MPC binary to run (relatively to mounted img)
MPCBIN="$MNT_DIR/usr/bin/MPC"

echo "-------------------------------------------------------------------------" >>  $TKGL_LOG
echo "Settings" >> $TKGL_LOG
echo "-------------------------------------------------------------------------" >>  $TKGL_LOG
echo "Assets directory                        : $ASSETS_DIR"  >> $TKGL_LOG
echo "Mounting point of the Force OS img      : $MNT_DIR"  >> $TKGL_LOG
echo "MPC binary                              : $MPCBIN" >>  $TKGL_LOG
echo "Root fs Force img file (ro)             : $ROOTFS_IMG_NAME" >>  $TKGL_LOG
echo "Midimapper path                         : $TMMBIN" >>  $TKGL_LOG
echo "Midimapper arguments                    : $TKGL_ARGV" >>  $TKGL_LOG
echo "-------------------------------------------------------------------------" >>  $TKGL_LOG

# Prepare Force context -------------------------------------------------

echo "Prepare Force context..." >>  $TKGL_LOG

# Force Image already mounted ?

if [ ! -f $MPCBIN ]
then
  # Show the splash screen
  cat $SPLASH_SCREEN>/dev/fb0

  # Mount force image, read only
  mkdir -p $MNT_DIR
  umount $MNT_DIR
  mount -o ro $ROOTFS_IMG_NAME $MNT_DIR
  if [ $? -ne 0 ]; then
    echo "Error while mounting $ROOTFS_IMG_NAME $MNT_DIR. Abort." >>$TKGL_LOG
    exit 1
  fi
  echo "Mounting rootfs img done ! mount -o ro $ROOTFS_IMG_NAME $MNT_DIR" >> $TKGL_LOG

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
  mount --bind "$MNT_DIR/usr/share/Akai" "/usr/share/Akai"

  # Prepare the laucnhing script
  touch $MPC_START_SHELL

  # insure exec permission
  #chmod +x $MPCBIN
  chmod +x $TMMBIN
  chmod +x $PLUGIN
  chmod +x $MPC_START_SHELL

  # Bind MPC with our launch script to continue
  mount --bind $MPC_START_SHELL /usr/bin/MPC

  echo "Welcome to The Kikgen Labs world !">$MPC_MESSAGEINFO

else
  echo "IamForce2 context already here (probably a 'new project' requested by user). Nothing to mount.">>$TKGL_LOG
  echo "Welcome to The Kikgen Labs world (new project) !">$MPC_MESSAGEINFO
fi

# start Force  -------------------------------------------

# remove eventual remoteScreen file that could stuck us in remote screen mode...
rm $MPC_REMOTE_SCREEN
# remove also core dump crash info files
rm $MPC_CRASHINFO

# Prepare a welcome message
echo "">>$MPC_MESSAGEINFO
echo "Rootfs image file    : $FORCE_ROOTFS_IMAGE">>$MPC_MESSAGEINFO
echo "Midimapper driver id : $IAMFORCE_DRIVER_ID">>$MPC_MESSAGEINFO

# Prepare a sub launch script (we rewrite it each time to update the command line)
echo "#!/bin/sh">$MPC_START_SHELL
echo "LD_PRELOAD=$TMMBIN $MPCBIN $ARGV $TKGL_ARGV"' "$@"'>>$MPC_START_SHELL
