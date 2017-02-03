#!/bin/bash
#===============================================================================
# FILE:         install.sh
#
# USAGE:        Execute from shell, e.g. ./install.sh
#
# DESCRIPTION:  Installs basic Arch Linux system
#               TODO: Describe in more details
#===============================================================================

# Treat unset variables as an error when peforming parameter expansion
# Exit immediately on errors
set -o nounset -o errexit

# Include steps definitions
source steps.sh

# Set log file name
LOG_FILE="../logs/install.log"

#-------------------------------------------------------------------------------
# Define installation function
#-------------------------------------------------------------------------------

install()
{
    #---------------------------------------
    # Preparations
    #---------------------------------------
    setTemporaryFont
    createLogDir
    log "Install..."

    updatePackageList
    installArchlinuxKeyring

    #---------------------------------------
    # Disks, partitions and file systems
    #---------------------------------------
    createSwap
    activateSwap
    createRootFileSystem
    mountRootPartition

    #---------------------------------------
    # Base system installation
    #---------------------------------------
    #rankMirrors
    downloadMirrorList
    installBaseSystemLts

    #---------------------------------------
    # Base system configuration
    #---------------------------------------
    generateFstab
    setHostName

    #---------------------------------------
    # Localization
    #---------------------------------------
    setLocales
    generateLocales
    setLanguage
    setLocalizationCtype
    setLocalizationNumeric
    setLocalizationTime
    setLocalizationCollate
    setLocalizationMonetary
    setLocalizationMeasurement

    #---------------------------------------
    # Time
    #---------------------------------------
    setTimeZone
    setHardwareClock

    #---------------------------------------
    # Console
    #---------------------------------------
    setConsoleKeymap
    setConsoleFont
    setConsoleFontmap

    #---------------------------------------
    # Network
    #---------------------------------------
    setWiredNetwork

    #---------------------------------------
    # Bootloader
    #---------------------------------------
    tempAlpmWorkaround                      # TODO: Remove when not needed
    installBootloader
    configureBootloader
    replacBootloaderKernelVersion
    createInitramfs

    #---------------------------------------
    # Root account
    #---------------------------------------
    setRootPassword

    log "Install...done"

    #---------------------------------------
    # Post-install steps
    #---------------------------------------
    copyProjectFiles
    unmountPartitions
}

#-------------------------------------------------------------------------------
# Execute installation function
#-------------------------------------------------------------------------------

time install

