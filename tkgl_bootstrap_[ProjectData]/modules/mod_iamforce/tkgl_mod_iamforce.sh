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

echo "-------------------------------------------------------------------------" >>  $TKGL_LOG
echo "MODULE $SCRIPT_NAME" >> $TKGL_LOG
echo "-------------------------------------------------------------------------" >>  $TKGL_LOG

# Do not launch the mod if we are running on a Force
[ "$DEVICE" == "Force" ] && exit 0

# Check if the MPC process is already running, if so, exit

if  [ ! "x$(ps -a | grep "{MPC Main Thread} /usr/bin/MPC" | grep -v grep)" == "x" ]
then
  echo " MPC running...Aborting."
  exit 1
fi

# Where all force assets are
ASSETS_DIR=$SCRIPT_DIR/force-assets

# Splash screen is different for the MPC X (90 degrees rotation)
SPLASH_SCREEN=$ASSETS_DIR/force_splash270_tkgl.data
[ "$DEVICE" == "MPC X" ] && SPLASH_SCREEN=$ASSETS_DIR/force_splash90_tkgl.data

# Settings ---------------------------------------------------------------------

# bootstrap dir within the chroot
CHROOT_BOOTSTRAP=/etc/tkgl_bootstrap

# configuration file name of mpcmapper.so within the chroot
MPCMAPPER_CONFIG_FILE=$CHROOT_BOOTSTRAP/modules/mod_iamforce/conf/map_force.conf

# mpcmapper command line arguments
TKGL_ARGV="--tkgl_iamForce --tkgl_configfile=$MPCMAPPER_CONFIG_FILE"

# Mounting point of the Force OS tkgl internal img
# Use the /run directory
ROOT_DIR=/run/tkgl_root

# media root dir binding
ROOT_DIR_MEDIA=/run/tkgl_root_media

# ext4 root fs image name to mount
# Image must be copied at the root of the tkgl_bootstrap directory
ROOTFS_IMG_NAME="$ASSETS_DIR/rootfs_force-3.1.3.8.img"

echo "-------------------------------------------------------------------------" >>  $TKGL_LOG
echo "Settings" >> $TKGL_LOG
echo "-------------------------------------------------------------------------" >>  $TKGL_LOG
echo "Bootstrap directory  within the chroot  : $CHROOT_BOOTSTRAP"  >> $TKGL_LOG
echo "Configuration file of mpcmapper.so      : $MPCMAPPER_CONFIG_FILE"  >> $TKGL_LOG
echo "Mpcmapper command line arguments        : $TKGL_ARGV" >> $TKGL_LOG
echo "Mounting point of the Force OS img      : $ROOT_DIR"  >> $TKGL_LOG
echo "Root fs Force img file (ro)             : $ROOTFS_IMG_NAME" >>  $TKGL_LOG
echo "-------------------------------------------------------------------------" >>  $TKGL_LOG

# Settings directory. Used to protect the host settings
TKGL_SETTINGS_MPC=$ASSETS_DIR/Settings_MPC

# Virtual sd card
TKGL_AZ01_INTERNAL_SD=$ASSETS_DIR/internal-sd

# Crash info files
MPC_CRASHINFO=/media/az01-internal/Settings/MPC/*.crashinfo

# Message displayed in a popup when the MPC app start
MPC_MESSAGEINFO=/media/az01-internal/Settings/MPC/MPC.message


# Prepare the chroot "Sandbox" -------------------------------------------------

echo "Prepare the chroot..." >>  $TKGL_LOG

# Show the splash screen
cat $SPLASH_SCREEN>/dev/fb0


if [ ! -f "$ROOTFS_IMG_NAME" ]
then
   echo "$ROOTFS_IMG_NAME not found">>$TKGL_LOG
   exit 1
fi

# Mount force image, read only
mkdir -p $ROOT_DIR
echo "Mounting rootfs img : mount -o ro $ROOTFS_IMG_NAME $ROOT_DIR" >> $TKGL_LOG
mount -o ro $ROOTFS_IMG_NAME $ROOT_DIR

# Make the media binding directory
echo "Create $ROOT_DIR_MEDIA media binding" >> $TKGL_LOG
mkdir -p $ROOT_DIR_MEDIA
mkdir -p $TKGL_AZ01_INTERNAL_SD
mkdir -p $TKGL_SETTINGS_MPC

# Bind our media directory with the true /media
mount --rbind /media $ROOT_DIR_MEDIA

# Bind our pseudo sd card over our media directory (beeing /media)
mount --rbind $TKGL_AZ01_INTERNAL_SD  $ROOT_DIR_MEDIA/az01-internal-sd

# Bind to separate settings from our host settings
mount --rbind $TKGL_SETTINGS_MPC $ROOT_DIR_MEDIA/az01-internal/Settings/MPC

# Finally bind with the chroot /media
mount --rbind $ROOT_DIR_MEDIA $ROOT_DIR/media

# bind the MPC bin to our bin
#mount --bind $ROOT_DIR/usr/bin/MPC /usr/bin/MPC




# Sanitary checks -------------------------------------------------------------

# Clear crash files
rm $ROOT_DIR$MPC_CRASHINFO

# Mount necessary file systems -------------------------------------------------

mount -t proc /proc $ROOT_DIR/proc
mount -t sysfs /sys $ROOT_DIR/sys
mount --rbind /run  $ROOT_DIR/run
mount --rbind /dev  $ROOT_DIR/dev
mount --bind /tmp   $ROOT_DIR/tmp

# Power supply faking ----------------------------------------------------------
# The Force checks the power status permanently, so the usage on battery is
# not possible, notably on the Live, Live2.
# Here we fake the /sys/class/power_supply

echo "1" > /tmp/value-1
echo "100" > /tmp/value-100
echo "Full" > /tmp/value-full
echo "18608000" > /tmp/value-voltnow

PWS_DIR=$ROOT_DIR/sys/class/power_supply/
mount --bind /tmp/value-1       $PWS_DIR/az01-ac-power/online
mount --bind /tmp/value-voltnow $PWS_DIR/az01-ac-power/voltage_now
mount --bind /tmp/value-1       $PWS_DIR/sbs-3-000b/present
mount --bind /tmp/value-full    $PWS_DIR/sbs-3-000b/status
mount --bind /tmp/value-100     $PWS_DIR/sbs-3-000b/capacity

# Mount overlays /etc /var from the internal part ------------------------------
echo $ROOT_DIR/media/az01-internal/system/etc/overlay
if [ !  -d "$ROOT_DIR/media/az01-internal/system/etc/overlay" ] || [ ! -d "$ROOT_DIR/media/az01-internal/system/var/overlay"  ]
then
  echo "Overlay directory not found within $ROOT_DIR/media/az01-internal/system">>$TKGL_LOG
  exit 1
fi


# /etc
mount -t overlay overlay -o \
lowerdir=$ROOT_DIR/etc,\
upperdir=$ROOT_DIR/media/az01-internal/system/etc/overlay,\
workdir=$ROOT_DIR/media/az01-internal/system/etc/.work \
$ROOT_DIR/etc>>$TKGL_LOG

# /var
mount -t overlay overlay -o \
lowerdir=$ROOT_DIR/var,\
upperdir=$ROOT_DIR/media/az01-internal/system/var/overlay,\
workdir=$ROOT_DIR/media/az01-internal/system/var/.work \
$ROOT_DIR/var>>$TKGL_LOG

# start to chroot in the Force image -------------------------------------------

# Make our bootstrap space in the chroot at /etc/tkgl_bootstrap
mkdir -p $ROOT_DIR$CHROOT_BOOTSTRAP
mount --rbind $TKGL_ROOT $ROOT_DIR$CHROOT_BOOTSTRAP>>$TKGL_LOG

# Prepare a welcome message
echo "Welcome to The Kikgen Labs world !">$ROOT_DIR$MPC_MESSAGEINFO

# Prepare the launch script within the chroot
# then chroot into our image

cat << EOF | chroot $ROOT_DIR
ulimit -S -s 1024
LD_PRELOAD=$CHROOT_BOOTSTRAP/lib/tkgl_mpcmapper.so exec /usr/bin/MPC $ARGV $TKGL_ARGV
#EOF

shutdown

# umount fs --------------------------------------------------------------------
# umount $ROOT_DIR/tmp
# umount $ROOT_DIR/dev
# umount $ROOT_DIR/run
# umount $ROOT_DIR/sys
# umount $ROOT_DIR/proc
# umount $ROOT_DIR/var
# umount $ROOT_DIR/etc
# umount $ROOT_DIR$CHROOT_BOOTSTRAP
# umount $ROOT_DIR
