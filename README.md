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
./github_download -b common

2014_12_09
Create new branch "kiss"

NOTES:
- fdisk does not return error code when provided partition parameters
  are invalid - perform additional checks after partition creation?

TODO:
- Allow for installation with other system present ()
    - Handle partitions
    - Support bootloader chainloading
- Experiment with Syslinux boot menu
    - Try out including other files
    - Allow for multiboot (chainloading)
    - Add file defining color scheme etc
- Increase sudo timeout
? Add Tmp partition handling similar to Data partition
- Add permissions handling of mounted devices
    - Should not require root privileges for basic operations
? Add autofs support for removable media
- Add cd/dvd burning program
- Add program for downloading arch isos
- Evince - fix missing icons
- Add screen saver deactivation when watching films (flash/vlc/...)
- Add SSD support

