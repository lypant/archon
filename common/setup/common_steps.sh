#!/bin/bash
#===============================================================================
# FILE:         common_steps.sh
#
# USAGE:        Include in ohter scripts, e.g. source common_steps.sh
#
# DESCRIPTION:  Arranges step functions into groups which are common
#               for all machines.
#               Contains only function definitions - they are not executed.
#===============================================================================

set -o nounset errexit

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

    #setConsoleFontTemporarily  # Individual
    updatePackageList
    #installArchlinuxKeyring    # Individual
    #installLivecdVim           # Individual
}

commonPartitioning()
{
    checkSystemHdd
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
    # Needed before reboot to install AUR packages nicely
    #setTmpfsTmpSize    # Individual
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
    #replacSyslinuxKernelVersion    # Individual
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
    individualInstallEnv    # To be defined in individual_steps.sh
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

    #setConsoleFontTemporarily  # Individual
    configurePacman
    #setMultilibRepository   # Needed for Android development   # Individual
}

commonSetMainUser()
{
    addUser1
    setUser1Password
    setUser1Sudoer
}

commonInstallGit()
{
    updatePackageList
    installGit
    configureGitUser
}

commonCloneProjectRepository()
{
    cloneProjectRepo
    checkoutCurrentBranch
    copyOverProjectFiles
    createVariantLink
}

commonSetupProject()
{
    commonSetMainUser
    commonInstallGit
    commonCloneProjectRepository
}

commonCustomize()
{
    # System
    installXorgBasic
    #installXorgAdditional	# Individual
    installAlsa

    # Console based software
    installVim
    installMc
    installVifm
    #installDvtm            # Official repo version not good enough
    installCustomizedDvtm   # Use customized version instead
    installElinks
    installCmus
    #installJdk                         # Individual
    #installAndroidEnv                  # Individual
    #installVirtualboxGuestAdditions    # Individual

    # GUI based software
    installRxvtUnicode
    installGuiFonts
    #installDwm             # Official repo version not good enough
    installCustomizedDwm    # Use customized version instead
    installDmenu
    installOpera
    installFlashPlugin
    installConky
    #installXbindkeys       # Individual
    installWmname           # Fix misbehaving Java apps in dwm
    installVlc
    installFeh
    installEvince

    # Dotfiles
    installBashprofileDotfile
    installBashrcDotfile
    installDircolorssolarizedDotfile
    installVimrcDotfile
    installVimsolarizedDotfile
    installMcsolarizedDotfile
    installVifmrcDotfile
    installVifmSolarizedDotfile
    installGitconfigDotfile
    installCmusColorThemeDotfile
    installXinitrcDotfile
    installXresourcesDotfile
    installConkyDotfile
    #installXbindkeysDotfile    # Individual

    # Configuration
    setBootloaderKernelParams
    hideSysctlConsoleMessages
    disableSyslinuxBootMenu
    setConsoleLoginMessage
    #setMkinitcpioModules   # Requires linux image recreation  # Individual
    setMkinitcpioHooks      # Requires linux image recreation
    setBootConsoleOutputLevels
    initAlsa                # Initialize all devices to a default state
    #unmuteAlsa             # Individual
    disablePcSpeaker

    #setVirtualboxSharedFolder  # Individual
}

commonPostCustomize()
{
    recreateImage   # Required by mkinitcpio-related steps
    changeUser1HomeOwnership

    log "Customize...done"

    copyProjectLogFiles
}

#=======================================
# Customization main function
#=======================================

customize()
{
    individualCustomizeEnv          # To be defined in individual_steps.sh
    commonPreCustomize
    individualPreCustomize          # To be defined in individual_steps.sh
    commonSetupProject
    commonCustomize
    individualCustomize             # To be defined in individual_steps.sh
    commonPostCustomize
    individualPostCustomize         # To be defined in individual_steps.sh
}

