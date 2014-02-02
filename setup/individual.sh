#!/bin/bash

echo individual.sh

createDotfilesBackupDir()
{
    requiresVariable "DOTFILES_BACKUP_DIR" "$FUNCNAME"

    local retval=0

    # Check if backup dir exists
    if [[ ! -d $DOTFILES_BACKUP_DIR ]]; then
        executeCommand "mkdir -p $DOTFILES_BACKUP_DIR"
        retval="$?"
    fi

    return $retval
}

installDotfile()
{
    requiresVariable "DOTFILES_BACKUP_DIR" "$FUNCNAME"
    requiresVariable "DOTFILES_SOURCE_DIR" "$FUNCNAME"
    requiresVariable "USER1_HOME" "$FUNCNAME"

    if [[ $# -lt 2 ]]; then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        return 1
    fi

    local dotfileName="$1"
    local dotfileHomePath="$2"
    local dotfile=""
    local nested=0
    local now=`date +"%Y%m%d_%H%M"`

    # Avoid extra slash when path is empty
    if [[ -z "$dotfileHomePath" ]]; then
        dotfile="$dotfileName"
        nested=0
    else
        dotfile="$dotfileHomePath/$dotfileName"
        nested=1
    fi

    # Ensure that dotfiles backup dir exists
    createDotfilesBackupDir
    retval="$?"
    if [[ $retval -ne 0  ]]; then
        log "$FUNCNAME: failed to create dotfiles backup dir: $retval"
        return 2
    fi

    # Backup original dotfile, if it exists
    backupFile "$USER1_HOME/$dotfile" "$DOTFILES_BACKUP_DIR/$dotfile"_"$now"
    retval="$?"
    if [[ $retval -ne 0  ]]; then
        log "$FUNCNAME: failed to backup dotfile $dotfile: $retval"
        return 3
    fi

    # Remove original dotfile
    executeCommand "rm -f $USER1_HOME/$dotfile"
    retval="$?"
    if [[ $retval -ne 0  ]]; then
        log "$FUNCNAME: failed to delete original dotfile $USER1_HOME/$dotfile: $retval"
        return 4
    fi

    # Ensure that for nested dotfile the path exists
    if [[ $nested -eq 1 ]]; then
        executeCommand "mkdir -p $USER1_HOME/$dotfileHomePath"
        retval="$?"
        if [[ $retval -ne 0  ]]; then
            log "$FUNCNAME: failed to create path for nested dotfile: $retval"
            return 5
        fi
    fi

    # Create link to new dotfile
    createLink "$DOTFILES_SOURCE_DIR/$dotfile" "$USER1_HOME/$dotfile"
    retval="$?"
    if [[ $retval -ne 0  ]]; then
        log "$FUNCNAME: failed to create link to new dotfile $DOTFILES_SOURCE_DIR/$dotfile: $retval"
        return 6
    fi

    return $retval
}

installBashprofileDotfile()
{
    log "Install bash_profile dotfile..."

    installDotfile ".bash_profile" ""
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install bash_profile dotfile"

    log "Install bash_profile dotfile...done"
}

installBashrcDotfile()
{
    log "Install bashrc dotfile..."

    installDotfile ".bashrc" ""
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install bashrc dotfile"

    log "Install bashrc dotfile...done"
}

installDircolorssolarizedDotfile()
{
    log "Install .dir_colors_solarized dotfile..."

    installDotfile ".dir_colors_solarized" ""
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install .dir_colors_solarized dotfile"

    log "Install .dir_colors_solarized dotfile...done"
}

installVimrcDotfile()
{
    log "Install vimrc dotfile..."

    installDotfile ".vimrc" ""
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install vimrc dotfile"

    log "Install vimrc dotfile...done"
}

installVimsolarizedDotfile()
{
    log "Install solarized.vim dotfile..."

    installDotfile "solarized.vim" ".vim/colors"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install solarized.vim dotfile"

    log "Install solarized.vim dotfile...done"
}

installMcsolarizedDotfile()
{
    log "Install mc_solarized.ini dotfile..."

    installDotfile "mc_solarized.ini" ".config/mc"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install mc_solarized.ini dotfile"

    log "Install mc_solarized.ini dotfile...done"
}

installGitconfigDotfile()
{
    log "Install .gitconfig dotfile..."

    installDotfile ".gitconfig" ""
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install .gitconfig dotfile"

    log "Install .gitconfig dotfile...done"
}

installXinitrcDotfile()
{
    log "Install .xinitrc dotfile..."

    installDotfile ".xinitrc" ""
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install .xinitrc dotfile"

    log "Install .xinitrc dotfile...done"
}

installXresourcesDotfile()
{
    log "Install .Xresources dotfile..."

    installDotfile ".Xresources" ""
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install .Xresources dotfile"

    log "Install .Xresources dotfile...done"
}

changeHomeOwnership()
{
    if [[ $# -lt 2 ]];then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        return 1
    fi

    log "Change home dir ownership..."

    local userName="$1"
    local userHome="$2"

    executeCommand "chown -R $userName:users $userHome"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to change home dir ownership"

    log "Change home dir ownership...done"
}

changeUser1HomeOwnership()
{
    requiresVariable "USER1_NAME" "$FUNCNAME"
    requiresVariable "USER1_HOME" "$FUNCNAME"

    log "Change user1 home ownership..."

    changeHomeOwnership "$USER1_NAME" "$USER1_HOME"
    # TODO: following tSOE is redundand - function above already cheks that - improve in future
    terminateScriptOnError "$?" "$FUNCNAME" "failed to change user1 home dir ownership"

    log "Change user1 home ownership...done"
}

installDvtm()
{
    requiresVariable "DVTM_PACKAGES" "$FUNCNAME"
    log "Install dvtm..."

    installPackage $DVTM_PACKAGES
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install dvtm"

    log "Install dvtm...done"
}

installXorgBasic()
{
    requiresVariable "XORG_BASIC_PACKAGES" "$FUNCNAME"

    log "Install xorg basics..."

    installPackage $XORG_BASIC_PACKAGES
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install xorg basics"

    log "Install xorg basics...done"
}

installXorgAdditional()
{
    requiresVariable "XORG_ADDITIONAL_PACKAGES" "$FUNCNAME"

    log "Install xorg additional..."

    installPackage $XORG_ADDITIONAL_PACKAGES
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install xorg additional"

    log "Install xorg additional...done"
}

installRxvtUnicode()
{
    requiresVariable "RXVTUNICODE_PACKAGES" "$FUNCNAME"

    log "Install rxvt unicode..."

    installPackage $RXVTUNICODE_PACKAGES
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install rxvt unicode"

    log "Install rxvt unicode...done"
}

installGuiFonts()
{
    requiresVariable "GUI_FONT_PACKAGES" "$FUNCNAME"

    log "Install gui fonts..."

    installPackage $GUI_FONT_PACKAGES
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install gui fonts"

    log "Install gui fonts...done"
}

# TODO - check if official repo installation works fine...
installDwm()
{
    requiresVariable "DWM_PACKAGES" "$FUNCNAME"

    log "Install dwm..."

    installPackage $DWM_PACKAGES
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install dwm"

    log "Install dwm...done"
}

installCustomizedDwm()
{
    requiresVariable "DWM_BUILD_PATH" "$FUNCNAME"

    log "Installing customized dwm..."

    # Clone project from git
    executeCommand "git clone http://git.suckless.org/dwm $DWM_BUILD_PATH"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to clone dwm repository"

    # Newest commit was not working... use specific, working version
    executeCommand "git -C $DWM_BUILD_PATH checkout 4fb31e0 -b dwm_installed"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to checkout older commit as a new branch"

    # Configure necessary settings
    executeCommand "sed -i 's/PREFIX = \/usr\/local/PREFIX = \/usr/g'" "$DWM_BUILD_PATH/config.mk"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to change dwm prefix"

    executeCommand "sed -i 's/X11INC = \/usr\/X11R6\/include/X11INC = \/usr\/include\/X11/g'" "$DWM_BUILD_PATH/config.mk"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to change dwm x11 include path"

    executeCommand "sed -i 's/X11LIB = \/usr\/X11R6\/lib/X11LIB = \/usr\/lib\/X11/g'" "$DWM_BUILD_PATH/config.mk"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to change dwm x11 lib path"

    executeCommand 'sed -i "s/\"st\"/\"$TERMINAL_EMULATOR_COMMAND\"/g"' "$DWM_BUILD_PATH/config.def.h"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to change dwm terminal emulator command"

    # Save configuration as new commit
    executeCommand "git -C $DWM_BUIL_PATH commit -a -m \"Adjustments done during archon installation\""
    terminateScriptOnError "$?" "$FUNCNAME" "failed to commit adjustments"

    # Install
    executeCommand "make clean install"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to build and install dwm"

    log "Installing customized dwm...done"
}

installDmenu()
{
    requiresVariable "DMENU_PACKAGES" "$FUNCNAME"

    log "Install dmenu..."

    installPackage $DMENU_PACKAGES
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install dmenu"

    log "Install dmenu...done"
}

installVirtualboxGuestAdditions()
{
    requiresVariable "VIRTUALBOX_GUEST_UTILS_PACKAGES" "$FUNCNAME"
    requiresVariable "VIRTUALBOX_GUEST_UTILS_MODULES" "$FUNCNAME"
    requiresVariable "VIRTUALBOX_GUEST_UTILS_MODULES_FILE" "$FUNCNAME"

    log "Install virtualbox guest additions..."

    # Install the packages
    installPackage $VIRTUALBOX_GUEST_UTILS_PACKAGES
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install virtualbox package"

    # Load required modules
    executeCommand "modprobe -a $VIRTUALBOX_GUEST_UTILS_MODULES"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to load required modules"

    # Setup modules to be loaded on startup
    if [ ! -z "$VIRTUALBOX_GUEST_UTILS_MODULES" ]; then
        for module in $VIRTUALBOX_GUEST_UTILS_MODULES
        do
            executeCommand "echo $module >> $VIRTUALBOX_GUEST_UTILS_MODULES_FILE"
            terminateScriptOnError "$?" "$FUNCNAME" "failed to setup module to be loaded on startup"
        done
    fi

    log "Install virtualbox guest additions...done"
}

setVirtualboxSharedFolder()
{
    requiresVariable "USER1_NAME" "$FUNCNAME"
    requiresVariable "USER1_HOME" "$FUNCNAME"
    requiresVariable "VIRTUALBOX_SHARED_FOLDER_NAME" "$FUNCNAME"

    log "Set virtualbox shared folder..."

    # Create /media folder
    executeCommand "mkdir /media"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to create /media dir"

    # Add user1 to vboxsf group
    executeCommand "gpasswd -a $USER1_NAME vboxsf"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to add user to vboxsf group"

    # Enable vboxservice service
    enableService "vboxservice"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to enable vboxservice"

    # Start vboxservice (needed for link creation)
    startService "vboxservice"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to start vboxservice"

    # Wait a moment for a started service to do its job
    executeCommand "sleep 5"

    # Create link for easy access
    createLink "/media/sf_$VIRTUALBOX_SHARED_FOLDER_NAME" "$USER1_HOME/$VIRTUALBOX_SHARED_FOLDER_NAME"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to create link to shared folder"

    log "Set virtualbox shared folder...done"
}

