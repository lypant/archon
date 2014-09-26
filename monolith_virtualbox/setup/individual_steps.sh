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
}

individualPartitioning()
{
    :
}

individualInstall()
{
    replacSyslinuxKernelVersion
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
    :
}

individualCustomize()
{
    # System
    removeMesaLibgl

    installVirtualboxGuestAdditions
    setVirtualboxSharedFolder
}

individualPostCustomize()
{
    :
}

