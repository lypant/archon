#!/bin/bash
#===============================================================================
# FILE:         custom_setup.sh
#
# USAGE:        Execute from shell, e.g. ./custom_setup.sh
#
# DESCRIPTION:  TODO: Describe
#===============================================================================

#===============================================================================
# Other scripts includes
#===============================================================================

source ../../../include/setup/archon_settings.conf
source ../../../include/setup/settings.conf
source settings.conf
source ../../../include/setup/functions.sh

#===============================================================================
# Log file for this script
#===============================================================================

LOG_FILE="$CUSTOM_SETUP_LOG_FILE"

#===============================================================================
# Main setup function
#===============================================================================

# Requires:
#   LOG_FILE
#   LOG_PREFIX
customSetup()
{
    createLogDir

    log "Custom setup..."

    #=======================================
    # LiveCD environment preparation
    #=======================================

    setConsoleFontTemporarily

    #=======================================
    # Common setup
    #=======================================

    setMultilibRepository   # Needed for Android development

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
    # Not needed for VirtualBox
    #setMkinitcpioModules    # Requires linux image recreation
    setMkinitcpioHooks      # Requires linux image recreation
    initAlsa                # Initialize all devices to a default state
    unmuteAlsa              # This should be enough on real HW
    setPcmModuleLoading
    disablePcSpeaker

    log "Custom setup...done"
}

#===============================================================================
# Main setup function execution
#===============================================================================

customSetup

