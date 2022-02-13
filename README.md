        __ __| |           |  /_) |     ___|             |           |
           |   __ \   _ \  ' /  | |  / |      _ \ __ \   |      _` | __ \   __|
           |   | | |  __/  . \  |   <  |   |  __/ |   |  |     (   | |   |\__ \
          _|  _| |_|\___| _|\_\_|_|\_\\____|\___|_|  _| _____|\__,_|_.__/ ____/

# MPC / Force bootstrap scripts

This "bootstrap" implementation allows Akai MPCs / Force system customization at boot time as linux application launching, data rescue, backup settings,... 
You need to update your MPC/Force with a modded image that will launch the bootstrap from the internal filesystem, before the MPC application starts.

## How to install :

1. Update as usual (usb procedure) with the last MPC / Force modded image to enable the bootstrap script :

   https://github.com/TheKikGen/MPC-LiveXplore  
   
2. Copy to the "tkgl_bootstrap_[ProjectData]" directory to the root of an sdcard/usb stick, preferably formatted with ext4 filesystem    

   You can download the last version in a zip file here : https://github.com/TheKikGen/MPC-LiveXplore-bootstrap/archive/refs/heads/main.zip  
   (remove the prefix "main" after unzip)

   The directory MUST be named "tkgl_bootstrap_[ProjectData]" to be recognized by the bootstrap script within the image.  
   This suffix allows to hide the directory when you are using the MPC app.
   
## Activation of modules at boot

You need to edit the file tkgl_bootstrap_[ProjectData]/doer_list to add a modules list you want to launch at boot time.  
Follow instructions within the file itself.

## Creating your own module 

Copy paste an existing module example (for example the arp_overlay) to create your own.  
The module name must have a directory at tkgl_bootstrap_[ProjectData]/modules/mod_(your module name).

Within the module directory, the start script must be named tkgl_mod_<your module name>.sh.  

Your module must be then added to the $DOER variable in the tkgl_bootstrap script.  
        
If your MPC is stuck, remove the sdcard and reboot.  You will find a log in the tkgl_bootstrap/logs.  
        
## Availables modules
        
````  
# ---------------------------------------------------------------------------------------------------------
# Module name  : Description
# ---------------------------------------------------------------------------------------------------------
# install      : setup some directories and permissions on the filesystem
# ---------------------------------------------------------------------------------------------------------
# etcovr_clean : clean passwords files and ssh config on the /etc overlay (/media/internal-sd).
#              : Even if ssh is enabled on the modified image, the overlay of the /etc directory 
#              : on internal-sd may restrict its use.  This module deletes any etc configuration files
#              : on that overlay.  Run once.
# ---------------------------------------------------------------------------------------------------------
# telnetd      : launch a telnetd server (root access). Experimental.
# ---------------------------------------------------------------------------------------------------------
# nomoressh    : stop the ssh temporarily for security reasons (e.g. during live performance).
#                You'll need to remove the usb key to reactivate ssh.
# ---------------------------------------------------------------------------------------------------------
# arp_overlay  : add your own arp patterns on the sdcard.
#              : Arp patterns are patterns are read only when the MPC app starts.  This module creates an
#              : overlay of the "/usr/share/Akai/SME0/Arp Patterns" directory on the bootstrap sdcard at
#              : "/media/TKGL_BOOTSTRAP/tkgl_bootstrap_[ProjectData]/modules/mod_arp_overlay/Arp Patterns"
#              : You must copy your own arp patterns within the "overlay" subdirectory.
#              : More than 3000 arp patterns are provided by default. 
# ---------------------------------------------------------------------------------------------------------
# rtpmidid     : Launch rtpmidi and avahi daemon in the background to enable midi over ethernet.  You can
#              : use application like TouchDaw or any rtpmidi/Apple midi compatible device to control your
#              : MPC/Force.  In the midi input/output, you will see a "rtpmidi tkgl Network" midi port.
# ---------------------------------------------------------------------------------------------------------
# nomoreazmidi : az01-midi is the proprietary Akai ethernet midi service, used notably to enable Ableton Live
#              : remote session. This module will stop the service (so will disable also Live remote control).
#              : If you use rtpmidid module, this is a recommended setting to avoid conflicts.
# ---------------------------------------------------------------------------------------------------------
# anyctrl      : use any midi controller as MPC/Force control surface (full ports)
# ---------------------------------------------------------------------------------------------------------
# anyctrl_lt   : use any midi controller as MPC/Force control surface (private only)
# ---------------------------------------------------------------------------------------------------------
# iamforce     : Force software launcher on a MPC using mpcmapper.so ld_preload library
# ---------------------------------------------------------------------------------------------------------
````


