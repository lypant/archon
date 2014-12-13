#!/bin/bash
#===============================================================================
# FILE:         steps.sh
#
# USAGE:        Include in other scripts, e.g. source steps.sh
#
# DESCRIPTION:  Defines but does not execute functions that can be used
#               in other scripts.
#               TODO: Describe in more details
#===============================================================================

# Treat unset variables as an error when peforming parameter expansion
# Exit immediately on errors
set -o nounset errexit

# Include functions definitions
source functions.sh

#-------------------------------------------------------------------------------
# Installation
#-------------------------------------------------------------------------------

#---------------------------------------
# Livecd steps
#---------------------------------------

setLivecdFont()
{
   setfont Lat2-Terminus16
}

createLogDir()
{
    local logDir="../logs"
    mkdir -p $logDir
    if [[ "$?" -ne 0 ]]; then
        echo "Failed to create log dir $logDir"
        echo "Aborting script!"
        exit 1
    fi
}

updatePackageList()
{
    log "Update package list..."
    cmd "pacman -Syy"
    err "$?" "$FUNCNAME" "failed to update package list"
    log "Update package list...done"
}

installArchlinuxKeyring()
{
    log "Install archlinux keyring..."
    installPackage archlinux-keyring
    log "Install archlinux keyring...done"
}

installLivecdVim()
{
    log "Install livecd vim..."
    installPackage vim
    log "Install livecd vim...done"
}

#---------------------------------------
# Disks, partitions and file systems
#---------------------------------------

SYSTEM_HDD="sdc"

#checkSystemHdd()
#{
#    local hdd="/dev/$SYSTEM_HDD"
#    local cnt=$(lsblk $hdd | wc -l)
#
#    log "Check system hdd..."
#    if [[ "cnt" -gt 2 ]]; then
#        # There are some partitions already created, stop script execution
#        log "Disk $hdd already contains some partitions"
#        exit 1
#    fi
#    log "Check system hdd...done"
#}

checkInitialPartitions()
{
    local hdd="/dev/$SYSTEM_HDD"

    log "Check initial partitions..."
    checkPartitionsCount $hdd 0
    err "$?" "$FUNCNAME" "Disk $hdd already contains some partitions"
    log "Check initial partitions...done"
}

createSwapPartition()
{
    log "Create swap partition..."
    createPartition /dev/$SYSTEM_HDD p 1 +4G 82
    log "Create swap partition...done"
}

createBootPartition()
{
    log "Create boot partition..."
    createPartition /dev/$SYSTEM_HDD p 2 +512M 83
    log "Create boot partition...done"
}

createRootPartition()
{
    log "Create root partition..."
    createPartition /dev/$SYSTEM_HDD p 3 "" 83
    log "Create root partition...done"
}

checkCreatedPartitions()
{
    local hdd="/dev/$SYSTEM_HDD"

    log "Check created partitions..."
    checkPartitionsCount $hdd 3
    err "$?" "$FUNCNAME" "Disk $hdd does not contain required partitions"
    log "Check created partitions...done"
}


setBootPartitionBootable()
{
    log "Set boot partition bootable..."
    setPartitionBootable /dev/$SYSTEM_HDD 2
    log "Set boot partition bootable...done"
}

