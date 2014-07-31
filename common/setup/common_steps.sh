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

CommonPreInstall()
{
    :
}

CommonPartitioning()
{
    :
}

CommonInstall()
{
    :
}

CommonPostInstall()
{
    :
}

#=======================================
# Installation main function
#=======================================

Install()
{
    CommonPreInstall
    CommonPartitioning
    IndividualPartitioning  # Defined in machine specific files
    CommonInstall
    IndividualInstall       # Defined in machine specific files
    CommonPostInstall
}

#===============================================================================
# Customization
#===============================================================================

#=======================================
# Customization groups
#=======================================

CommonPreCustomize()
{
    :
}

CommonCloneProjectRepository()
{
    :
}

CommonCustomize()
{
    :
}

CommonPostCustomize()
{
    :
}

#=======================================
# Customization main function
#=======================================

Customize()
{
    CommonPreCustomize
    CommonCloneProjectRepository
    CommonCustomize
    IndividualCustomize     # Defined in machine specific files
    CommonPostCustomize
}

