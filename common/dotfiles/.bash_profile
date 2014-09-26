#
# ~/.bash_profile
#

#===============================================================================
# Load .bashrc
#===============================================================================
[[ -f ~/.bashrc ]] && . ~/.bashrc

#===============================================================================
# Manage user session - pick only one from the options
#===============================================================================

#=======================================
# Use terminal multiplexer - dvtm
# Log out after exiting dvtm
#=======================================
#[[ -z $DISPLAY ]] && dvtm && exit

#=======================================
# Start X automatically after login
# All output is redirected to log file for clean visual login effect
# Exiting X leaves user logged in into console with terminal multiplexer
# Log out after exiting dvtm
# Note: Add exec before "startx" to to log out after exiting X
#=======================================
[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && startx -- -keeptty > ~/.xlog && dvtm && exit

