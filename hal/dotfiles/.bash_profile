#
# ~/.bash_profile
#

#-------------------------------------------------------------------------------
# Load .bashrc if it exists
#-------------------------------------------------------------------------------
[[ -f ~/.bashrc ]] && . ~/.bashrc

#-------------------------------------------------------------------------------
# Manage user session - pick only one from the options
#-------------------------------------------------------------------------------

#---------------------------------------
# Console mode
#---------------------------------------
# Launch terminal multipxer
# Log out after exiting terminal multiplexer
[[ -z $DISPLAY ]] && [[ -z $TMUX ]] && tmux && exit

#---------------------------------------
# GUI mode
#---------------------------------------
# Start X automatically after login
# All output is redirected to log file for clean visual login effect
# Exiting X leaves user logged in into console with terminal multiplexer
# Log out after exiting terminal multiplexer
# Note: Add exec before "startx" to to log out after exiting X
#[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && startx -- -keeptty > ~/.xlog && tmux && exit

