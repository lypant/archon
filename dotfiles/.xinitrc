# When on VirtualBox
/usr/bin/VBoxClient-all

# Use settings from .Xresources
[[ -f ~/.Xresources ]] && xrdb -merge ~/.Xresources

# Launch dwm
exec dwm

