#!/bin/sh
#
# __ __| |           |  /_) |     ___|             |           |
#    |   __ \   _ \  ' /  | |  / |      _ \ __ \   |      _` | __ \   __|
#    |   | | |  __/  . \  |   <  |   |  __/ |   |  |     (   | |   |\__ \
#   _|  _| |_|\___| _|\_\_|_|\_\\____|\___|_|  _| _____|\__,_|_.__/ ____/
#
# BOOTSTRAP script for MPC device.
# arp_overlay - Arp patterns overlay setting on sdcard (ext4)

SCRIPT_NAME=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_NAME")
source "$SCRIPT_DIR/../../scripts/tkgl_path"

echo "-------------------------------------------------------------------------" >>  $TKGL_LOG
echo "MODULE $SCRIPT_NAME" >> $TKGL_LOG
echo "-------------------------------------------------------------------------" >>  $TKGL_LOG


OVR_ARP_DIR="$SCRIPT_DIR/Arp Patterns"

AKAI_SME0_ARP="/usr/share/Akai/SME0/Arp Patterns"

mkdir -p "$OVR_ARP_DIR/.work" 
mkdir -p "$OVR_ARP_DIR/overlay" 
set >>$TKGL_LOG
# mount the overlay
mount -t overlay overlay -o \
lowerdir = "$AKAI_SME0_ARP",\
upperdir = "$OVR_ARP_DIR/overlay",\
workdir  = "$OVR_ARP_DIR/.work" \
"$AKAI_SME0_ARP">>$TKGL_LOG
