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
    installConky

    #-------------------
    # Programs
    #-------------------
    installCustomizedDwm
    installDmenu
    installRxvtUnicode
    installFirefox
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

    installXinitrcDotfile
    installXresourcesDotfile
    installXbindkeysrcDotfile
    installConkyDotfile

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
    # Partitions and file systems
    #---------------------------------------
    setTmpfsTmpSize # To install large AUR packages in supplementation script
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

