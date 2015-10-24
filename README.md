Another approach to automatic Arch Linux installation and configuration.

VirtualBox machine setup needed for installation to complete ('common' branch):
- Set up shared folder, according to setup from config files
- Create data disk
    - Should be recognized as /dev/sdb (NOT sda) to avoid setup scripts change
        - Can be achieved by setting disk as SATA, PORT1 (when sda is PORT0)
- Set custom video mode for terminal (available under vga=864 or vesa 360)
    - Run in host's terminal:
    VBoxManage setextradata "<guest_name>" "CustomVideoMode1" "1680x1050x24"

Downloading scripts from livecd:
curl -L https://github.com/lypant/archon/tarball/common | tar xz
or with custom image containing additional scripts:
./github_download -b kiss

2014_12_09
Create new branch "kiss"

NOTES:
- fdisk does not return error code when provided partition parameters
  are invalid - perform additional checks after partition creation?

TODO:
? Allow for installation with other system present ()
    - Handle partitions
    - Support bootloader chainloading
? Add Tmp partition handling similar to Data partition
- Add cd/dvd burning program (brasero?)
- Add program for downloading arch isos
- Evince - fix missing icons
- Add screen saver deactivation when watching films (flash/vlc/...)
? Add virtualbox installation
    - When using two disks this might be not needed as maintaining VBox
      compatibility requires much work
- Add libreoffice or similar office suite installation
- BinUhr
    ? python2-pyserial package needed for serial communication
    ? add user to uucp group for access of /dev/ttyS0
- Add console program for email
    ? mutt
    ? alpine
- Consider replacing dwm with i3
    Pros:
        - Configuration not requiring recompilation
            - No need to adjust after package update
        - Good documentation
    Cons:
        ? Is it possible to have colorized dmenu without using AUR dmenu?
            - If not than this is a con
        - Gaps between windows (at least between terminals)
        - No defined layouts - need to create manually
            - How to switch e.g. from "tiled" to "bstack" layouts easily?
    dwm cons:
        - Need to update patches for newer commits in dwm git repo
        - Patching and fiddling with source code can lead to bugs
        - No central config file witch could be left after package update
        - Not installed as package - might be not visible for some dependencies

