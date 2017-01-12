#
# ~/.bashrc
#

#-------------------------------------------------------------------------------
# If not running interactively, don't do anything
#-------------------------------------------------------------------------------
[[ $- != *i* ]] && return

#---------------------------------------
# Exported variables
#---------------------------------------

# Add more dirs to path
export PATH=$PATH:$HOME/archon/skynet/bin

# Script for entering sudo password using dmenu
export SUDO_ASKPASS="/home/adam/archon/skynet/bin/dmenu_passwd"

#-------------------------------------------------------------------------------
# Shell
#-------------------------------------------------------------------------------

#---------------------------------------
# Prompt(s)
#---------------------------------------
PS1='[\u@\h \W]\$'

#---------------------------------------
# Aliases
#---------------------------------------

#-------------------
# Data partition remounting
#-------------------
dataRwParams="remount,nouser,noexec,rw"
alias drw="sudo mount -L \"Data\" -o $dataRwParams"
dataRoParams="remount,auto,nouser,noexec,ro"
alias dro="sudo mount -L \"Data\" -o $dataRoParams"

#-------------------
# ls
#-------------------
alias ls='ls -h --color=auto'
alias la='ls -A'
alias ll='la -l'

#-------------------
# mc
#-------------------
if [[ -z "$DISPLAY" ]]; then
    # Aliases for console

    # Do not use fancy characters to draw outline
    # Use vim as editor
    # Use mc_viewer script as viewer - vim with additional parameters
    alias mc='EDITOR=vim VIEWER=$HOME/archon/skynet/bin/mc_viewer mc -a'
else
    # Aliases for GUI

    # Use vim as editor
    # Use mc_viewer script as viewer - vim with additional parameters
    alias mc='EDITOR=vim VIEWER=$HOME/archon/skynet/bin/mc_viewer mc'
fi

#-------------------
# mkdir
#-------------------
alias mkdir="mkdir -p"

#-------------------
# Privileged access
#-------------------

# To let aliases carry over to the root account when using sudo
# -E option to allow e.g. vim settings available during sudo session
alias sudo='sudo -E '
alias poweroff="sudo systemctl poweroff"
alias reboot="sudo systemctl reboot"

#-------------------
# Udisks/udiskie
#-------------------
alias dismount='udiskie-umount --detach'

#-------------------
# Urgency hint
#-------------------
alias urgent='echo -e "\a"'

#---------------------------------------
# Command completion
#---------------------------------------

# sudo
complete -cf sudo

# git
source "/usr/share/git/completion/git-completion.bash"

#-------------------------------------------------------------------------------
# Color themes
#-------------------------------------------------------------------------------

#---------------------------------------
# Solarized
#---------------------------------------

# Load colors definition
source "$HOME/archon/skynet/colors/solarized/bash.conf"

#---------------------------------------
# Choice
#---------------------------------------
if [[ "$TERM" = "linux" ]]; then
    #Set desired theme here
    CONSOLE_THEME="solarized"

    # No color theme
    #CONSOLE_THEME=""
fi

#---------------------------------------
# Definition
#---------------------------------------
if [[ "$CONSOLE_THEME" = "solarized" ]]; then
    # Set console colors using predefined values
    CONSOLE_COLOR_BLACK=$SOLARIZED_BASE03
    CONSOLE_COLOR_RED=$SOLARIZED_RED
    CONSOLE_COLOR_GREEN=$SOLARIZED_GREEN
    CONSOLE_COLOR_YELLOW=$SOLARIZED_YELLOW
    CONSOLE_COLOR_BLUE=$SOLARIZED_BLUE
    CONSOLE_COLOR_MAGNETA=$SOLARIZED_MAGNETA
    CONSOLE_COLOR_CYAN=$SOLARIZED_CYAN
    CONSOLE_COLOR_WHITE=$SOLARIZED_BASE2
    CONSOLE_COLOR_BR_BLACK=$SOLARIZED_BASE02
    CONSOLE_COLOR_BR_RED=$SOLARIZED_ORANGE
    CONSOLE_COLOR_BR_GREEN=$SOLARIZED_BASE01
    CONSOLE_COLOR_BR_YELLOW=$SOLARIZED_BASE00
    CONSOLE_COLOR_BR_BLUE=$SOLARIZED_BASE0
    CONSOLE_COLOR_BR_MAGNETA=$SOLARIZED_VIOLET
    CONSOLE_COLOR_BR_CYAN=$SOLARIZED_BASE1
    CONSOLE_COLOR_BR_WHITE=$SOLARIZED_BASE3

    # Set dir colors file
    DIR_COLORS_FILE="$HOME/.dir_colors_solarized"

    # Set Midnight Commander colors file
    MC_COLORS_FILE="$HOME/.config/mc/mc_solarized.ini"
fi

#---------------------------------------
# Setting
#---------------------------------------
if [[ -n "$CONSOLE_THEME" ]]; then
    # Set console colors
    echo -en "\e]P0$CONSOLE_COLOR_BLACK"
    echo -en "\e]P1$CONSOLE_COLOR_RED"
    echo -en "\e]P2$CONSOLE_COLOR_GREEN"
    echo -en "\e]P3$CONSOLE_COLOR_YELLOW"
    echo -en "\e]P4$CONSOLE_COLOR_BLUE"
    echo -en "\e]P5$CONSOLE_COLOR_MAGNETA"
    echo -en "\e]P6$CONSOLE_COLOR_CYAN"
    echo -en "\e]P7$CONSOLE_COLOR_WHITE"
    echo -en "\e]P8$CONSOLE_COLOR_BR_BLACK"
    echo -en "\e]P9$CONSOLE_COLOR_BR_RED"
    echo -en "\e]PA$CONSOLE_COLOR_BR_GREEN"
    echo -en "\e]PB$CONSOLE_COLOR_BR_YELLOW"
    echo -en "\e]PC$CONSOLE_COLOR_BR_BLUE"
    echo -en "\e]PD$CONSOLE_COLOR_BR_MAGNETA"
    echo -en "\e]PE$CONSOLE_COLOR_BR_CYAN"
    echo -en "\e]PF$CONSOLE_COLOR_BR_WHITE"
    clear # Redraw background

    # Set dir colors
    eval $(dircolors -b $DIR_COLORS_FILE)

    # Set Midnight Commander colors
    export MC_SKIN=$MC_COLORS_FILE
fi

