#!/bin/sh
#
# __ __| |           |  /_) |     ___|             |           |
#    |   __ \   _ \  ' /  | |  / |      _ \ __ \   |      _` | __ \   __|
#    |   | | |  __/  . \  |   <  |   |  __/ |   |  |     (   | |   |\__ \
#   _|  _| |_|\___| _|\_\_|_|\_\\____|\___|_|  _| _____|\__,_|_.__/ ____/
#
# BOOTSTRAP INSTALL script for MPC device.

# This shell script will :
# - Add the tkgl bin to the path
# - create and mount an overlay for Arp patterns and progressions on this sd card.


TKGL_ROOT=$(dirname $(readlink -f "$0"))/..
TKGL_SCRIPT=$TKGL_ROOT/scripts
TKGL_BIN=$TKGL_ROOT/bin
TKGL_CONF=$TKGL_ROOT/conf
TKGL_LOGS=$TKGL_ROOT/logs
TKGL_LIB=$TKGL_ROOT/lib

# creates all the directories again because empty dirs can be missing
cd $TKGL_ROOT
echo "*** The KiGenLabs bootstrap install script"
echo "Directories creation..."
mkdir -p $TKGL_SCRIPT>>/dev/null
mkdir -p $TKGL_BIN>>/dev/null
mkdir -p $TKGL_CONF>>/dev/null
mkdir -p $TKGL_LOGS>>/dev/null
mkdir -p $TKGL_LIB>>/dev/null

echo "Changing permission and ownership in /bin /scripts..."

chown root:root $TKGL_BIN/*
chmod 755 $TKGL_BIN/*
chown root:root $TKGL_SCRIPT/*
chmod 755 $TKGL_SCRIPT/*
chown root:root $TKGL_LIB/*                         
chmod 755 $TKGL_LIB/* 

echo "*** Done !" 
echo "*** Please check below :' 
echo "*** - directries existence, 
echo "*** - permissions and ownership by root"

ls $TKGL_ROOT
ls -l $TKGL_BIN
ls -l $TKGL_SCRIPT

