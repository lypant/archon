#!/bin/bash

echo disks.sh

# TODO: Try to separate fdisk commands for each partition, as they may occupy different disks
partitionDisks()
{
    requiresVariable "PARTITION_PREFIX" "$FUNCNAME"
    requiresVariable "SYSTEM_HDD" "$FUNCNAME"
    requiresVariable "SWAP_PARTITION_SIZE" "$FUNCNAME"
    requiresVariable "ROOT_PARTITION_SIZE" "$FUNCNAME"

    log "Partition disks..."

cat << EOF | fdisk $PARTITION_PREFIX$SYSTEM_HDD
n
p
1

$SWAP_PARTITION_SIZE
t
82
n
p
2

$ROOT_PARTITION_SIZE
t
2
83
a
2
w
EOF

    log "Partition disks...done"
}

createSwap()
{
    requiresVariable "PARTITION_PREFIX" "$FUNCNAME"
    requiresVariable "SWAP_PARTITION_HDD" "$FUNCNAME"
    requiresVariable "SWAP_PARTITION_NB" "$FUNCNAME"

    log "Create swap..."

    executeCommand "mkswap $PARTITION_PREFIX$SWAP_PARTITION_HDD$SWAP_PARTITION_NB"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to create swap"

    log "Create swap...done"
}

activateSwap()
{
    requiresVariable "PARTITION_PREFIX" "$FUNCNAME"
    requiresVariable "SWAP_PARTITION_HDD" "$FUNCNAME"
    requiresVariable "SWAP_PARTITION_NB" "$FUNCNAME"

    log "Activate swap..."

    executeCommand "swapon $PARTITION_PREFIX$SWAP_PARTITION_HDD$SWAP_PARTITION_NB"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to activate swap"

    log "Activate swap...done"
}

createRootFileSystem()
{
    requiresVariable "ROOT_PARTITION_FS" "$FUNCNAME"
    requiresVariable "PARTITION_PREFIX" "$FUNCNAME"
    requiresVariable "ROOT_PARTITION_HDD" "$FUNCNAME"
    requiresVariable "ROOT_PARTITION_NB" "$FUNCNAME"

    log "Create root file system..."

    executeCommand "mkfs.$ROOT_PARTITION_FS $PARTITION_PREFIX$ROOT_PARTITION_HDD$ROOT_PARTITION_NB"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to create root file system"

    log "Create root file system...done"
}

mountRootPartition()
{
    requiresVariable "PARTITION_PREFIX" "$FUNCNAME"
    requiresVariable "ROOT_PARTITION_HDD" "$FUNCNAME"
    requiresVariable "ROOT_PARTITION_NB" "$FUNCNAME"
    requiresVariable "ROOT_PARTITION_MOUNT_POINT" "$FUNCNAME"

    log "Mount root partition..."

    executeCommand "mount $PARTITION_PREFIX$ROOT_PARTITION_HDD$ROOT_PARTITION_NB $ROOT_PARTITION_MOUNT_POINT"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to mount root partition"

    log "Mount root partition...done"
}

unmountRootPartition()
{
    requiresVariable "ROOT_PARTITION_MOUNT_POINT" "$FUNCNAME"

    log "Unmount root partition..."

    executeCommand "umount $ROOT_PARTITION_MOUNT_POINT"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to unmount root partition"

    log "Unmount root partition...done"
}

