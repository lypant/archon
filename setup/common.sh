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

