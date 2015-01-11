#!/bin/bash
#===============================================================================
# FILE:         supplement.sh
#
# USAGE:        Execute from shell, e.g. ./supplement.sh
#
# DESCRIPTION:  Installs AUR packages;
#               Use regular user account for launching as makepkg does not allow
#               root to install AUR packages - reason for separating AUR steps
#               into this separate script.
#===============================================================================

# Treat unset variables as an error when peforming parameter expansion
# Exit immediately on errors
set -o nounset -o errexit

# Include steps definitions
source steps.sh

# TODO: Get rid of variant link/variable? Hardcode 'hal'? Make it consistent
#       in all installation scripts

# Determine variant name based on parent dir name
VARIANT=$(cd ../; pwd)
VARIANT=${VARIANT##*/}

# Set log file name
LOG_FILE="/home/adam/archon/variant/logs/supplement.log"

#-------------------------------------------------------------------------------
# Define supplementation function
#-------------------------------------------------------------------------------

supplement()
{
    log "Supplement..."

    #---------------------------------------
    # Android development environment
    #---------------------------------------
    installJdk
    installAndroidEnv

    log "Supplement...done"
}

#-------------------------------------------------------------------------------
# Execute supplementation function
#-------------------------------------------------------------------------------

time supplement

