#
# ~/.bash_profile
#

# Load .bashrc
[[ -f ~/.bashrc ]] && . ~/.bashrc

# Start X automatically after login
# Add exec before startx to to log out after exiting X
# Here exiting X leaves user logged in console
# Also all output is redirected to log file for clean visual login effect
[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && startx &> ~/.xlog

