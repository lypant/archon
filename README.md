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

2017_01_20
In order to set up a printer:
- launch web browser with http://localhost:631
- administration -> add printer -> root user and password
- select HP LaserJet Professional P1102 USB 000000000QN207ARPR1a HPLIP
    (HP LaserJet Professional P1102)
- select HP LaserJet Professional p1102 hpijs, 3.16.11, requires proprietary plugin
- set media size to A4

2017_01_05
Create new machine setup "skynet"

2014_12_09
Create new branch "kiss"


NOTES:
- fdisk does not return error code when provided partition parameters
  are invalid - perform additional checks after partition creation?

TODO:
- Check video driver for skynet
- Adjust skynet .tmux.conf
- Allow for installation with other system present ()
    - Handle partitions
    - Support bootloader chainloading
- Increase sudo timeout
? Add Tmp partition handling similar to Data partition
? Add autofs support for removable media
- Add cd/dvd burning program (brasero?)
- Add program for downloading arch isos
- Evince - fix missing icons
- Add screen saver deactivation when watching films (flash/vlc/...)
- Add libreoffice or similar office suite installation
- BinUhr
    ? python2-pyserial package needed for serial communication
    ? add user to uucp group for access of /dev/ttyS0
- try some console email client
    - mutt
    - alpine
- try framebuffer image viewer
- try w3m console web browser
- replace java JDK from AUR with packages from official repositories
? Try compton again - for 2 video drivers sometimes old frame was popping up
