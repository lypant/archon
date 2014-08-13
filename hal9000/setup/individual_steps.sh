#!/bin/bash
#===============================================================================
# FILE:         individual_steps.sh
#
# USAGE:        Include in ohter scripts, e.g. source individual_steps.sh
#
# DESCRIPTION:  Arranges step functions which are specific for a particular
#               machine into logical groups.
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
    # Console based software
    installJdk
    installAndroidEnv
    installVirtualboxGuestAdditions

    # Dotfiles
    installXbindkeysDotfile

    # Configuration
    setMkinitcpioModules    # Requires linux image recreation
}

individualPostCustomize()
{
    :
}

