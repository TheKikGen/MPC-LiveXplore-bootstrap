#!/bin/sh
#
# __ __| |           |  /_) |     ___|             |           |
#    |   __ \   _ \  ' /  | |  / |      _ \ __ \   |      _` | __ \   __|
#    |   | | |  __/  . \  |   <  |   |  __/ |   |  |     (   | |   |\__ \
#   _|  _| |_|\___| _|\_\_|_|\_\\____|\___|_|  _| _____|\__,_|_.__/ ____/
#
# BOOTSTRAP script for MPCMAPPER LD_PRELOAD LIBRARY.

# This "low-level" library allows you to run a Force binary on a MPC hardware
# with all features enabled (and vice versa).

#------------------------------------------------------------------------------

SCRIPT_NAME=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT")

source $TKGL_PATH_FILE
echo "-------------------------------------------------------------------------" >>  $TKGL_LOG
echo "MODULE $SCRIPT_NAME" >> $TKGL_LOG
echo "-------------------------------------------------------------------------" >>  $TKGL_LOG


# Settings ---------------------------------------------------------------------

# bootstrap dir within the chroot
CHROOT_BOOTSTRAP=/etc/tkgl_bootstrap

# configuration file of mpcmapper.so
MPCMAPPER_CONFIG_FILE=map_live_force.conf

# mpcmapper command lien arguments
TKGL_ARGV="--tkgl_iamForce --tkgl_configfile=$CHROOT_BOOTSTRAP/conf/$MPCMAPPER_CONFIG_FILE"

# Mounting point of the Force OS tkgl internal img
# Use the /run directory
ROOT_DIR=/run/tkgl_root
# media root dir binding
ROOT_DIR_MEDIA=/run/tkgl_root_media

# ext4 root fs image name to mount
# Image must be copied at the root of the tkgl_bootstrap directory
ROOTFS_IMG_NAME="$TKGL_ROOT/rootfs_force-3.1.3.8.img"

echo "-------------------------------------------------------------------------" >>  $TKGL_LOG
echo "Settings" >> $TKGL_LOG
echo "-------------------------------------------------------------------------" >>  $TKGL_LOG
echo "Bootstrap directory  within the chroot  : $CHROOT_BOOTSTRAP"  >> $TKGL_LOG
echo "Configuration file of mpcmapper.so      : $MPCMAPPER_CONFIG_FILE"  >> $TKGL_LOG
echo "Mpcmapper command line arguments        : $TKGL_ARGV" >> $TKGL_LOG
echo "Mounting point of the Force OS img      : $ROOT_DIR"  >> $TKGL_LOG
echo "Root fs Force img file (ro)             : $ROOTFS_IMG_NAME" >>  $TKGL_LOG
echo "-------------------------------------------------------------------------" >>  $TKGL_LOG

# az01-internal partitions
AZ01_INTERNAL_PART=/dev/mmcblk2p7
AZ01_INERNAL_SD_PART=/dev/mmcblk0p1

# Settings directory. Used to protect the host settings
AZ01_INTERNAL_SETTINGS_MPC=/media/az01-internal/Settings/MPC
TKGL_SETTINGS_MPC=$TKGL_ROOT/Settings_MPC

# Virtual sd card
TKGL_AZ01_INTERNAL_SD=$TKGL_ROOT/force-internal-sd

# Crash info file
MPC_CRASHINFO=/media/az01-internal/Settings/MPC/MPC.crashinfo
# Message displayed in a popup when the MPC app start
MPC_MESSAGEINFO=/media/az01-internal/Settings/MPC/MPC.message

# $ dd if=/dev/zero of=~/theFile.img bs=1k count=1034064
# $ mkfs.ext4 ~/theFile.img
# cp -a to copy
# internal sd uuid : 6df1ed3a-f152-49ee-b7de-b3d9662ca920
# mkfs.ext4 ./sdcard.img -U 6df1ed3a-f152-49ee-b7de-b3d9662ca920 -E offset=$((8192*512))
# mount -o offset=$((8192*512)) ./sdcard.img /tmp/mnt1


# Prepare the chroot "Sandbox" -------------------------------------------------

echo "Prepare the chroot..." >>  $TKGL_LOG

# Show the Force splash screen
cat $TKGL_ROOT/force_splash.img>/dev/fb0

if [ ! -f "$ROOTFS_IMG_NAME" ]
then
   echo "$ROOTFS_IMG_NAME not found">>$TKGL_LOG
   exit
fi

# Check rw image before mounting
#e2fsck -pf $ROOTFS_IMG_NAME

# Mount image
mkdir -p $ROOT_DIR
echo "Mounting rootfs img : mount -o ro $ROOTFS_IMG_NAME $ROOT_DIR" >> $TKGL_LOG
mount -o ro $ROOTFS_IMG_NAME $ROOT_DIR

# Create the media binding directory
echo "Create $ROOT_DIR_MEDIA media binding" >> $TKGL_LOG
mkdir -p $ROOT_DIR_MEDIA
# change permissions in the rootfs img
chmod 1777 $ROOT_DIR_MEDIA
# bind internal to our rootfs to get a full rw media directory
mount --bind $ROOT_DIR_MEDIA $ROOT_DIR/media

# bind the host az01-internal, and bind again to protect MPC settings
echo "Create az01-internal binding at $TKGL_SETTINGS_MPC" >> $TKGL_LOG

mkdir -p $ROOT_DIR/media/az01-internal
mount --bind /media/az01-internal $ROOT_DIR/media/az01-internal
mkdir -p $TKGL_SETTINGS_MPC
mount --bind $TKGL_SETTINGS_MPC $AZ01_INTERNAL_SETTINGS_MPC


# Sanitary checks -------------------------------------------------------------

# clear pseudo-mounted disk in chroot  /media but az01-*
# We use rmdir here to avoid rm side effect. Dirs are empty when unbinded.
rmdir $(find $ROOT_DIR/media/* | grep -v az01-)

# Clear crash file
rm $ROOT_DIR$MPC_CRASHINFO

# Mount necessary file systems -------------------------------------------------

mount -t proc /proc $ROOT_DIR/proc
mount -t sysfs /sys $ROOT_DIR/sys
mount --rbind /run  $ROOT_DIR/run
mount --rbind /dev  $ROOT_DIR/dev
mount --bind /tmp   $ROOT_DIR/tmp

# Mount overlays /etc /var from the internal part ------------------------------

if [ [! -d $ROOT_DIR/media/az01-internal/system/etc/overlay ] || [ ! -d $ROOT_DIR/media/az01-internal/system/var/overlay  ] ]
then
  echo "Overlay directory not found within $ROOT_DIR/media/az01-internal/system">>$TKGL_LOG
  exit
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

# Bind user partitions in the chroot space-------------------------

# pseudo internal sd card
mkdir -p $TKGL_AZ01_INTERNAL_SD
mkdir -p $ROOT_DIR/media/az01-internal-sd
mount --bind $TKGL_AZ01_INTERNAL_SD  $ROOT_DIR/media/az01-internal-sd>>$TKGL_LOG

# search for mounted usb disks but the one containing our chroot to avoid bad manipulation...
MOUNT_LIST=$(lsblk -o MOUNTPOINT,PATH,SUBSYSTEMS,TYPE | grep '\S*usb.*part' | grep -Ev "$MOUNT_POINT" | cut -d' ' -f1)

if [ "x$MOUNT_LIST" != "x" ]
then
 for DISK_MOUNT_PATH in $MOUNT_LIST ; do
  # bind mounted usb disk into the chroot
  if [ "x$DISK_MOUNT_PATH" != "x" ]
  then
    echo "Bind $DISK_MOUNT_PATH  to $ROOT_DIR$DISK_MOUNT_PATH">>$TKGL_LOG
    chmod 777 $DISK_MOUNT_PATH
    mkdir -p $ROOT_DIR$DISK_MOUNT_PATH
    chmod 777 $ROOT_DIR$DISK_MOUNT_PATH
    mount --rbind $DISK_MOUNT_PATH  $ROOT_DIR$DISK_MOUNT_PATH
  fi
 done
fi

# start to chroot in the Force image -------------------------------------------

# Make our bootstrap space in the chroot at /etc/tkgl_bootstrap (overlay)
mkdir -p $ROOT_DIR$CHROOT_BOOTSTRAP
mount --rbind $TKGL_ROOT $ROOT_DIR$CHROOT_BOOTSTRAP>>$TKGL_LOG

# Prepare a welcome message
echo "Welcome to The Kikgen Labs world !">$ROOT_DIR$MPC_MESSAGEINFO

# chroot into our image
echo "chroot $ROOT_DIR sh $CHROOT_BOOTSTRAP/scripts/tkgl_chroot_launcher $CHROOT_BOOTSTRAP/lib/tkgl_mpcmapper.so /usr/bin/MPC $ARGV $TKGL_ARGV">>$TKGL_LOG
chroot $ROOT_DIR sh $CHROOT_BOOTSTRAP/scripts/tkgl_chroot_launcher $CHROOT_BOOTSTRAP/lib/tkgl_mpcmapper.so /usr/bin/MPC $ARGV $TKGL_ARGV
#shutdown
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
