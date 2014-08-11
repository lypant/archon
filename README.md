This is my another approach to automatic Arch Linux installation and configuration.
This time some modularity is introduced, to separate parts which are common for all machines from those which are machine-specific.

To set custom video mode for terminal (available under vga=864 or vesa 360)
run in host's terminal:
VBoxManage setextradata "<guest_name>" "CustomVideoMode1" "1680x1050x24"

Instruction
1. Download the project files
curl -L https://github.com/lypant/archon/tarball/common | tar xz

TODO:
- Split collors definintion from .bashrc into separate file (existing bash.conf?)
