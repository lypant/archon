#!/bin/bash
#===============================================================================
# FILE:         custom_setup.sh
#
# USAGE:        Execute from shell, e.g. ./custom_setup.sh
#
# DESCRIPTION:  Functions used to perform custom system setup.
#               Executes main setup function.
#===============================================================================

#===============================================================================
# Other scripts usage
#===============================================================================

source "settings.conf"
source "functions.sh"

#===============================================================================
# Log file for this script
#===============================================================================

LOG_FILE="$PROJECT_SETUP_CUSTOM_LOG_FILE"

#===============================================================================
# Helper functions
#===============================================================================

addUser()
{
    if [[ $# -lt 4 ]];then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        err "1" "$FUNCNAME" "failed to add user"
    fi

    local mainGroup="$1"
    local additionalGroups="$2"
    local shell="$3"
    local name="$4"

    log "Add user..."

    cmd "useradd -m -g $mainGroup -G $additionalGroups -s $shell $name"
    err "$?" "$FUNCNAME" "failed to add user"

    log "Add user...done"
}

setUserPassword()
{
    if [[ $# -lt 1 ]];then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        err "1" "$FUNCNAME" "failed to set user password"
    fi

    log "Set user password..."

    local ask=1
    local name="$1"

    while [ $ask -ne 0 ]; do
        log "Provide password for user $name"
        cmd "passwd $name"
        ask=$?
    done

    log "Set user password...done"
}

setSudoer()
{
    if [[ $# -lt 1 ]];then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        err "1" "$FUNCNAME" "failed to set sudoer"
    fi

    log "Set sudoer..."

    local name="$1"

    # TODO - do it in a safer way... Here just for experiments
    cmd "echo \"$name ALL=(ALL) ALL\" >> /etc/sudoers"
    err "$?" "$FUNCNAME" "failed to set sudoer"

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
        cmd "cp $original $backup"
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
        cmd "ln -s $linkTarget $linkName"
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

    cmd "systemctl enable $service"
    return $?
}

startService()
{
    if [[ $# -lt 1 ]]; then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        return 1
    fi

    local service="$1"

    cmd "systemctl start $service"
    return $?
}

createDotfilesBackupDir()
{
    reqVar "DOTFILES_BACKUP_DIR" "$FUNCNAME"

    local retval=0

    # Check if backup dir exists
    if [[ ! -d $DOTFILES_BACKUP_DIR ]]; then
        cmd "mkdir -p $DOTFILES_BACKUP_DIR"
        retval="$?"
    fi

    return $retval
}

installDotfile()
{
    reqVar "DOTFILES_BACKUP_DIR" "$FUNCNAME"
    reqVar "DOTFILES_SOURCE_DIR" "$FUNCNAME"
    reqVar "USER1_HOME" "$FUNCNAME"

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
    cmd "rm -f $USER1_HOME/$dotfile"
    retval="$?"
    if [[ $retval -ne 0  ]]; then
        log "$FUNCNAME: failed to delete original dotfile"\
            " $USER1_HOME/$dotfile: $retval"
        return 4
    fi

    # Ensure that for nested dotfile the path exists
    if [[ $nested -eq 1 ]]; then
        cmd "mkdir -p $USER1_HOME/$dotfileHomePath"
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
        log "$FUNCNAME: failed to create link to new dotfile"\
            "$DOTFILES_SOURCE_DIR/$dotfile: $retval"
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

    cmd "chown -R $userName:users $userHome"
    err "$?" "$FUNCNAME" "failed to change home dir ownership"

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
    reqVar "USER1_MAIN_GROUP" "$FUNCTION"
    reqVar "USER1_ADDITIONAL_GROUPS" "$FUNCTION"
    reqVar "USER1_SHELL" "$FUNCTION"
    reqVar "USER1_NAME" "$FUNCTION"

    log "Add user1..."

    cmd "useradd -m -g $USER1_MAIN_GROUP -G $USER1_ADDITIONAL_GROUPS -s"\
        "$USER1_SHELL $USER1_NAME"
    err "$?" "$FUNCNAME" "failed to add user 1"

    log "Add user1...done"
}

setUser1Password()
{
    reqVar "USER1_NAME" "$FUNCTION"

    log "Set user 1 password..."

    setUserPassword "$USER1_NAME"

    log "Set user 1 password...done"
}

setUser1Sudoer()
{
    reqVar "USER1_NAME" "$FUNCTION"

    log "Set user1 sudoer..."

    setSudoer "$USER1_NAME"

    log "Set user1 sudoer...done"
}

#===================
# Common system packages
#===================

installAlsa()
{
    reqVar "ALSA_PACKAGES" "$FUNCTION"

    log "Install alsa..."

    installPackage $ALSA_PACKAGES
    err "$?" "$FUNCNAME" "failed to install alsa"

    log "Install alsa...done"
}

#===================
# Common software packages
#===================

installVim()
{
    reqVar "VIM_PACKAGES" "$FUNCTION"

    log "Install vim..."

    installPackage $VIM_PACKAGES
    err "$?" "$FUNCNAME" "failed to install vim"

    log "Install vim...done"
}

installMc()
{
    reqVar "MC_PACKAGES" "$FUNCTION"

    log "Install mc..."

    installPackage $MC_PACKAGES
    err "$?" "$FUNCNAME" "failed to install mc"

    log "Install mc...done"
}

installGit()
{
    reqVar "GIT_PACKAGES" "$FUNCTION"

    log "Install git..."

    installPackage $GIT_PACKAGES
    err "$?" "$FUNCNAME" "failed to install git"

    log "Install git...done"
}

#===================
# Common configuration
#===================

configurePacman()
{
    log "Configure pacman..."

    uncommentVar "TotalDownload" "/etc/pacman.conf"
    err "$?" "$FUNCNAME" "failed to configure pacman"

    log "Configure pacman...done"
}

configureGitUser()
{
    reqVar "GIT_USER_EMAIL" "$FUNCNAME"
    reqVar "GIT_USER_NAME" "$FUNCNAME"

    log "Configure git user..."

    cmd "git config --global user.email \"$GIT_USER_EMAIL\""
    err "$?" "$FUNCNAME" "failed to configure git user email"

    cmd "git config --global user.name \"$GIT_USER_NAME\""
    err "$?" "$FUNCNAME" "failed to configure git user name"

    log "Configure git user...done"
}

setBootloaderKernelParams()
{
    reqVar "ROOT_PARTITION_HDD" "$FUNCNAME"
    reqVar "ROOT_PARTITION_NB" "$FUNCNAME"
    reqVar "BOOTLOADER_KERNEL_PARAMS" "$FUNCNAME"

    log "Set bootloader kernel params..."

    local src="APPEND root.*$"
    local path="$PARTITION_PREFIX$ROOT_PARTITION_HDD$ROOT_PARTITION_NB"
    local bkp="$BOOTLOADER_KERNEL_PARAMS"
    local params="$path $bkp"
    local dst="APPEND root=$params"
    local subst="s|$src|$dst|"
    local file="/boot/syslinux/syslinux.cfg"
    cmd "sed -i \"$subst\" $file"
    err "$?" "$FUNCNAME" "failed to set bootloader kernel params"

    log "Set bootloader kernel params...done"
}

disableSyslinuxBootMenu()
{
    log "Disable syslinux boot menu..."

    commentVar "UI" "/boot/syslinux/syslinux.cfg"
    err "$?" "$FUNCNAME" "failed to disable syslinux boot menu"

    log "Disable syslinux boot menu...done"
}

setConsoleLoginMessage()
{
    # Do not require COSNOLE_LOGIN_MSG - when empty, no message will be used

    log "Set console login message..."

    # Remove welcome message
    cmd "rm -f /etc/issue"
    err "$?" "$FUNCNAME" "failed to remove /etc/issue file"

    # Set new welcome message, if present
    if [ ! -z "$CONSOLE_LOGIN_MSG" ];then
        cmd "echo $CONSOLE_LOGIN_MSG > /etc/issue"
        err "$?" "$FUNCNAME" "failed to set console login message"
    else
        log "Console welcome message not set, /etc/issue file deleted"
    fi

    log "Set console login message...done"
}

# This requires image recreation for changes to take effect
setEarlyTerminalFont()
{
    log "Set early terminal font..."

    # Set hooks
    local src="^HOOKS.*$"
    local dst="HOOKS=\\\"$HOOKS\\\""
    local subst="s|$src|$dst|"
    local file="/etc/mkinitcpio.conf"
    cmd "sed -i \"$subst\" $file"
    err "$?" "$FUNCNAME" "failed to set early terminal font"

    log "Set early terminal font...done"
}

initAlsa()
{
    log "Init alsa..."

    cmd "alsactl init"
    # May return error 99 - ignore it

    log "Init alsa...done"
}

unmuteAlsa()
{
    log "Unmute alsa..."

    cmd "amixer sset Master unmute"
    err "$?" "$FUNCNAME" "failed to unmute alsa"

    log "Unmute alsa...done"
}

#=======================================
# Project repository cloning
#=======================================

cloneProjectRepo()
{
    reqVar "PROJECT_REPO_URL" "$FUNCNAME"
    reqVar "PROJECT_REPO_DST" "$FUNCNAME"

    log "Clone $PROJECT_NAME repo..."

    cmd "git clone $PROJECT_REPO_URL $PROJECT_REPO_DST"
    err "$?" "$FUNCNAME" "failed to clone $PROJECT_NAME repo"

    log "Clone $PROJECT_NAME repo...done"
}

checkoutCurrentBranch()
{
    reqVar "PROJECT_REPO_DST" "$FUNCNAME"
    reqVar "PROJECT_BRANCH" "$FUNCNAME"

    log "Checkout current branch..."

    # Execute git commands from destination path
    cmd "git -C $PROJECT_REPO_DST checkout $PROJECT_BRANCH"
    err "$?" "$FUNCNAME" "failed to checkout current branch"

    log "Checkout current branch...done"
}

copyOverProjectFiles()
{
    reqVar "PROJECT_ROOT_PATH" "$FUNCNAME"
    reqVar "USER1_HOME" "$FUNCNAME"

    log "Copy over $PROJECT_NAME files..."

    cmd "cp -r $PROJECT_ROOT_PATH $USER1_HOME"
    err "$?" "$FUNCNAME" "failed to copy over $PROJECT_NAME files"

    log "Copy over $PROJECT_NAME files...done"
}

commitAdjustments()
{
    reqVar "PROJECT_REPO_DST" "$FUNCNAME"
    reqVar "CUSTOM_COMMIT_COMMENT" "$FUNCNAME"

    log "Commit adjustments..."

    if [[ -n "$(git -C $PROJECT_REPO_DST status --porcelain)" ]]; then
        cmd "git -C $PROJECT_REPO_DST commit -a -m \"$CUSTOM_COMMIT_COMMENT\""
        err "$?" "$FUNCNAME" "failed to commit adjustments"
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
    reqVar "XORG_BASIC_PACKAGES" "$FUNCNAME"

    log "Install xorg basics..."

    installPackage $XORG_BASIC_PACKAGES
    err "$?" "$FUNCNAME" "failed to install xorg basics"

    log "Install xorg basics...done"
}

installXorgAdditional()
{
    reqVar "XORG_ADDITIONAL_PACKAGES" "$FUNCNAME"

    log "Install xorg additional..."

    installPackage $XORG_ADDITIONAL_PACKAGES
    err "$?" "$FUNCNAME" "failed to install xorg additional"

    log "Install xorg additional...done"
}

#===================
# Individual software packages
#===================

#=========
# Console-based
#=========


installDvtm()
{
    reqVar "DVTM_PACKAGES" "$FUNCNAME"
    log "Install dvtm..."

    installPackage $DVTM_PACKAGES
    err "$?" "$FUNCNAME" "failed to install dvtm"

    log "Install dvtm...done"
}

installCustomizedDvtm()
{
    reqVar "DVTM_GIT_REPO" "$FUNCNAME"
    reqVar "DVTM_BUILD_PATH" "$FUNCNAME"
    reqVar "DVTM_CUSTOM_BRANCH" "$FUNCNAME"
    reqVar "DVTM_ACTIVE_COLOR" "$FUNCNAME"
    reqVar "DVTM_MOD_KEY" "$FUNCNAME"
    reqVar "CUSTOM_COMMIT_COMMENT" "$FUNCNAME"

    log "Install customized dvtm..."

    cmd "git clone $DVTM_GIT_REPO $DVTM_BUILD_PATH"
    err "$?" "$FUNCNAME" "failed to clone dvtm repository"

    cmd "git -C $DVTM_BUILD_PATH checkout -b $DVTM_CUSTOM_BRANCH"
    err "$?" "$FUNCNAME" "failed to checkout new branch"

    # Change default blue color to something brighter
    # to make it visible on older CRT monitor
    local src="BLUE"
    local dst="$DVTM_ACTIVE_COLOR"
    local subst="s|$src|$dst|g"
    local file="$DVTM_BUILD_PATH/config.def.h"
    cmd "sed -i \"$subst\" $file"
    err "$?" "$FUNCNAME" "failed to change active color"

    # Change default mod key - 'g' is not convenient to be used with CTRL key
    src="#define MOD CTRL('g')"
    dst="#define MOD CTRL('$DVTM_MOD_KEY')"
    subst="s|$src|$dst|g"
    file="$DVTM_BUILD_PATH/config.def.h"
    cmd "sed -i \"$subst\" $file"
    err "$?" "$FUNCNAME" "failed to change mod key"

    cmd "git -C $DVTM_BUILD_PATH commit -a -m \"$CUSTOM_COMMIT_COMMENT\""
    err "$?" "$FUNCNAME" "failed to commit adjustments"

    cmd "make -C $DVTM_BUILD_PATH"
    err "$?" "$FUNCNAME" "failed to make dvtm"

    cmd "make -C $DVTM_BUILD_PATH install"
    err "$?" "$FUNCNAME" "failed to install dvtm"

    log "Install customized dvtm...done"
}

installElinks()
{
    reqVar "ELINKS_PACKAGES" "$FUNCNAME"

    log "Install elinks..."

    installPackage $ELINKS_PACKAGES
    err "$?" "$FUNCNAME" "failed to install elinks"

    log "Install elinks...done"
}

installVirtualboxGuestAdditions()
{
    reqVar "VIRTUALBOX_GUEST_UTILS_PACKAGES" "$FUNCNAME"
    reqVar "VIRTUALBOX_GUEST_UTILS_MODULES" "$FUNCNAME"
    reqVar "VIRTUALBOX_GUEST_UTILS_MODULES_FILE" "$FUNCNAME"

    log "Install virtualbox guest additions..."

    # Install the packages
    installPackage $VIRTUALBOX_GUEST_UTILS_PACKAGES
    err "$?" "$FUNCNAME" "failed to install virtualbox package"

    # Load required modules
    cmd "modprobe -a $VIRTUALBOX_GUEST_UTILS_MODULES"
    err "$?" "$FUNCNAME" "failed to load required modules"

    # Setup modules to be loaded on startup
    if [ ! -z "$VIRTUALBOX_GUEST_UTILS_MODULES" ]; then
        for module in $VIRTUALBOX_GUEST_UTILS_MODULES
        do
            cmd "echo $module >> $VIRTUALBOX_GUEST_UTILS_MODULES_FILE"
            err "$?" "$FUNCNAME"\
                "failed to setup module to be loaded on startup"
        done
    fi

    log "Install virtualbox guest additions...done"
}

#=========
# GUI-based
#=========

installRxvtUnicode()
{
    reqVar "RXVTUNICODE_PACKAGES" "$FUNCNAME"

    log "Install rxvt unicode..."

    installPackage $RXVTUNICODE_PACKAGES
    err "$?" "$FUNCNAME" "failed to install rxvt unicode"

    log "Install rxvt unicode...done"
}

installGuiFonts()
{
    reqVar "GUI_FONT_PACKAGES" "$FUNCNAME"

    log "Install gui fonts..."

    installPackage $GUI_FONT_PACKAGES
    err "$?" "$FUNCNAME" "failed to install gui fonts"

    log "Install gui fonts...done"
}

installDwm()
{
    reqVar "DWM_PACKAGES" "$FUNCNAME"

    log "Install dwm..."

    installPackage $DWM_PACKAGES
    err "$?" "$FUNCNAME" "failed to install dwm"

    log "Install dwm...done"
}

#installCustomizedDwm()
#{
#    reqVar "DWM_GIT_REPO" "$FUNCNAME"
#    reqVar "DWM_BUILD_PATH" "$FUNCNAME"
#    reqVar "DWM_CUSTOM_BRANCH" "$FUNCNAME"
#    reqVar "DWM_BASE_COMMIT" "$FUNCNAME"
#    reqVar "DWM_TERMINAL_EMULATOR_COMMAND" "$FUNCNAME"
#    reqVar "CUSTOM_COMMIT_COMMENT" "$FUNCNAME"
#
#    log "Installing customized dwm..."
#
#    # Clone project from git
#    cmd "git clone $DWM_GIT_REPO $DWM_BUILD_PATH"
#    err "$?" "$FUNCNAME" "failed to clone dwm repository"
#
#    # Newest commit was not working... use specific, working version
#    cmd "git -C $DWM_BUILD_PATH checkout $DWM_BASE_COMMIT -b $DWM_CUSTOM_BRANCH"
#    err "$?" "$FUNCNAME" "failed to checkout older commit as a new branch"
#
#    # Configure necessary settings
#    local src="PREFIX = /usr/local"
#    local dst="PREFIX = /usr"
#    local subst="s|$src|$dst|g"
#    local file="$DWM_BUILD_PATH/config.mk"
#    cmd "sed -i \"$subst\" $file"
#    err "$?" "$FUNCNAME" "failed to change dwm prefix"
#
#    src="X11INC = /usr/X11R6/incude"
#    dst="X11INC = /usr/include/X11"
#    subst="s|$src|$dst|g"
#    file="$DWM_BUILD_PATH/config.mk"
#    cmd "sed -i \"$subst\" $file"
#    err "$?" "$FUNCNAME" "failed to change dwm x11 include path"
#
#    src="X11LIB = /usr/X11R6/lib"
#    dst="X11LIB = /usr/lib/X11"
#    subst="s|$src|$dst|g"
#    file="$DWM_BUILD_PATH/config.mk"
#    cmd "sed -i \"$subst\" $file"
#    err "$?" "$FUNCNAME" "failed to change dwm x11 lib path"
#
#    # Set terminal command to be launched on shortcut invocation
#    src="\\\"st\\\""
#    dst="\\\"$DWM_TERMINAL_EMULATOR_COMMAND\\\""
#    subst="s|$src|$dst|g"
#    file="$DWM_BUILD_PATH/config.def.h"
#    cmd "sed -i \"$subst\" $file"
#    err "$?" "$FUNCNAME" "failed to change dwm terminal emulator command"
#
#    # Change resizehints to false for better aligned terminal windows
#    src="static const Bool resizehints = True"
#    dst="static const Bool resizehints = False"
#    subst="s|$src|$dst|g"
#    file="$DWM_BUILD_PATH/config.def.h"
#    cmd "sed -i \"$subst\" $file"
#    err "$?" "$FUNCNAME" "failed to change resizehints"
#
#    # Save configuration as new commit
#    cmd "git -C $DWM_BUILD_PATH commit -a -m \"$CUSTOM_COMMIT_COMMENT\""
#    err "$?" "$FUNCNAME" "failed to commit adjustments"
#
#    # Install
#    cmd "make -C $DWM_BUILD_PATH clean install"
#    err "$?" "$FUNCNAME" "failed to build and install dwm"
#
#    log "Installing customized dwm...done"
#}

installCustomizedDwm()
{
    reqVar "DWM_GIT_REPO" "$FUNCNAME"
    reqVar "DWM_BUILD_PATH" "$FUNCNAME"
    reqVar "DWM_BASE_COMMIT" "$FUNCNAME"
    reqVar "DWM_CUSTOM_BRANCH" "$FUNCNAME"
    reqVar "PATCHES_DIR" "$FUNCNAME"
    reqVar "DWM_CUSTOM_PATCH_FILE" "$FUNCNAME"
    reqVar "CUSTOM_COMMIT_COMMENT" "$FUNCNAME"

    log "Installing customized dwm..."

    # Clone project from git
    cmd "git clone $DWM_GIT_REPO $DWM_BUILD_PATH"
    err "$?" "$FUNCNAME" "failed to clone dwm repository"

    # Newest commit was not working... use specific, working version
    cmd "git -C $DWM_BUILD_PATH checkout $DWM_BASE_COMMIT -b $DWM_CUSTOM_BRANCH"
    err "$?" "$FUNCNAME" "failed to checkout older commit as a new branch"

    # Apply patch with customizations
    cmd "git -C $DWM_BUILD_PATH apply $PATCHES_DIR/$DWM_CUSTOM_PATCH_FILE"
    err "$?" "$FUNCNAME" "failed to apply custom dwm patch"

    # Add changes introduced with patch. Use add . since new files may be added.
    cmd "git -C $DWM_BUILD_PATH add ."
    err "$?" "$FUNCNAME" "failed to add patch changes"

    # Save configuration as new commit
    cmd "git -C $DWM_BUILD_PATH commit -m \"$CUSTOM_COMMIT_COMMENT\""
    err "$?" "$FUNCNAME" "failed to commit adjustments"

    # Install
    cmd "make -C $DWM_BUILD_PATH clean install"
    err "$?" "$FUNCNAME" "failed to build and install dwm"

    log "Installing customized dwm...done"
}

installDmenu()
{
    reqVar "DMENU_PACKAGES" "$FUNCNAME"

    log "Install dmenu..."

    installPackage $DMENU_PACKAGES
    err "$?" "$FUNCNAME" "failed to install dmenu"

    log "Install dmenu...done"
}

installOpera()
{
    reqVar "OPERA_PACKAGES" "$FUNCNAME"

    log "Install opera..."

    installPackage $OPERA_PACKAGES
    err "$?" "$FUNCNAME" "failed to install opera"

    log "Install opera...done"
}

#===================
# Individual configuration
#===================

setVirtualboxSharedFolder()
{
    reqVar "USER1_NAME" "$FUNCNAME"
    reqVar "USER1_HOME" "$FUNCNAME"
    reqVar "VIRTUALBOX_SHARED_FOLDER_NAME" "$FUNCNAME"

    log "Set virtualbox shared folder..."

    # Create /media folder
    cmd "mkdir /media"
    err "$?" "$FUNCNAME" "failed to create /media dir"

    # Add user1 to vboxsf group
    cmd "gpasswd -a $USER1_NAME vboxsf"
    err "$?" "$FUNCNAME" "failed to add user to vboxsf group"

    # Enable vboxservice service
    enableService "vboxservice"
    err "$?" "$FUNCNAME" "failed to enable vboxservice"

    # Start vboxservice (needed for link creation)
    startService "vboxservice"
    err "$?" "$FUNCNAME" "failed to start vboxservice"

    # Wait a moment for a started service to do its job
    cmd "sleep 5"

    # Create link for easy access
    createLink\
        "/media/sf_$VIRTUALBOX_SHARED_FOLDER_NAME"\
        "$USER1_HOME/$VIRTUALBOX_SHARED_FOLDER_NAME"
    err "$?" "$FUNCNAME" "failed to create link to shared folder"

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
    err "$?" "$FUNCNAME" "failed to install bash_profile dotfile"

    log "Install bash_profile dotfile...done"
}

installBashrcDotfile()
{
    log "Install bashrc dotfile..."

    installDotfile ".bashrc" ""
    err "$?" "$FUNCNAME" "failed to install bashrc dotfile"

    log "Install bashrc dotfile...done"
}

installDircolorssolarizedDotfile()
{
    log "Install .dir_colors_solarized dotfile..."

    installDotfile ".dir_colors_solarized" ""
    err "$?" "$FUNCNAME" "failed to install .dir_colors_solarized dotfile"

    log "Install .dir_colors_solarized dotfile...done"
}

# vim

installVimrcDotfile()
{
    log "Install vimrc dotfile..."

    installDotfile ".vimrc" ""
    err "$?" "$FUNCNAME" "failed to install vimrc dotfile"

    log "Install vimrc dotfile...done"
}

installVimsolarizedDotfile()
{
    log "Install solarized.vim dotfile..."

    installDotfile "solarized.vim" ".vim/colors"
    err "$?" "$FUNCNAME" "failed to install solarized.vim dotfile"

    log "Install solarized.vim dotfile...done"
}

# mc

installMcsolarizedDotfile()
{
    log "Install mc_solarized.ini dotfile..."

    installDotfile "mc_solarized.ini" ".config/mc"
    err "$?" "$FUNCNAME" "failed to install mc_solarized.ini dotfile"

    log "Install mc_solarized.ini dotfile...done"
}

# git

installGitconfigDotfile()
{
    log "Install .gitconfig dotfile..."

    installDotfile ".gitconfig" ""
    err "$?" "$FUNCNAME" "failed to install .gitconfig dotfile"

    log "Install .gitconfig dotfile...done"
}

# X

installXinitrcDotfile()
{
    log "Install .xinitrc dotfile..."

    installDotfile ".xinitrc" ""
    err "$?" "$FUNCNAME" "failed to install .xinitrc dotfile"

    log "Install .xinitrc dotfile...done"
}

installXresourcesDotfile()
{
    log "Install .Xresources dotfile..."

    installDotfile ".Xresources" ""
    err "$?" "$FUNCNAME" "failed to install .Xresources dotfile"

    log "Install .Xresources dotfile...done"
}

#===================
# Other
#===================

recreateImage()
{
    log "Recreate linux image..."

    cmd "mkinitcpio -p linux"
    err "$?" "$FUNCNAME" "failed to set recreate linux image"

    log "Recreate linux image...done"
}

changeUser1HomeOwnership()
{
    reqVar "USER1_NAME" "$FUNCNAME"
    reqVar "USER1_HOME" "$FUNCNAME"

    log "Change user1 home ownership..."

    changeHomeOwnership "$USER1_NAME" "$USER1_HOME"
    # TODO: following tSOE is redundand
    # function above already cheks that - improve in future
    err "$?" "$FUNCNAME" "failed to change user1 home dir ownership"

    log "Change user1 home ownership...done"
}

#=======================================
# Post setup actions
#=======================================

copyProjectLogFiles()
{
    reqVar "PROJECT_LOG_DIR" "$FUNCNAME"
    reqVar "PROJECT_REPO_DST" "$FUNCNAME"

    # Do not perform typical logging in this function...
    # This would spoil nice logs copied to user's dir

    cp -r $PROJECT_LOG_DIR $PROJECT_REPO_DST
    err "$?" "$FUNCNAME" "failed to copy project log files"
}

#===============================================================================
# Main setup function
#===============================================================================

setupCustom()
{
    createLogDir    # Should be created by basic setup; just to be sure

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
    initAlsa                # Initialize all devices to a default state
    unmuteAlsa              # This should be enough on real HW

    #=======================================
    # Project repository cloning
    #=======================================

    cloneProjectRepo
    checkoutCurrentBranch
    copyOverProjectFiles
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

    #=========
    # Console-based
    #=========

    #installDvtm            # Official repo version not good enough
    installCustomizedDvtm   # Use customized version instead
    installElinks
    installVirtualboxGuestAdditions

    #=========
    # GUI-based
    #=========

    installRxvtUnicode
    installGuiFonts
    #installDwm             # Official repo version not good enough
    installCustomizedDwm    # Use customized version instead
    installDmenu
    installOpera

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

    #=======================================
    # Post setup actions
    #=======================================

    copyProjectLogFiles
}

#===============================================================================
# Main setup function execution
#===============================================================================

setupCustom

