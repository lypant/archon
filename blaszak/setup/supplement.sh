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

# Set log file name
LOG_FILE="/home/adam/archon/blaszak/logs/supplement.log"

#-------------------------------------------------------------------------------
# Define supplementation function
#-------------------------------------------------------------------------------

supplement()
{
    log "Supplement..."

    #--------------------------------------
    # Misc AUR packages
    #--------------------------------------
    installMtpTools

    #-------------------
    # Printing
    #-------------------
    #installProprietaryPrinterDriver  # Required by HP P1102 printer

    #---------------------------------------
    # Android development environment
    #---------------------------------------
    #installJdk         # TODO: Prefer packages from official repositories
    #installAndroidEnv

    #--------------------------------------
    # Systemd services enabling
    #--------------------------------------
    enableUdiskieService

    log "Supplement...done"
}

#-------------------------------------------------------------------------------
# Execute supplementation function
#-------------------------------------------------------------------------------

time supplement

