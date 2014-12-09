#!/bin/bash
#===============================================================================
# FILE:         install.sh
#
# USAGE:        Execute from shell, e.g. ./install.sh
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
LOG_FILE="../logs/install.log"

#-------------------------------------------------------------------------------
# Define installation function
#-------------------------------------------------------------------------------

install()
{
    createLogDir
    setLivecdFont
    helloArch
}

#-------------------------------------------------------------------------------
# Execute installation function
#-------------------------------------------------------------------------------

install
