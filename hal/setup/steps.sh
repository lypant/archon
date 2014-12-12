#!/bin/bash
#===============================================================================
# FILE:         steps.sh
#
# USAGE:        Include in other scripts, e.g. source steps.sh
#
# DESCRIPTION:  Defines but does not execute functions that can be used
#               in other scripts.
#               TODO: Describe in more details
#===============================================================================

# Treat unset variables as an error when peforming parameter expansion
# Exit immediately on errors
set -o nounset errexit

# Include functions definitions
source functions.sh

#-------------------------------------------------------------------------------
# Installation
#-------------------------------------------------------------------------------

setLivecdFont()
{
   setfont Lat2-Terminus16
}

createLogDir()
{
    local logDir="../logs"
    mkdir -p $logDir
    if [[ "$?" -ne 0 ]]; then
        echo "Failed to create log dir $logDir"
        echo "Aborting script!"
        exit 1
    fi
}

updatePackageList()
{
    log "Update package list..."
    cmd "pacman -Syy"
    err "$?" "$FUNCNAME" "failed to update package list"
    log "Update package list...done"
}

installArchlinuxKeyring()
{
    log "Install archlinux keyring..."
    installPackage archlinux-keyring
    log "Install archlinux keyring...done"
}

installLivecdVim()
{
    log "Install livecd vim..."
    installPackage vim
    log "Install livecd vim...done"
}

