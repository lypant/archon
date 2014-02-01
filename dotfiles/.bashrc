#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Prompt(s)
PS1='[\u@\h \W]\$'

# Aliases

# ls
alias ls='ls --color=auto'
alias la='ls -a'
alias ll='ls -al'

if [ -z "$DISPLAY" ]; then
    # Aliases for console

    # Do not use fancy characters to draw outline
    # Use vim as editor
    # Use mc_viewer.sh script as viewer - vim with additional parameters
    alias mc='EDITOR=vim VIEWER=$HOME/archon/scripts/mc_viewer.sh mc -a'
else
    # Aliases for GUI

    # Use vim as editor
    # Use mc_viewer.sh script as viewer - vim with additional parameters
    alias mc='EDITOR=vim VIEWER=$HOME/archon/scripts/mc_viewer.sh mc'
fi

# Exported variables

# Add more dirs to path
export PATH=$PATH:/$HOME/archon/scripts

# Color themes for linux console

# Chose color theme here
if [ "$TERM" = "linux" ]; then
    #Set desired theme here
    CONSOLE_THEME="solarized"
fi

# Define colors for themes here
if [ "$CONSOLE_THEME" = "solarized" ]; then
    # Set console colors
    CONSOLE_COLOR_BLACK="073642"      # S_base02
    CONSOLE_COLOR_RED="dc322f"        # S_red
    CONSOLE_COLOR_GREEN="859900"      # S_green
    CONSOLE_COLOR_YELLOW="b58900"     # S_yellow
    CONSOLE_COLOR_BLUE="268bd2"       # S_blue
    CONSOLE_COLOR_MAGNETA="d33682"    # S_magneta
    CONSOLE_COLOR_CYAN="2aa198"       # S_cyan
    CONSOLE_COLOR_WHITE="eee8d5"      # S_base2
    CONSOLE_COLOR_BR_BLACK="002b36"   # S_base03
    CONSOLE_COLOR_BR_RED="cb4b16"     # S_orange
    CONSOLE_COLOR_BR_GREEN="586e75"   # S_base01
    CONSOLE_COLOR_BR_YELLOW="657b83"  # S_base00
    CONSOLE_COLOR_BR_BLUE="839496"    # S_base0
    CONSOLE_COLOR_BR_MAGNETA="6c71c4" # S_violet
    CONSOLE_COLOR_BR_CYAN="93a1a1"    # S_base1
    CONSOLE_COLOR_BR_WHITE="fdf6e3"   # S_base3

    # Set dir colors file
    DIR_COLORS_FILE="$HOME/.dir_colors_solarized"

    # Set Midnight Commander colors file
    MC_COLORS_FILE="$HOME/.config/mc/mc_solarized.ini"
fi

# Set console solors, if console theme is defined
if [ -n "$CONSOLE_THEME" ]; then
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

