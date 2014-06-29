#!/bin/bash
#===============================================================================
# FILE:         functions.sh
#
# USAGE:        Include in other scripts, e.g. source functions.sh
#
# DESCRIPTION:  Functions used by setup scripts.
#               Contains only function definitions - they are not executed.
#
# CONVENTIONS:  Function should either return error code or abort the script
#               on failure.
#               Names of functions returning value start with an underscode.
#               Exception:  log function - returns result but always neglected,
#                           so without underscore for convenience
#===============================================================================

#===============================================================================
# Generic functions
#===============================================================================

# Requires:
#   LOG_DIR
createLogDir()
{
    # Check if log dir variable is set.
    # Since there is no standard logging mechanism available at that stage,
    # just check the variable and echo on screen instead of using
    # TODO: <reqVar function name> function.
    if [[ -z "$LOG_DIR" ]]; then
        echo "$FUNCNAME: variable LOG_DIR not set"
        echo "Aborting script!"
        exit 1
    fi

    # Create log directory
    mkdir -p $LOG_DIR

    # Check result
    if [[ "$?" -ne 0 ]]; then
        echo "Failed to create log dir $LOG_DIR"
        echo "Aborting script!"
        exit 2
    fi
}

# Requires:
#   LOG_FILE
#   LOG_PREFIX
log()
{
    # Check if all required variables are set
    if [[ -z "$LOG_FILE" ]]; then
        echo "$FUNCNAME: variable LOG_FILE not set"
        return 1
    fi

    if [[ -z "$LOG_PREFIX" ]]; then
        echo "$FUNCNAME: variable LOG_PREFIX not set"
        return 2
    fi

    # Use msg with prefix to distinguish logs generated by setup scripts
    local msg="$PROJECT_LOG_PREFIX$@"

    # Write message to screen and log file
    (echo "$msg" 2>&1) | tee -a $LOG_FILE
    return ${PIPESTATUS[0]}
}

# Requires:
#   LOG_FILE
#   CMD_PREFIX
_cmd()
{
    # Check if all required variables are set
    if [[ -z "$LOG_FILE" ]]; then
        echo "$FUNCNAME: variable LOG_FILE not set"
        return 1
    fi

    if [[ -z "$CMD_PREFIX" ]]; then
        echo "$FUNCNAME: variable CMD_PREFIX not set"
        return 2
    fi

    # Record command to be executed to the log file
    echo "$CMD_PREFIX$@" >> $LOG_FILE

    # Execute command
    # Redirect stdout and stderr to screen and log file
    (eval "$@" 2>&1) | tee -a $LOG_FILE
    return ${PIPESTATUS[0]}
}

# Checks whether required variable is set
# Usage: req MY_VAR $FUNCNAME
req()
{
    local var="$1"
    local function="$2"

    if [[ -z "${!var}" ]]; then
        log "$function: variable $var not defined"
        log "Aborting script!"
        exit 1
    fi
}

# Checks provided error code. Terminates script when it is nonzero.
# Usage: err $? $FUNCNAME "message to be shown and logged"
err()
{
    # Check number of required params
    if [[ $# -lt 3 ]]; then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        log "Aborting script!"
        exit 1
    fi

    local error="$1"
    local funcname="$2"
    local msg="$3"

    if [[ "$error" -ne 0 ]]; then
        log "$funcname: $msg: $error"
        log "Aborting script!"
        exit 2
    fi
}

#===============================================================================
# Helper functions
#===============================================================================

updatePackageList()
{
    log "Update package list..."

    _cmd "pacman -Syy"
    err "$?" "$FUNCNAME" "failed to update package list"

    log "Update package list...done"
}

installPackage()
{
    log "Installing package $@..."

    _cmd "pacman -S $@ --noconfirm"
    err "$?" "$FUNCNAME" "failed to install package $@"

    log "Installing package $@...done"
}

# Delay is given in seconds
delay()
{
    if [[ $# -lt 1 ]]; then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        exit 1
    fi

    local seconds="$1"

    log "Waiting $seconds""s..."
    _cmd "sleep $seconds"
    log "Waiting $seconds""s...done"
}

createPartition()
{
    req PARTITION_OPERATIONS_DELAY $FUNCNAME

    if [[ $# -lt 5 ]]; then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        log "Aborting script!"
        exit 1
    fi

    local disk="$1"         # e.g. /dev/sda
    local partType="$2"     # "p" for prtimary, "e" for extented
    local partNb="$3"       # e.g. "1" for "/dev/sda1"
    local partSize="$4"     # e.g. "+1G" for 1GiB, "" for remaining space
    local partCode="$5"     # e.g. "82" for swap, "83" for Linux, etc.
    local partCodeNb=""     # No partition nb for code setting for 1st partition

    # For first partition, provide partition number when entering
    # partition code
    if [[ $partNb -ne 1 ]]; then
        partCodeNb=$partNb
    fi

    cat <<-EOF | fdisk $disk
	n
	$partType
	$partNb
	
	$partSize
	t
	$partCodeNb
	$partCode
	w
	EOF

    delay $PARTITION_OPERATIONS_DELAY
}

# Best executed when all (at least two) partitions are created
setPartitionBootable()
{
    req PARTITION_OPERATIONS_DELAY $FUNCNAME

    if [[ $# -lt 2 ]]; then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        log "Aborting script!"
        exit 1
    fi

    local disk="$1"     # e.g. /dev/sda
    local partNb="$2"   # e.g. "1" for "/dev/sda1"

    cat <<-EOF | fdisk $disk
	a
	$partNb
	w
	EOF

    delay $PARTITION_OPERATIONS_DELAY
}

#===============================================================================
# Setup functions
#===============================================================================

#=======================================
# LiveCD preparation
#=======================================

setConsoleFontTemporarily()
{
    req CONSOLE_FONT $FUNCNAME

    # Font setting is not crucial, so don't abort the script when it fails
    setfont $CONSOLE_FONT
}


installArchlinuxKeyring()
{
    req ARCHLINUX_KEYRING_PACKAGES $FUNCNAME

    log "Install archlinux keyring..."

    installPackage $ARCHLINUX_KEYRING_PACKAGES

    log "Install archlinux keyring...done"
}

installLivecdVim()
{
    req VIM_PACKAGES $FUNCNAME

    log "Install livecd vim..."

    installPackage $VIM_PACKAGES

    log "Install livecd vim...done"
}

#=======================================
# Partitions and file systems
#=======================================

createSwapPartition()
{
    req PARTITION_PREFIX $FUNCNAME
    req SWAP_PARTITION_HDD $FUNCNAME
    req SWAP_PARTITION_TYPE $FUNCNAME
    req SWAP_PARTITION_NB $FUNCNAME
    req SWAP_PARTITION_SIZE $FUNCNAME
    req SWAP_PARTITION_CODE $FUNCNAME

    log "Create swap partition..."

    createPartition\
        "$PARTITION_PREFIX$SWAP_PARTITION_HDD"\
        "$SWAP_PARTITION_TYPE"\
        "$SWAP_PARTITION_NB"\
        "$SWAP_PARTITION_SIZE"\
        "$SWAP_PARTITION_CODE"

    log "Create swap partition...done"
}

createBootPartition()
{
    req PARTITION_PREFIX $FUNCNAME
    req BOOT_PARTITION_HDD $FUNCNAME
    req BOOT_PARTITION_TYPE $FUNCNAME
    req BOOT_PARTITION_NB $FUNCNAME
    req BOOT_PARTITION_SIZE $FUNCNAME
    req BOOT_PARTITION_CODE $FUNCNAME

    log "Create boot partition..."

    createPartition\
        "$PARTITION_PREFIX$BOOT_PARTITION_HDD"\
        "$BOOT_PARTITION_TYPE"\
        "$BOOT_PARTITION_NB"\
        "$BOOT_PARTITION_SIZE"\
        "$BOOT_PARTITION_CODE"

    log "Create boot partition...done"
}

createRootPartition()
{
    req PARTITION_PREFIX $FUNCNAME
    req ROOT_PARTITION_HDD $FUNCNAME
    req ROOT_PARTITION_TYPE $FUNCNAME
    req ROOT_PARTITION_NB $FUNCNAME
    #req ROOT_PARTITION_SIZE $FUNCNAME # Use remaining space
    req ROOT_PARTITION_CODE $FUNCNAME

    log "Create root partition..."

    createPartition\
        "$PARTITION_PREFIX$ROOT_PARTITION_HDD"\
        "$ROOT_PARTITION_TYPE"\
        "$ROOT_PARTITION_NB"\
        "$ROOT_PARTITION_SIZE"\
        "$ROOT_PARTITION_CODE"

    log "Create root partition...done"
}

setBootPartitionBootable()
{
    req PARTITION_PREFIX $FUNCNAME
    req BOOT_PARTITION_HDD $FUNCNAME
    req BOOT_PARTITION_NB $FUNCNAME

    log "Set boot partition bootable..."

    setPartitionBootable\
        "$PARTITION_PREFIX$BOOT_PARTITION_HDD"\
        "$BOOT_PARTITION_NB"

    log "Set boot partition bootable...done"
}

createSwap()
{
    req PARTITION_PREFIX $FUNCNAME
    req SWAP_PARTITION_HDD $FUNCNAME
    req SWAP_PARTITION_NB $FUNCNAME

    log "Create swap..."

    _cmd "mkswap $PARTITION_PREFIX$SWAP_PARTITION_HDD$SWAP_PARTITION_NB"
    err "$?" "$FUNCNAME" "failed to create swap"

    log "Create swap...done"
}

activateSwap()
{
    req PARTITION_PREFIX $FUNCNAME
    req SWAP_PARTITION_HDD $FUNCNAME
    req SWAP_PARTITION_NB $FUNCNAME

    log "Activate swap..."

    _cmd "swapon $PARTITION_PREFIX$SWAP_PARTITION_HDD$SWAP_PARTITION_NB"
    err "$?" "$FUNCNAME" "failed to activate swap"

    log "Activate swap...done"
}

createBootFileSystem()
{
    req BOOT_PARTITION_FS $FUNCNAME
    req BOOT_PARTITION_HDD $FUNCNAME
    req BOOT_PARTITION_NB $FUNCNAME

    log "Create boot file system..."

    _cmd "mkfs.$BOOT_PARTITION_FS"\
        "$PARTITION_PREFIX$BOOT_PARTITION_HDD$BOOT_PARTITION_NB"
    err "$?" "$FUNCNAME" "failed to create boot file system"

    log "Create boot file system...done"
}

createRootFileSystem()
{
    req ROOT_PARTITION_FS $FUNCNAME
    req PARTITION_PREFIX $FUNCNAME
    req ROOT_PARTITION_HDD $FUNCNAME
    req ROOT_PARTITION_NB $FUNCNAME

    log "Create root file system..."

    _cmd "mkfs.$ROOT_PARTITION_FS"\
        " $PARTITION_PREFIX$ROOT_PARTITION_HDD$ROOT_PARTITION_NB"
    err "$?" "$FUNCNAME" "failed to create root file system"

    log "Create root file system...done"
}

mountRootPartition()
{
    req PARTITION_PREFIX $FUNCNAME
    req ROOT_PARTITION_HDD $FUNCNAME
    req ROOT_PARTITION_NB $FUNCNAME
    req ROOT_PARTITION_MOUNT_POINT $FUNCNAME

    log "Mount root partition..."

    _cmd "mount $PARTITION_PREFIX$ROOT_PARTITION_HDD$ROOT_PARTITION_NB"\
        " $ROOT_PARTITION_MOUNT_POINT"
    err "$?" "$FUNCNAME" "failed to mount root partition"

    log "Mount root partition...done"
}

mountBootPartition()
{
    req PARTITION_PREFIX $FUNCNAME
    req BOOT_PARTITION_HDD $FUNCNAME
    req BOOT_PARTITION_NB $FUNCNAME
    req BOOT_PARTITION_MOUNT_POINT $FUNCNAME

    log "Mount boot partition..."

    _cmd "mkdir $BOOT_PARTITION_MOUNT_POINT"
    err "$?" "$FUNCNAME" "failed to create boot partition mount point"

    _cmd "mount $PARTITION_PREFIX$BOOT_PARTITION_HDD$BOOT_PARTITION_NB"\
        " $BOOT_PARTITION_MOUNT_POINT"
    err "$?" "$FUNCNAME" "failed to mount boot partition"

    log "Mount boot partition...done"
}

unmountPartitions()
{
    req LIVECD_MOUNT_POINT $FUNCNAME

    log "Unmount partitions..."

    _cmd "umount -R $LIVECD_MOUNT_POINT"
    err "$?" "$FUNCNAME" "failed to unmount partitions"

    log "Unmount partitions...done"
}

