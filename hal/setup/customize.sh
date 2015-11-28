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
    setTemporaryFont
    createLogDir
    log "Customize..."
    setMultilibRepository
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
    installCompressionTools
    installIsoTools

    #---------------------------------------
    # GUI programs
    #---------------------------------------

    #-------------------
    # Xorg
    #-------------------
    installXorg
    removeMesaLibgl

    #-------------------
    # Video driver
    #-------------------
    installVideoDriver

    #-------------------
    # Fonts
    #-------------------
    installGuiFonts

    #-------------------
    # Config
    #-------------------
    installXbindkeys

    #-------------------
    # Programs
    #-------------------
    installI3
    installDmenu
    installRxvtUnicode
    installFirefox
    installFlashplugin
    installThunderbird
    installVlc
    installFeh
    installEvince
    installWmname

    #---------------------------------------
    # Sound
    #---------------------------------------
    installAlsa
    disablePcSpeaker
    installCmus

    #---------------------------------------
    # Partitions and file systems
    #---------------------------------------
    installFuseExfat
    installAutomountTools
    configureAutomountTools
    setTmpfsTmpSize # To install large AUR packages in supplementation script
    setDataPartition
    # TODO: Check Android device mounting

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
    copyUdiskieServiceDotfile           # Activate at supplementation stage

    installXinitrcDotfile
    installXresourcesDotfile
    installXbindkeysrcDotfile
    installI3ConfigDotfile
    installI3StatusConfigDoftile

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

    #-------------------
    # SSD adjustments
    #-------------------
    setRootPartitionTrim
    setIoScheduler
    setSwappiness
    setMakepkgBuilddir

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

