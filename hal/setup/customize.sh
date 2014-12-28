#!/bin/bash
#===============================================================================
# FILE:         customize.sh
#
# USAGE:        Execute from shell, e.g. ./customize.sh
#
# DESCRIPTION:  Installs basic Arch Linux system
#               TODO: Describe in more details
#===============================================================================

# Treat unset variables as an error when peforming parameter expansion
# Exit immediately on errors
set -o nounset errexit

# Include steps definitions
source steps.sh

# Determine variant name based on parent dir name
VARIANT=$(cd ../; pwd)
VARIANT=${VARIANT##*/}

# Set log file name
LOG_FILE="../logs/customize.log"

#-------------------------------------------------------------------------------
# Define customization function
#-------------------------------------------------------------------------------

customize()
{
    #---------------------------------------
    # Preparations
    #---------------------------------------
    setTemporaryFont
    createLogDir
    log "Customize..."
    configurePacman
    updatePackageList

    #---------------------------------------
    # User account
    #---------------------------------------
    addUser
    setUserPassword
    setSudoRights

    #---------------------------------------
    # Git and archon files
    #---------------------------------------
    installGit
    configureGitUser
    cloneArchonRepo
    checkoutCurrentBranch
    copyOverArchonFiles
    createVariantLink

    #---------------------------------------
    # Console programs
    #---------------------------------------

    #-------------------
    # vim
    #-------------------
    installVim
    installPathogen
    installNerdTree
    installNerdCommenter
    installTagbar
    installCtags

    installMc
    installTmux

    #---------------------------------------
    # Sound
    #---------------------------------------
    installAlsa
    initAlsa
    disablePcSpeaker
    installCmus

    #---------------------------------------
    # Dotfiles
    #---------------------------------------
    installBashprofileDotfile
    installBashrcDotfile
    installDirColorsSolarizedDotfile
    installVimrcDotfile
    installVimSolarizedDotfile
    installMcSolarizedDotfile
    installGitconfigDotfile
    installCmusColorThemeDotfile
    installTmuxConfDotfile

    #---------------------------------------
    # Boot process configuration
    #---------------------------------------
    setBootloaderKernelParams
    hideSysctlConsoleMessages
    disableSyslinuxBootMenu
    setConsoleLoginMessage
    setLastLoginMessage
    setMkinitcpioHooks                      # Requires image recreation
    setMkinitcpioModules                    # Requires imafe recreation
    setBootConsoleOutputLevels

    #---------------------------------------
    # Final steps
    #---------------------------------------
    recreateImage
    changeHomeOwnership
    log "Customize...done"
    copyProjectLogFiles
}

#-------------------------------------------------------------------------------
# Execute customization function
#-------------------------------------------------------------------------------

time customize

