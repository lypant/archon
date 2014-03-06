# When on VirtualBox
/usr/bin/VBoxClient-all

# Use settings from .Xresources
[[ -f ~/.Xresources ]] && xrdb -merge ~/.Xresources

# Set X font path to include terminus-font
xset +fp /usr/share/fonts/local

# Set root window background color to solarized base03
xsetroot -solid "#002b36"

# Launch dwm
exec dwm

