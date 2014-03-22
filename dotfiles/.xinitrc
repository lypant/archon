#===============================================================================
# VirtualBox
#===============================================================================
/usr/bin/VBoxClient-all

#===============================================================================
# Use settings from .Xresources
#===============================================================================
[[ -f ~/.Xresources ]] && xrdb -merge ~/.Xresources

#===============================================================================
# Fonts
#===============================================================================

# Set X font path to include terminus-font
xset +fp /usr/share/fonts/local

#===============================================================================
# Colors
#===============================================================================

# Load colors definition
source "$HOME/archon/colors/solarized/bash.conf"

# Set root window background color
xsetroot -solid "#$SOLARIZED_BASE03"

#===============================================================================
# Windows Manager
#===============================================================================

# Use conky to display system info on status bar
conky | while read -r; do xsetroot -name "$REPLY"; done &

# Launch dwm
exec dwm

