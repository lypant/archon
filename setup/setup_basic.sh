#!/bin/bash

echo setup_basic.sh

source "setup.conf"
source "functions.sh"
source "livecd.sh"
source "disks.sh"
source "installation.sh"

# Set log file for basic setup
LOG_FILE="/root/archon/logs/setup_basic.log"

copyArchonFiles()
{
    requiresVariable "ARCHON_MNT_PATH" "$FUNCNAME"
    requiresVariable "ARCHON_LIVECD_PATH" "$FUNCNAME"

    log "Copy archon files..."

    # Do not perform logging in this function to not spoil nice logs copied to new system
    mkdir $ARCHON_MNT_PATH
    terminateScriptOnError "$?" "$FUNCNAME" "failed to copy archon files"

    cp -R $ARCHON_LIVECD_PATH/* $ARCHON_MNT_PATH
    terminateScriptOnError "$?" "$FUNCNAME" "failed to copy archon files"

    log "Copy archon files...done"
}

setupBasic()
{
    log "Setup basic..."

    # LiveCD preparation
    setLivecdConsoleFont
    setLivecdPacmanTotalDownload
    updatePackageList
    installLivecdVim

    # Prepare partitions and file systems
    partitionDisks
    createSwap
    activateSwap
    createRootFileSystem
    mountRootPartition

    # Install
    #rankMirrors        # Use only one of alternatives - rankMirrors or downloadMirrorList
    downloadMirrorList  # Use only one of alternatives - rankMirrors or downloadMirrorList
    installBaseSystem
    generateFstab
    setHostName
    setLocales
    setLanguage
    setTimeZone
    setHardwareClock
    setConsoleKeymap
    setConsoleFont
    setWiredNetwork
    installBootloader
    configureSyslinux
    setRootPassword

    log "Setup basic...done"

    # Copy config files, scripts and logs to newly installed system
    copyArchonFiles

    # Unmount partitions
    unmountRootPartition
}

setupBasic

