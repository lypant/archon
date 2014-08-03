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
}

commonPartitioning()
{
    :
}

commonInstall()
{
    :
}

commonPostInstall()
{
    log "Install...done"
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
    :
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
    :
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

