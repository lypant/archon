#!/bin/bash
#===============================================================================
# FILE:         customize.sh
#
# USAGE:        Execute from shell, e.g. ./customize.sh
#
# DESCRIPTION:  Installs basic Arch Linux system
#               TODO: Describe in more details
#
# TODO:        Group together program installation and its dotfile, if possible
#===============================================================================

# Treat unset variables as an error when peforming parameter expansion
# Exit immediately on errors
set -o nounset -o errexit

# Include steps definitions
source steps.sh

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
    installElinks
    installCompressionTools
    installIsoTools

    #---------------------------------------
    # Sound
    #---------------------------------------
    installAlsa
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
    installActkbdConfDotfile            # actkbd is installed in supplementation
    copyActkbdServiceDotfile            # actkbd is installed in supplementation

    #---------------------------------------
    # Boot process configuration
    #---------------------------------------
    setBootloaderKernelParams
    hideSysctlConsoleMessages
    disableSyslinuxBootMenu
    setConsoleLoginMessage
    setLastLoginMessage
    setMkinitcpioHooks                      # Requires image recreation
    #setMkinitcpioModules                   # Requires image recreation
    setBootConsoleOutputLevels

    #---------------------------------------
    # Partitions and file systems
    #---------------------------------------
    installAutomountTools
    configureAutomountTools
    setDataPartition

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

