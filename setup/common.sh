#!/bin/bash

echo common.sh

# USERS

addUser1() {
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

# SYSTEM PACKAGES

installAlsa()
{
    requiresVariable "ALSA_PACKAGES" "$FUNCTION"

    log "Install alsa..."

    installPackage $ALSA_PACKAGES
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install alsa"

    log "Install alsa...done"
}

# SOFTWARE PACKAGES

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

# CONFIGURATION

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

recreateImage()
{
    log "Recreate linux image..."

    executeCommand "mkinitcpio -p linux"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to set recreate linux image"

    log "Recreate linux image...done"
}

