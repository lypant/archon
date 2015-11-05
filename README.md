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
- Increase sudo timeout
? Add Tmp partition handling similar to Data partition
? Add autofs support for removable media
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
? Replace dwm with i3?
    i3 pros:
    - i3 does not require rebuild after changing settings
    - i3 has separate config file which survives package updates
    - i3 is better documented
    - i3 provides lightweight status bar
        - no need for conky
        - no need for cmus_status script
    - it is supposed to support multi monitor setups (I have single monitor)
    i3 cons:
    - no preconfigured layouts which can be activated with a shorcut keys
    - tree structure is not very intuitive when dealing with windows created by
        program - e.g. cinelerra
    - tearing/flickering was visible and is known issue
        - suggested to use compton - give it a try
    dwm pros:
        - nice preconfigured layouts
    dwm cons:
    - configuration by source code
        - no single config file to be carried over dwm update
        - applying multiple patches is not easy, time consuming and error prone
        - possibility to introduce bugs while patching
    - so far I was using conky for status bars, cmus_status - fancy but not KISS
    - problems with status bar - 'eaten characters'
- if going to i3...
    - set Urxvt.urgentOnBell: true in .Xresources
    - add ttf-font-icons for symbols in status bar (gucharmap for viewing chars)
        - F1C0 for disk/db
        - F3B3 for load
        - F0E0 for load
        - F012 for volume
        - F073 for date/calendar
        - F36E for time/clock
        in config:
        font pango:Terminus, font-icons 10
    - use i3 session mode for locking/rebooting/shutting down
        - no need for rt, pf scripts
    - try compton to prevent flickering/tearing
        - might require hsetroot for background color setting
    - try X11/Xorg settings for preventing flickering/tearing
        Section "Extensions"
            Option "Composite" "Disable"
        EndSection
- try some console email client
    - mutt
    - alpine
- try framebuffer image viewer
- try w3m console web browser

