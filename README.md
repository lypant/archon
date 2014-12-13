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
