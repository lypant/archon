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

    log "Basic setup..."

    #=======================================
    # LiveCD environment preparation
    #=======================================

    setConsoleFontTemporarily
    updatePackageList
    installArchlinuxKeyring
    installLivecdVim

    #=======================================
    # Partitions and file systems
    #=======================================

    createSwapPartition
    createBootPartition
    createRootPartition
    setBootPartitionBootable
    createSwap
    activateSwap
    createBootFileSystem
    createRootFileSystem
    # Root partition has to be mounted first
    mountRootPartition
    mountBootPartition

    #=======================================
    # Installation
    #=======================================

    # Use only one of alternatives - rankMirrors or downloadMirrorList
    #rankMirrors
    downloadMirrorList

    log "Basic setup...done"

    #=======================================
    # Post installation actions
    #=======================================

    unmountPartitions
}

#===============================================================================
# Main setup function execution
#===============================================================================

basicSetup

