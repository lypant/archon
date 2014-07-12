#!/bin/bash
#===============================================================================
# FILE:         custom_setup.sh
#
# USAGE:        Execute from shell, e.g. ./custom_setup.sh
#
# DESCRIPTION:  TODO: Describe
#===============================================================================

#===============================================================================
# Other scripts includes
#===============================================================================

source ../../../include/setup/archon_settings.conf
source ../../../include/setup/settings.conf
source settings.conf
source ../../../include/setup/functions.sh

#===============================================================================
# Log file for this script
#===============================================================================

LOG_FILE="$CUSTOM_SETUP_LOG_FILE"

#===============================================================================
# Main setup function
#===============================================================================

# Requires:
#   LOG_FILE
#   LOG_PREFIX
customSetup()
{
    createLogDir

    log "Custom setup..."

    #=======================================
    # LiveCD environment preparation
    #=======================================

    setConsoleFontTemporarily

    log "Custom setup...done"
}

#===============================================================================
# Main setup function execution
#===============================================================================

customSetup

