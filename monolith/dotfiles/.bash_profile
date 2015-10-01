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
# N/A
