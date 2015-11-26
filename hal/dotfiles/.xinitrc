#-------------------------------------------------------------------------------
# Use settings from .Xresources
#-------------------------------------------------------------------------------
[[ -f ~/.Xresources ]] && xrdb -merge ~/.Xresources

#-------------------------------------------------------------------------------
# Fonts
#-------------------------------------------------------------------------------

# Set X font path to include terminus-font
xset +fp /usr/share/fonts/local

#-------------------------------------------------------------------------------
# Keyboard
#-------------------------------------------------------------------------------

# Set fontmap to Polish
setxkbmap pl

# Bind keyboard keys
xbindkeys

#-------------------------------------------------------------------------------
# Colors
#-------------------------------------------------------------------------------

# Load colors definition
source "$HOME/archon/hal/colors/solarized/bash.conf"

# Set root window background color
xsetroot -solid "#$SOLARIZED_BASE03"

#-------------------------------------------------------------------------------
# Window Manager
#-------------------------------------------------------------------------------

## Use conky to display system info on status bar
#conky | while read -r; do xsetroot -name "$REPLY"; done &

# Fix misbehaving Java applications by setting WM name
wmname LG3D

## Launch dwm
#exec dwm

