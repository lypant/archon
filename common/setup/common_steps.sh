#!/bin/bash
#===============================================================================
# FILE:         common_steps.sh
#
# USAGE:        Include in ohter scripts, e.g. source common_steps.sh
#
# DESCRIPTION:  Arranges step functions into groups which are common
#               for all machines.
#               Contains only function definitions - they are not executed.
#
# CONVENTIONS:  A function should either return an error code or abort a script
#               on failure.
#               Names of functions returning value start with an underscore.
#               Exception:  log function - returns result but always neglected,
#                           so without an underscore - for convenience
#===============================================================================

#===============================================================================
# Installation
#===============================================================================

#=======================================
# Installation groups
#=======================================

commonPreInstall()
{
    createLogDir
    log "Install..."

    setConsoleFontTemporarily
    updatePackageList
    #installArchlinuxKeyring    # Individual
    #installLivecdVim           # Individual
}

commonPartitioning()
{
    createSwapPartition
    createBootPartition
    createRootPartition
    setBootPartitionBootable
    createSwap
    activateSwap
    createBootFileSystem
    createRootFileSystem
    # Root partition has to be mounted first
    mountRootPartition
    mountBootPartition
}

commonInstall()
{
    # Use only one of alternatives - rankMirrors or downloadMirrorList
    #rankMirrors
    downloadMirrorList
    installBaseSystem
    generateFstab
    #setTmpfsTmpSize    # Needed before reboot to install AUR packages nicely # Individual
    setHostName
    setLocales
    generateLocales
    setLanguage
    setLocalizationCtype
    setLocalizationNumeric
    setLocalizationTime
    setLocalizationCollate
    setLocalizationMonetary
    setLocalizationMeasurement
    setTimeZone
    setHardwareClock
    setConsoleKeymap
    setConsoleFont
    setConsoleFontmap
    setWiredNetwork
    installBootloader
    configureSyslinux
    setRootPassword
}

commonPostInstall()
{
    log "Install...done"

    copyProjectFiles
    unmountPartitions
}

#=======================================
# Installation main function
#=======================================

install()
{
    commonPreInstall
    individualPreInstall    # To be defined in individual_steps.sh
    commonPartitioning
    individualPartitioning  # To be defined in individual_steps.sh
    commonInstall
    individualInstall       # To be defined in individual_steps.sh
    commonPostInstall
    individualPostInstall   # To be defined in individual_steps.sh
}

#===============================================================================
# Customization
#===============================================================================

#=======================================
# Customization groups
#=======================================

commonPreCustomize()
{
    createLogDir
    log "Customize..."
}

commonCloneProjectRepository()
{
    :
}

commonCustomize()
{
    :
}

commonPostCustomize()
{
    log "Customize...done"
}

#=======================================
# Customization main function
#=======================================

customize()
{
    commonPreCustomize
    individualPreCustomize          # To be defined in individual_steps.sh
    commonCloneProjectRepository
    commonCustomize
    individualCustomize             # To be defined in individual_steps.sh
    commonPostCustomize
    individualPostCustomize         # To be defined in individual_steps.sh
}

