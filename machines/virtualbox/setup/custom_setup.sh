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

    #=======================================
    # Project repository cloning
    #=======================================

    cloneProjectRepo
    checkoutCurrentBranch
    copyOverProjectFiles

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
    installCmus
    # TODO: installJdk
    # TODO: installAndroidEnv
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
    installConky
    installXbindkeys
    installWmname           # Fix misbehaving Java apps in dwm
    installVlc

    #===================
    # Individual configuration
    #===================

    setVirtualboxSharedFolder

    #===================
    # Other
    #===================

    recreateImage   # Required by mkinitcpio-related steps
    changeUser1HomeOwnership

    log "Custom setup...done"

    #=======================================
    # Post setup actions
    #=======================================

    copyProjectLogFiles
}

#===============================================================================
# Main setup function execution
#===============================================================================

customSetup

