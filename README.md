        __ __| |           |  /_) |     ___|             |           |
           |   __ \   _ \  ' /  | |  / |      _ \ __ \   |      _` | __ \   __|
           |   | | |  __/  . \  |   <  |   |  __/ |   |  |     (   | |   |\__ \
          _|  _| |_|\___| _|\_\_|_|\_\\____|\___|_|  _| _____|\__,_|_.__/ ____/

# MPC / Force bootstrap scripts

This "bootstrap" implementation allows Akai MPCs / Force system customization at boot time as linux application launching, data rescue, backup settings,... 
You need to update your MPC/Force with a modded image that will launch the bootstrap from the internal filesystem, before the MPC application starts.

How to install :

1. Copy to the ".tkgl_bootstrap" directory to the root of an sdcard/usb stick, preferably formatted with ext4 filesystem    

   Important : the directory MUST be named ".tkgl_bootstrap" to be hidden and for the bootstrap to be launched on the sdcard.
   You should change permissions and ownership of binaries and scripts files as follow (locally or in a ssh root session) : 
   
        - cd /media/(your smartcard name)/.tkgl_bootstrap
        - chmod 755 ./lib/* ./bin/* ./scripts/*
        - chown root:root ./lib/* ./bin/* ./scripts/*

2. Update as usual (usb procedure) with the last MPC / Force modded image to enable the bootstrap script :

  [MPC 2.9.0](https://drive.google.com/drive/folders/1A57y88qUesdRu_S2F8FVn3AhZaA_dDgG?usp=sharing)

  [Force 3.0.6](https://drive.google.com/drive/folders/1AqEcxZnJkUNG-8yA7DVGSTJy_sd6ijqr?usp=sharing)

   Rename the image file before copying it to the usb key by removing the ".bootstrapxx" after ".img".
   The launch script on the internal ssd will find the tkgl_bootstrap script automatically. 

3. Create your module and adapt the /tkgl_bootstrap/scripts/tkgl_bootstrap script to your needs 

   Copy paste a script module example (for example the mod_telnetd) to create your own. 
   Your module must be then added to the $DOER variable in the tkgl_bootstrap script.
   
        # submodules launcher : add to the doer , separated by space
        # install      : setup some directories and permissions on the filesystem
        # arp_overlay  : create an overlay of Arp Patterns on the sdcard (if ext4)
        # telnetd      : launch a telnetd server (root access)
        # etcovr_clean : clean passwords files and ssh config on the /etc overlay

        TKGL_DOER="install etcovr_clean arp_overlay telnetd"
   
   Have a look to the tkgl_mod_kgl_mod_arp_overlay.sh : it creates an overlay on the Arp Patterns/Progression directory to allow you to load 
   your own patterns from the sdcard (check "Arp Patterns" and "Progressions" links at the root directory that will be created after a first boot).
   
   A full root access to the system is granted within tkgl_bootstrap, however the file system is mounted read-only for security reasons.
   I do not recommend to install software to (and/or deeply customize) the internal file system. You will loose everything at the next update.
   Instead implement your custom app on the sdcard, to ensure isolation with the filesystem, and to preserve your work.
   It also allows you to return to normal operation of your MPC by simply removing the external sdcard/usb key.

4. Place any binary in the /tkgl_bootstrap/bin

5. Test locally via ssh before running in nominal mode

    ssh root@(your MPC ip addr), then cd to /media(your sdcard name)/tkgl_bootstrap/scripts and run tkgl_bootstrap.
    
6. Reboot your MPC !

    ssh root@(your MPC ip addr) reboot
    
    if your MPC is stuck, remove the sdcard and reboot.  You will find a log in the tkgl_bootstrap/logs.


