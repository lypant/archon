#!/bin/bash
#===============================================================================
# FILE:         basic_setup.sh
#
# USAGE:        Execute from shell, e.g. ./basic_setup.sh
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

LOG_FILE="$BASIC_SETUP_LOG_FILE"

#===============================================================================
# Main setup function
#===============================================================================

# Requires:
#   LOG_FILE
#   LOG_PREFIX
basicSetup()
{
    createLogDir

    _log "Basic setup..."

    #=======================================
    # LiveCD environment preparation
    #=======================================

    setConsoleFontTemporarily
    updatePackageList
    installArchlinuxKeyring
    installLivecdVim

    _log "Basic setup...done"
}

#===============================================================================
# Main setup function execution
#===============================================================================

basicSetup

