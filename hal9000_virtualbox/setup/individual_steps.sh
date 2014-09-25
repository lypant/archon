#!/bin/bash
#===============================================================================
# FILE:         individual_steps.sh
#
# USAGE:        Include in ohter scripts, e.g. source individual_steps.sh
#
# DESCRIPTION:  Arranges step functions which are specific for a particular
#               machine into logical groups.
#               Contains only function definitions - they are not executed.
#===============================================================================

set -o nounset errexit

#===============================================================================
# Installation
#===============================================================================

#=======================================
# Installation groups
#=======================================

individualInstallEnv()
{
    setConsoleFontTemporarily
}

individualPreInstall()
{
    installArchlinuxKeyring
    installLivecdVim
}

individualPartitioning()
{
    :
}

individualInstall()
{
    setTmpfsTmpSize    # Needed before reboot to install AUR packages nicely
}

individualPostInstall()
{
    :
}

#===============================================================================
# Customization
#===============================================================================

#=======================================
# Customization groups
#=======================================

individualCustomizeEnv()
{
    setConsoleFontTemporarily
}

individualPreCustomize()
{
    setMultilibRepository   # Needed for Android development
}

individualCustomize()
{
    # System
    replaceMesaLibgl

    # Console based software
    #installJdk                     # Do not test on virtualbox
    #installAndroidEnv              # Do not test on virtualbox
    installVirtualboxGuestAdditions

    # Dotfiles
    installXbindkeysDotfile

    # Configuration
    setDataPartition
    #setMkinitcpioModules        # Not needed for virtualbox
    setVirtualboxSharedFolder
}

individualPostCustomize()
{
    :
}

