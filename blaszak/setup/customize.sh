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
    setMultilibRepository   # TODO Is it necessary once Arch is 64bit only?
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
    workaroundCaCerts   # TODO: check in future if still needed
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
    installVimAirline
    installVimFugitive

    installMc
    installRanger
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
    installPackagesRequiredByI3Shell

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
    #installFirefox     # no ALSA support anymore; don't want to switch to PA
    installChromium
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
    setAlsaSoundCards
    disablePcSpeaker
    installCmus

    #---------------------------------------
    # Partitions and file systems
    #---------------------------------------
    installFuseExfat
    installAutomountTools
    configureAutomountTools
    configureMtpTools # Packages will be installed in supplementation script
    setTmpfsTmpSize # To install large AUR packages in supplementation script
    setDataPartition
    setCdromMounting
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
    installCmusAutosaveDotfile
    installTmuxConfDotfile
    copyUdiskieServiceDotfile           # Activate at supplementation stage
    installRangerDotfile
    installRifleDotfile

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

    #---------------------------------------
    # Printing
    #---------------------------------------
    #installCups
    #enableCupsService
    #installPrinterDriver

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

