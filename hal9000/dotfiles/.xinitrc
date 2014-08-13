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
# Keyboard
#===============================================================================

# Set fontmap to Polish
setxkbmap pl

#===============================================================================
# Colors
#===============================================================================

# Load colors definition
source "$HOME/archon/hal9000/colors/solarized/bash.conf"

# Set root window background color
xsetroot -solid "#$SOLARIZED_BASE03"

#===============================================================================
# Windows Manager
#===============================================================================

# Use conky to display system info on status bar
conky | while read -r; do xsetroot -name "$REPLY"; done &

# Bind keyboard keys
xbindkeys

# Fix misbehaving Java applications by setting WM name
wmname LG3D

# Launch dwm
exec dwm

