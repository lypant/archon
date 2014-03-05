# When on VirtualBox
/usr/bin/VBoxClient-all

# Use settings from .Xresources
[[ -f ~/.Xresources ]] && xrdb -merge ~/.Xresources

# Set X font path to include terminus-font
xset +fp /usr/share/fonts/local

# Launch dwm
exec dwm

