#!/bin/sh
#
# __ __| |           |  /_) |     ___|             |           |
#    |   __ \   _ \  ' /  | |  / |      _ \ __ \   |      _` | __ \   __|
#    |   | | |  __/  . \  |   <  |   |  __/ |   |  |     (   | |   |\__ \
#   _|  _| |_|\___| _|\_\_|_|\_\\____|\___|_|  _| _____|\__,_|_.__/ ____/
#
# BOOTSTRAP module rtpmidid.

# This module launch avahi and rtp midi as a daemon on Force and MPC hardware
# Credit to David Moreno for rtpmidi binaries.
# Check the rtpmidi project on github : https://github.com/davidmoreno/rtpmidid

#------------------------------------------------------------------------------

SCRIPT_NAME=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_NAME")
source "$SCRIPT_DIR/../../scripts/tkgl_path"

# Settings ---------------------------------------------------------------------

# exit if no settings present for the bus (must exists in the update img)

if [ -f "/etc/dbus-1/system-local.conf" ]
then
  echo "/etc/dbus-1/system-local.conf present in the update image." >> $TKGL_LOG
else
  echo "/etc/dbus-1/system-local.conf missing. Download a more recent update image. Aborting." >> $TKGL_LOG
  exit 1
fi

cat /etc/dbus-1/system-local.conf >> $TKGL_LOG

# Stop Akai network midi
# systemctl stop az01-network-midi

# Mount 2nd /etc overlays (the first one is at /media/az01-internal/system)
# this will avoid /etc pollution on the lower etc overlay
mkdir -p $SCRIPT_DIR/etc/overlay
mkdir -p $SCRIPT_DIR/etc/.work

mount -t overlay overlay -o \
lowerdir=/etc,\
upperdir=$SCRIPT_DIR/etc/overlay,\
workdir=$SCRIPT_DIR/etc/.work \
/etc

# Add avahi user and group (will be copied on our etc overlay)
#adduser -D  -S -h /var/run/avahi-daemon -g "Avahi mDNS daemon" avahi avahi >>  $TKGL_LOG

AVAHI_USER="avahi:x:1011:1011:Avahi mDNS daemon:/var/run/avahi-daemon:/bin/false"
AVAHI_GROUP="avahi:x:1011:avahi"

grep "avahi" /etc/passwd || echo "$AVAHI_USER"  | tee -a  /etc/passwd
grep "avahi" /etc/group  || echo "$AVAHI_GROUP" | tee -a  /etc/group

# Add avahi midi libs in the lib path
export LD_LIBRARY_PATH=$SCRIPT_DIR/lib:$LD_LIBRARY_PATH

# Make system directories
$SCRIPT_DIR/sbin/avahi-daemon -f /etc/avahi/avahi-daemon.conf -D
sleep 4

# Binding socket at /var/run/rtpmidid/control.sock:
mkdir -p /var/run/rtpmidid

# Start fork of rtpmidi and leave the script
$SCRIPT_DIR/sbin/rtpmidid &

if ps | grep avahi-daemon | grep -v grep ; then echo "avahi-daemon is running" >> $TKGL_LOG ; fi
if ps | grep rtpmidid | grep -v grep ; then echo "rtpmidid is running" >> $TKGL_LOG ; fi
