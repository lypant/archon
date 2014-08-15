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
    :
}

individualPartitioning()
{
    :
}

individualInstall()
{
    :
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
    installVirtualboxGuestAdditions
    setVirtualboxSharedFolder
}

individualPostCustomize()
{
    :
}

