#!/bin/bash
#===============================================================================
# FILE:         customize.sh
#
# USAGE:        Execute from shell, e.g. ./customize.sh
#
# DESCRIPTION:  Installs basic Arch Linux system
#               TODO: Describe in more details
#===============================================================================

# Treat unset variables as an error when peforming parameter expansion
# Exit immediately on errors
set -o nounset errexit

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
    log "Customize..."

    configurePacman

    #---------------------------------------
    # User account
    #---------------------------------------
    addUser
    setUserPassword
    setSudoRights

    #---------------------------------------
    # Final steps
    #---------------------------------------
    changeHomeOwnership

    log "Customize...done"

    # TODO: Uncomment as soon as archon dir is created in home dir
    #copyProjectLogFiles
}

#-------------------------------------------------------------------------------
# Execute customization function
#-------------------------------------------------------------------------------

customize

