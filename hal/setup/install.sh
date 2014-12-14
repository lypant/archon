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
    #---------------------------------------
    # Livecd steps
    #---------------------------------------

    setLivecdFont
    createLogDir
    log "Install..."

    updatePackageList
    installArchlinuxKeyring
    installLivecdVim

    #---------------------------------------
    # Disks, partitions and file systems
    #---------------------------------------

    checkInitialPartitions
    createSwapPartition
    createBootPartition
    createRootPartition
    checkCreatedPartitions
    setBootPartitionBootable
    createSwap
    activateSwap
    createBootFileSystem
    createRootFileSystem
    mountRootPartition
    mountBootPartition

    unmountPartitions

    log "Install...done"
}

#-------------------------------------------------------------------------------
# Execute installation function
#-------------------------------------------------------------------------------

install
