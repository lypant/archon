#!/bin/bash
#===============================================================================
# FILE:         setup_custom.sh
#
# USAGE:        Execute from shell, e.g. ./setup_custom.sh
#
# DESCRIPTION:  Functions used to perform custom system setup.
#               Executes main setup function.
#===============================================================================

#===============================================================================
# Other scripts usage
#===============================================================================

source "setup.conf"
source "functions.sh"

#===============================================================================
# Log file for this script
#===============================================================================

LOG_FILE="$ARCHON_SETUP_CUSTOM_LOG_FILE"

#===============================================================================
# Helper functions
#===============================================================================

addUser()
{
    if [[ $# -lt 4 ]];then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        terminateScriptOnError "1" "$FUNCNAME" "failed to add user"
    fi

    local mainGroup="$1"
    local additionalGroups="$2"
    local shell="$3"
    local name="$4"

    log "Add user..."

    executeCommand "useradd -m -g $mainGroup -G $additionalGroups -s $shell $name"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to add user"

    log "Add user...done"
}

setUserPassword()
{
    if [[ $# -lt 1 ]];then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        terminateScriptOnError "1" "$FUNCNAME" "failed to set user password"
    fi

    log "Set user password..."

    local ask=1
    local name="$1"

    while [ $ask -ne 0 ]; do
        log "Provide password for user $name"
        executeCommand "passwd $name"
        ask=$?
    done

    log "Set user password...done"
}

setSudoer()
{
    if [[ $# -lt 1 ]];then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        terminateScriptOnError "1" "$FUNCNAME" "failed to set sudoer"
    fi

    log "Set sudoer..."

    local name="$1"

    # TODO - do it in a safer way... Here just for experiments
    executeCommand "echo \"$name ALL=(ALL) ALL\" >> /etc/sudoers"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to set sudoer"

    log "Set sudoer...done"
}

backupFile()
{
    if [[ $# -lt 2 ]]; then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        return 1
    fi

    local original=$1
    local backup=$2
    local retval=0

    # If original file exists, move it to backup dir
    if [[ -e $original ]]; then
        executeCommand "cp $original $backup"
        retval=$?
    fi
    return $retval
}

createLink()
{
    if [[ $# -lt 2 ]]; then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        return 1
    fi

    local linkTarget=$1
    local linkName=$2
    local retval=0

    # Check if target exists
    if [[ -e $linkTarget ]]; then
        # File exists
        # create symlink
        executeCommand "ln -s $linkTarget $linkName"
        retval=$?
    else
        log "Link target does not exist!"
        retval=2
    fi

    return $retval
}

enableService()
{
    if [[ $# -lt 1 ]]; then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        return 1
    fi

    local service="$1"

    executeCommand "systemctl enable $service"
    return $?
}

startService()
{
    if [[ $# -lt 1 ]]; then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        return 1
    fi

    local service="$1"

    executeCommand "systemctl start $service"
    return $?
}

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

#===============================================================================
# Setup functions
#===============================================================================

#=======================================
# Common setup
#=======================================

#===================
# Common users
#===================

addUser1()
{
    requiresVariable "USER1_MAIN_GROUP" "$FUNCTION"
    requiresVariable "USER1_ADDITIONAL_GROUPS" "$FUNCTION"
    requiresVariable "USER1_SHELL" "$FUNCTION"
    requiresVariable "USER1_NAME" "$FUNCTION"

    log "Add user1..."

    executeCommand "useradd -m -g $USER1_MAIN_GROUP -G $USER1_ADDITIONAL_GROUPS -s $USER1_SHELL $USER1_NAME"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to add user 1"

    log "Add user1...done"
}

setUser1Password()
{
    requiresVariable "USER1_NAME" "$FUNCTION"

    log "Set user 1 password..."

    setUserPassword "$USER1_NAME"

    log "Set user 1 password...done"
}

setUser1Sudoer()
{
    requiresVariable "USER1_NAME" "$FUNCTION"

    log "Set user1 sudoer..."

    setSudoer "$USER1_NAME"

    log "Set user1 sudoer...done"
}

#===================
# Common system packages
#===================

installAlsa()
{
    requiresVariable "ALSA_PACKAGES" "$FUNCTION"

    log "Install alsa..."

    installPackage $ALSA_PACKAGES
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install alsa"

    log "Install alsa...done"
}

#===================
# Common software packages
#===================

installVim()
{
    requiresVariable "VIM_PACKAGES" "$FUNCTION"

    log "Install vim..."

    installPackage $VIM_PACKAGES
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install vim"

    log "Install vim...done"
}

installMc()
{
    requiresVariable "MC_PACKAGES" "$FUNCTION"

    log "Install mc..."

    installPackage $MC_PACKAGES
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install mc"

    log "Install mc...done"
}

installGit()
{
    requiresVariable "GIT_PACKAGES" "$FUNCTION"

    log "Install git..."

    installPackage $GIT_PACKAGES
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install git"

    log "Install git...done"
}

#===================
# Common configuration
#===================

configurePacman()
{
    log "Configure pacman..."

    uncommentVar "TotalDownload" "/etc/pacman.conf"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to configure pacman"

    log "Configure pacman...done"
}

configureGitUser()
{
    requiresVariable "GIT_USER_EMAIL" "$FUNCNAME"
    requiresVariable "GIT_USER_NAME" "$FUNCNAME"

    log "Configure git user..."

    executeCommand "git config --global user.email \"$GIT_USER_EMAIL\""
    terminateScriptOnError "$?" "$FUNCNAME" "failed to configure git user email"

    executeCommand "git config --global user.name \"$GIT_USER_NAME\""
    terminateScriptOnError "$?" "$FUNCNAME" "failed to configure git user name"

    log "Configure git user...done"
}

setBootloaderKernelParams()
{
    requiresVariable "ROOT_PARTITION_HDD" "$FUNCNAME"
    requiresVariable "ROOT_PARTITION_NB" "$FUNCNAME"
    requiresVariable "BOOTLOADER_KERNEL_PARAMS" "$FUNCNAME"

    log "Set bootloader kernel params..."

    # Not using var for /dev/ - caused sed problems interpreting / character
    executeCommand "sed -i \"s/APPEND root=\/dev\/$ROOT_PARTITION_HDD$ROOT_PARTITION_NB rw/APPEND root=\/dev\/$ROOT_PARTITION_HDD$ROOT_PARTITION_NB $BOOTLOADER_KERNEL_PARAMS/\" /boot/syslinux/syslinux.cfg"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to set bootloader kernel params"

    log "Set bootloader kernel params...done"
}

disableSyslinuxBootMenu()
{
    log "Disable syslinux boot menu..."

    commentVar "UI" "/boot/syslinux/syslinux.cfg"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to disable syslinux boot menu"

    log "Disable syslinux boot menu...done"
}

setConsoleLoginMessage()
{
    # Do not require COSNOLE_WELCOME_MSG - when empty, no message will be used

    log "Set console login message..."

    # Remove welcome message
    executeCommand "rm -f /etc/issue"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to remove /etc/issue file"

    # Set new welcome message, if present
    if [ ! -z "$CONSOLE_WELCOME_MSG" ];then
        executeCommand "echo $CONSOLE_WELCOME_MSG > /etc/issue"
        terminateScriptOnError "$?" "$FUNCNAME" "failed to set console login message"
    else
        log "Console welcome message not set, /etc/issue file deleted"
    fi

    log "Set console login message...done"
}

# This requires image recreation for changes to take effect
setEarlyTerminalFont()
{
    log "Set early terminal font..."

    # Add "consolefont keymap" hooks
    # TODO - write a function for extending such lists
    # TODO   (original list might change and we don't care about the list, we want just to add sth)
    local originalList="base udev autodetect modconf block filesystems keyboard fsck"
    local newList="$originalList consolefont keymap"

    executeCommand "sed -i \"s/HOOKS=\\\"$originalList\\\"/HOOKS=\\\"$newList\\\"/g\" /etc/mkinitcpio.conf"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to set early terminal font"

    log "Set early terminal font...done"
}

#=======================================
# Project repository cloning
#=======================================

cloneArchonRepo()
{
    requiresVariable "ARCHON_REPO_URL" "$FUNCNAME"
    requiresVariable "ARCHON_REPO_DST" "$FUNCNAME"

    log "Clone archon repo..."

    executeCommand "git clone $ARCHON_REPO_URL $ARCHON_REPO_DST"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to clone archon repo"

    log "Clone archon repo...done"
}

checkoutCurrentBranch()
{
    requiresVariable "ARCHON_REPO_DST" "$FUNCNAME"
    requiresVariable "ARCHON_BRANCH" "$FUNCNAME"

    log "Checkout current branch..."

    # Execute git commands from destination path
    executeCommand "git -C $ARCHON_REPO_DST checkout $ARCHON_BRANCH"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to checkout current branch"

    log "Checkout current branch...done"
}

createNewBranch()
{
    requiresVariable "ARCHON_REPO_DST" "$FUNCNAME"
    requiresVariable "ARCHON_NEW_BRANCH_NAME" "$FUNCNAME"

    log "Create new branch..."

    executeCommand "git -C $ARCHON_REPO_DST checkout -b \"$ARCHON_NEW_BRANCH_NAME\""
    terminateScriptOnError "$?" "$FUNCNAME" "failed to create new archon branch"

    log "Create new branch...done"
}

copyOverArchonFiles()
{
    requiresVariable "ARCHON_ROOT_PATH" "$FUNCNAME"
    requiresVariable "USER1_HOME" "$FUNCNAME"

    log "Copy over archon files..."

    executeCommand "cp -r $ARCHON_ROOT_PATH $USER1_HOME"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to copy over archon files"

    log "Copy over archon files...done"
}

commitAdjustments()
{
    requiresVariable "ARCHON_REPO_DST" "$FUNCNAME"

    log "Commit adjustments..."

    if [[ -n "$(git -C $ARCHON_REPO_DST status --porcelain)" ]]; then
        executeCommand "git -C $ARCHON_REPO_DST commit -a -m \"Adjustments done during archon installation\""
        terminateScriptOnError "$?" "$FUNCNAME" "failed to commit adjustments"
    else
        log "No changes detected, no need to commit"
    fi

    log "Commit adjustments...done"
}

#=======================================
# Individual setup
#=======================================

#===================
# Individual users
#===================

#===================
# Individual system packages
#===================

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

#===================
# Individual software packages
#===================

installDvtm()
{
    requiresVariable "DVTM_PACKAGES" "$FUNCNAME"
    log "Install dvtm..."

    installPackage $DVTM_PACKAGES
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install dvtm"

    log "Install dvtm...done"
}

installCustomizedDvtm()
{
    requiresVariable "DVTM_GIT_REPO" "$FUNCNAME"
    requiresVariable "DVTM_BUILD_PATH" "$FUNCNAME"
    requiresVariable "DVTM_CUSTOM_BRANCH" "$FUNCNAME"
    requiresVariable "DVTM_ACTIVE_COLOR" "$FUNCNAME"
    requiresVariable "DVTM_MOD_KEY" "$FUNCNAME"
    requiresVariable "CUSTOM_COMMIT_COMMENT" "$FUNCNAME"

    log "Install customized dvtm..."

    executeCommand "git clone $DVTM_GIT_REPO $DVTM_BUILD_PATH"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to clone dvtm repository"

    executeCommand "git -C $DVTM_BUILD_PATH checkout -b $DVTM_CUSTOM_BRANCH"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to checkout new branch"

    # Change default blue color to something brighter - to make it visible on older CRT monitor
    executeCommand "sed -i 's/BLUE/$DVTM_ACTIVE_COLOR/g'" "$DVTM_BUILD_PATH/config.def.h"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to change active color"

    # Change default mod key - 'g' is not convenient to be used with CTRL key
    executeCommand "sed -i \"s/#define MOD CTRL('g')/#define MOD CTRL('$DVTM_MOD_KEY')/g\"" "$DVTM_BUILD_PATH/config.def.h"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to change mod key"

    executeCommand "git -C $DVTM_BUILD_PATH commit -a -m \"$CUSTOM_COMMIT_COMMENT\""
    terminateScriptOnError "$?" "$FUNCNAME" "failed to commit adjustments"

    executeCommand "make -C $DVTM_BUILD_PATH"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to make dvtm"

    executeCommand "make -C $DVTM_BUILD_PATH install"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install dvtm"

    log "Install customized dvtm...done"
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
    requiresVariable "DWM_GIT_REPO" "$FUNCNAME"
    requiresVariable "DWM_BUILD_PATH" "$FUNCNAME"
    requiresVariable "DWM_CUSTOM_BRANCH" "$FUNCNAME"
    requiresVariable "DWM_BASE_COMMIT" "$FUNCNAME"
    requiresVariable "TERMINAL_EMULATOR_COMMAND" "$FUNCNAME"
    requiresVariable "CUSTOM_COMMIT_COMMENT" "$FUNCNAME"

    log "Installing customized dwm..."

    # Clone project from git
    executeCommand "git clone $DWM_GIT_REPO $DWM_BUILD_PATH"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to clone dwm repository"

    # Newest commit was not working... use specific, working version
    executeCommand "git -C $DWM_BUILD_PATH checkout $DWM_BASE_COMMIT -b $DWM_CUSTOM_BRANCH"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to checkout older commit as a new branch"

    # Configure necessary settings
    executeCommand "sed -i 's/PREFIX = \/usr\/local/PREFIX = \/usr/g'" "$DWM_BUILD_PATH/config.mk"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to change dwm prefix"

    executeCommand "sed -i 's/X11INC = \/usr\/X11R6\/include/X11INC = \/usr\/include\/X11/g'" "$DWM_BUILD_PATH/config.mk"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to change dwm x11 include path"

    executeCommand "sed -i 's/X11LIB = \/usr\/X11R6\/lib/X11LIB = \/usr\/lib\/X11/g'" "$DWM_BUILD_PATH/config.mk"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to change dwm x11 lib path"

    # Set terminal command to be launched on shortcut invocation
    executeCommand 'sed -i "s/\"st\"/\"$TERMINAL_EMULATOR_COMMAND\"/g"' "$DWM_BUILD_PATH/config.def.h"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to change dwm terminal emulator command"

    # Change resizehints to false for better aligned terminal windows
    executeCommand "sed -i 's/static const Bool resizehints = True/static const Bool resizehints = False/g'" "$DWM_BUILD_PATH/config.def.h"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to change resizehints"

    # Save configuration as new commit
    executeCommand "git -C $DWM_BUILD_PATH commit -a -m \"$CUSTOM_COMMIT_COMMENT\""
    terminateScriptOnError "$?" "$FUNCNAME" "failed to commit adjustments"

    # Install
    executeCommand "make -C $DWM_BUILD_PATH clean install"
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

#===================
# Individual configuration
#===================

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

#=========
# Dotfiles
#=========

# Bash etc.

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

# vim

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

# mc

installMcsolarizedDotfile()
{
    log "Install mc_solarized.ini dotfile..."

    installDotfile "mc_solarized.ini" ".config/mc"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install mc_solarized.ini dotfile"

    log "Install mc_solarized.ini dotfile...done"
}

# git

installGitconfigDotfile()
{
    log "Install .gitconfig dotfile..."

    installDotfile ".gitconfig" ""
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install .gitconfig dotfile"

    log "Install .gitconfig dotfile...done"
}

# X

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

#===================
# Other
#===================

recreateImage()
{
    log "Recreate linux image..."

    executeCommand "mkinitcpio -p linux"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to set recreate linux image"

    log "Recreate linux image...done"
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

#===============================================================================
# Main setup function
#===============================================================================

setupCustom()
{
    log "Setup custom..."

    #=======================================
    # Common setup
    #=======================================

    #===================
    # Common users
    #===================

    addUser1
    setUser1Password
    setUser1Sudoer

    #===================
    # Common system packages
    #===================

    updatePackageList
    installAlsa

    #===================
    # Common software packages
    #===================

    installVim
    installMc
    installGit

    #===================
    # Common configuration
    #===================

    configurePacman
    configureGitUser
    setBootloaderKernelParams
    disableSyslinuxBootMenu
    setConsoleLoginMessage
    setEarlyTerminalFont    # Requires linux image recreation

    #=======================================
    # Project repository cloning
    #=======================================

    cloneArchonRepo
    checkoutCurrentBranch
    createNewBranch
    copyOverArchonFiles
    commitAdjustments

    #=======================================
    # Individual setup
    #=======================================

    #===================
    # Individual users
    #===================

    #===================
    # Individual system packages
    #===================

    installXorgBasic
    installXorgAdditional

    #===================
    # Individual software packages
    #===================

    #installDvtm            # Official repo version not good enough
    installCustomizedDvtm   # Use customized version instead
    installRxvtUnicode
    installGuiFonts
    #installDwm             # Official repo version not good enough
    installCustomizedDwm    # Use customized version instead
    installDmenu
    installVirtualboxGuestAdditions

    #===================
    # Individual configuration
    #===================

    setVirtualboxSharedFolder

    #=========
    # Dotfiles
    #=========

    # Bash etc.
    installBashprofileDotfile
    installBashrcDotfile
    installDircolorssolarizedDotfile

    # vim
    installVimrcDotfile
    installVimsolarizedDotfile

    # mc
    installMcsolarizedDotfile

    # git
    installGitconfigDotfile

    # X
    installXinitrcDotfile
    installXresourcesDotfile

    #===================
    # Other
    #===================

    recreateImage   # Required by setEarlyTerminalFont
    changeUser1HomeOwnership

    log "Setup custom...done"
}

#===============================================================================
# Main setup function execution
#===============================================================================

setupCustom

