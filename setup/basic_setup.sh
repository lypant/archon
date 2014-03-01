#!/bin/bash
#===============================================================================
# FILE:         basic_setup.sh
#
# USAGE:        Execute from shell, e.g. ./basic_setup.sh
#
# DESCRIPTION:  Functions used to perform basic system setup.
#               Executes main setup function.
#===============================================================================

#===============================================================================
# Other scripts usage
#===============================================================================

source "settings.conf"
source "functions.sh"

#===============================================================================
# Log file for this script
#===============================================================================

LOG_FILE="$PROJECT_SETUP_BASIC_LOG_FILE"

#===============================================================================
# Helper functions
#===============================================================================

createPartition()
{
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
}

# Best executed when all (at least two) partitions are created
setPartitionBootable()
{
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
}

downloadFile()
{
    if [[ $# -lt 2 ]]; then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        return 1
    fi

    local src=$1
    local dst=$2

    executeCommand "curl -so $dst --create-dirs $src"
    return $?
}

archChroot()
{
    requiresVariable "ROOT_PARTITION_MOUNT_POINT" "$FUNCNAME"

    if [[ $# -lt 1 ]];then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        return 1
    fi

    executeCommand arch-chroot $ROOT_PARTITION_MOUNT_POINT /bin/bash -c \""$@"\"
    return $?
}

setLocale()
{
    if [[ $# -lt 1 ]]; then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        terminateScriptOnError "1" "$FUNCNAME" "failed to set locale"
    fi

    log "Set locale for  $1..."

    #archChroot "sed -i \\\"s|^#\\\\\(${1}.*\\\\\)$|\\\\\1|\\\" /etc/locale.gen"

    local subst="s|^#\\\\\(${1}.*\\\\\)$|\1|"
    local file="/etc/locale.gen"
    archChroot "sed -i \\\"$subst\\\" $file"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to set locale"

    log "Set locale for $1...done"
}

#===============================================================================
# Setup functions
#===============================================================================

#=======================================
# LiveCD preparation
#=======================================

setLivecdConsoleFont()
{
    requiresVariable "CONSOLE_FONT" "$FUNCNAME"

    log "Set livecd console font..."

    executeCommand "setfont $CONSOLE_FONT"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to set livecd console font"

    log "Set livecd console font...done"
}

setLivecdPacmanTotalDownload()
{
    log "Set livecd pacman total download..."

    uncommentVar "TotalDownload" "/etc/pacman.conf"
    terminateScriptOnError\
        "$?" "$FUNCNAME" "failed to set livecd pacman total download"

    log "Set livecd pacman total download...done"
}

installLivecdVim()
{
    log "Install livecd vim..."

    installPackage "vim"

    log "Install livecd vim...done"
}

#=======================================
# Partitions and file systems
#=======================================

createSwapPartition()
{
    requiresVariable "PARTITION_PREFIX" "$FUNCNAME"
    requiresVariable "SWAP_PARTITION_HDD" "$FUNCNAME"
    requiresVariable "SWAP_PARTITION_TYPE" "$FUNCNAME"
    requiresVariable "SWAP_PARTITION_NB" "$FUNCNAME"
    requiresVariable "SWAP_PARTITION_SIZE" "$FUNCNAME"
    requiresVariable "SWAP_PARTITION_CODE" "$FUNCNAME"

    log "Create swap partition..."

    createPartition\
        "$PARTITION_PREFIX$SWAP_PARTITION_HDD"\
        "$SWAP_PARTITION_TYPE"\
        "$SWAP_PARTITION_NB"\
        "$SWAP_PARTITION_SIZE"\
        "$SWAP_PARTITION_CODE"
    terminateScriptOnError\
        "$?" "$FUNCNAME" "failed to create swap partition"

    log "Create swap partition...done"
}

createBootPartition()
{
    requiresVariable "PARTITION_PREFIX" "$FUNCNAME"
    requiresVariable "BOOT_PARTITION_HDD" "$FUNCNAME"
    requiresVariable "BOOT_PARTITION_TYPE" "$FUNCNAME"
    requiresVariable "BOOT_PARTITION_NB" "$FUNCNAME"
    requiresVariable "BOOT_PARTITION_SIZE" "$FUNCNAME"
    requiresVariable "BOOT_PARTITION_CODE" "$FUNCNAME"

    log "Create boot partition..."

    createPartition\
        "$PARTITION_PREFIX$BOOT_PARTITION_HDD"\
        "$BOOT_PARTITION_TYPE"\
        "$BOOT_PARTITION_NB"\
        "$BOOT_PARTITION_SIZE"\
        "$BOOT_PARTITION_CODE"
    terminateScriptOnError\
        "$?" "$FUNCNAME" "failed to create boot partition"

    log "Create boot partition...done"
}

createRootPartition()
{
    requiresVariable "PARTITION_PREFIX" "$FUNCNAME"
    requiresVariable "ROOT_PARTITION_HDD" "$FUNCNAME"
    requiresVariable "ROOT_PARTITION_TYPE" "$FUNCNAME"
    requiresVariable "ROOT_PARTITION_NB" "$FUNCNAME"
    #requiresVariable "ROOT_PARTITION_SIZE" "$FUNCNAME" # Use remaining space
    requiresVariable "ROOT_PARTITION_CODE" "$FUNCNAME"

    log "Create root partition..."

    createPartition\
        "$PARTITION_PREFIX$ROOT_PARTITION_HDD"\
        "$ROOT_PARTITION_TYPE"\
        "$ROOT_PARTITION_NB"\
        "$ROOT_PARTITION_SIZE"\
        "$ROOT_PARTITION_CODE"
    terminateScriptOnError\
        "$?" "$FUNCNAME" "failed to create root partition"

    log "Create root partition...done"
}

setBootPartitionBootable()
{
    requiresVariable "PARTITION_PREFIX" "$FUNCNAME"
    requiresVariable "BOOT_PARTITION_HDD" "$FUNCNAME"
    requiresVariable "BOOT_PARTITION_NB" "$FUNCNAME"

    log "Set boot partition bootable..."

    setPartitionBootable\
        "$PARTITION_PREFIX$BOOT_PARTITION_HDD"\
        "$BOOT_PARTITION_NB"

    terminateScriptOnError\
        "$?" "$FUNCNAME" "failed to set boot partition bootable"

    log "Set boot partition bootable...done"
}

createSwap()
{
    requiresVariable "PARTITION_PREFIX" "$FUNCNAME"
    requiresVariable "SWAP_PARTITION_HDD" "$FUNCNAME"
    requiresVariable "SWAP_PARTITION_NB" "$FUNCNAME"

    log "Create swap..."

    executeCommand\
        "mkswap $PARTITION_PREFIX$SWAP_PARTITION_HDD$SWAP_PARTITION_NB"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to create swap"

    log "Create swap...done"
}

activateSwap()
{
    requiresVariable "PARTITION_PREFIX" "$FUNCNAME"
    requiresVariable "SWAP_PARTITION_HDD" "$FUNCNAME"
    requiresVariable "SWAP_PARTITION_NB" "$FUNCNAME"

    log "Activate swap..."

    executeCommand\
        "swapon $PARTITION_PREFIX$SWAP_PARTITION_HDD$SWAP_PARTITION_NB"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to activate swap"

    log "Activate swap...done"
}

createBootFileSystem()
{
    requiresVariable "BOOT_PARTITION_FS" "$FUNCNAME"
    requiresVariable "BOOT_PARTITION_HDD" "$FUNCNAME"
    requiresVariable "BOOT_PARTITION_NB" "$FUNCNAME"

    log "Create boot file system..."

    executeCommand\
        "mkfs.$BOOT_PARTITION_FS"\
        "$PARTITION_PREFIX$BOOT_PARTITION_HDD$BOOT_PARTITION_NB"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to create boot file system"

    log "Create boot file system...done"
}

createRootFileSystem()
{
    requiresVariable "ROOT_PARTITION_FS" "$FUNCNAME"
    requiresVariable "PARTITION_PREFIX" "$FUNCNAME"
    requiresVariable "ROOT_PARTITION_HDD" "$FUNCNAME"
    requiresVariable "ROOT_PARTITION_NB" "$FUNCNAME"

    log "Create root file system..."

    executeCommand\
        "mkfs.$ROOT_PARTITION_FS"\
        " $PARTITION_PREFIX$ROOT_PARTITION_HDD$ROOT_PARTITION_NB"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to create root file system"

    log "Create root file system...done"
}

mountBootPartition()
{
    requiresVariable "PARTITION_PREFIX" "$FUNCNAME"
    requiresVariable "BOOT_PARTITION_HDD" "$FUNCNAME"
    requiresVariable "BOOT_PARTITION_NB" "$FUNCNAME"
    requiresVariable "BOOT_PARTITION_MOUNT_POINT" "$FUNCNAME"

    log "Mount boot partition..."

    executeCommand "mkdir $BOOT_PARTITION_MOUNT_POINT"
    terminateScriptOnError\
        "$?" "$FUNCNAME" "failed to create boot partition mount point"

    executeCommand\
        "mount $PARTITION_PREFIX$BOOT_PARTITION_HDD$BOOT_PARTITION_NB"\
        " $BOOT_PARTITION_MOUNT_POINT"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to mount boot partition"

    log "Mount boot partition...done"
}

mountRootPartition()
{
    requiresVariable "PARTITION_PREFIX" "$FUNCNAME"
    requiresVariable "ROOT_PARTITION_HDD" "$FUNCNAME"
    requiresVariable "ROOT_PARTITION_NB" "$FUNCNAME"
    requiresVariable "ROOT_PARTITION_MOUNT_POINT" "$FUNCNAME"

    log "Mount root partition..."

    executeCommand\
        "mount $PARTITION_PREFIX$ROOT_PARTITION_HDD$ROOT_PARTITION_NB"\
        " $ROOT_PARTITION_MOUNT_POINT"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to mount root partition"

    log "Mount root partition...done"
}

#unmountRootPartition()
#{
#    requiresVariable "ROOT_PARTITION_MOUNT_POINT" "$FUNCNAME"
#
#    log "Unmount root partition..."
#
#    executeCommand "umount $ROOT_PARTITION_MOUNT_POINT"
#    terminateScriptOnError "$?" "$FUNCNAME" "failed to unmount root partition"
#
#    log "Unmount root partition...done"
#}

unmountPartitions()
{
    requiresVariable "LIVECD_MOUNT_POINT" "$FUNCNAME"

    log "Unmount partitions..."

    executeCommand "umount -R $LIVECD_MOUNT_POINT"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to unmount partitions"

    log "Unmount partitions...done"
}

#=======================================
# Installation
#=======================================

# Note: rankMirrors takes longer time but
# might provide faster servers than downloadMirrorList
rankMirrors()
{
    requiresVariable "MIRROR_LIST_FILE" "$FUNCNAME"
    requiresVariable "MIRROR_LIST_FILE_BACKUP" "$FUNCNAME"
    requiresVariable "MIRROR_COUNT" "$FUNCNAME"

    log "Rank mirrors..."

    # Backup original file
    executeCommand "cp $MIRROR_LIST_FILE $MIRROR_LIST_FILE_BACKUP"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to rank mirrors"

    executeCommand\
        "rankmirrors -n $MIRROR_COUNT $MIRROR_LIST_FILE_BACKUP >"\
        "$MIRROR_LIST_FILE"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to rank mirrors"

    log "Rank mirrors...done"
}

# Note: downloadMirrorList is faster than rankMirrors but
# might give slower servers
downloadMirrorList()
{
    requiresVariable "MIRROR_LIST_FILE" "$FUNCNAME"
    requiresVariable "MIRROR_LIST_FILE_BACKUP" "$FUNCNAME"
    requiresVariable "MIRROR_LIST_URL" "$FUNCNAME"

    log "Download mirror list..."

    # Backup original file
    executeCommand "cp $MIRROR_LIST_FILE $MIRROR_LIST_FILE_BACKUP"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to download mirror list"

    downloadFile $MIRROR_LIST_URL $MIRROR_LIST_FILE
    terminateScriptOnError "$?" "$FUNCNAME" "failed to download mirror list"

    uncommentVar "Server" $MIRROR_LIST_FILE
    terminateScriptOnError "$?" "$FUNCNAME" "failed to download mirror list"

    log "Download mirror list...done"
}

installBaseSystem()
{
    requiresVariable "ROOT_PARTITION_MOUNT_POINT" "$FUNCNAME"
    requiresVariable "BASE_SYSTEM_PACKAGES" "$FUNCNAME"

    log "Install base system..."

    executeCommand\
        "pacstrap -i $ROOT_PARTITION_MOUNT_POINT $BASE_SYSTEM_PACKAGES"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install base system"

    log "Install base system...done"
}

generateFstab()
{
    requiresVariable "ROOT_PARTITION_MOUNT_POINT" "$FUNCNAME"

    log "Generate fstab..."

    executeCommand\
        "genfstab -L -p $ROOT_PARTITION_MOUNT_POINT >>"\
        " $ROOT_PARTITION_MOUNT_POINT/etc/fstab"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to generate fstab"

    log "Generate fstab...done"
}

setHostName()
{
    requiresVariable "HOST_NAME" "$FUNCNAME"

    log "Set host name..."

    archChroot "echo $HOST_NAME > /etc/hostname"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to set host name"

    log "Set host name...done"
}

setLocales()
{
    requiresVariable "LOCALIZATION_LANGUAGE_EN" "$FUNCNAME"
    requiresVariable "LOCALIZATION_LANGUAGE_PL" "$FUNCNAME"

    log "Set locales..."

    setLocale "$LOCALIZATION_LANGUAGE_EN"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to set locale"

    setLocale "$LOCALIZATION_LANGUAGE_PL"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to set locale"

    log "Set locales...done"
}

generateLocales()
{
    log "Generate locales..."

    archChroot "locale-gen"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to generate locales"

    log "Generate locales...done"
}

setLanguage()
{
    requiresVariable "LOCALIZATION_LANGUAGE_EN" "$FUNCNAME"

    log "Set language..."

    archChroot "echo LANG=$LOCALIZATION_LANGUAGE_EN > /etc/locale.conf"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to set language"

    log "Set language...done"
}

setTimeZone()
{
    requiresVariable "LOCALIZATION_TIME_ZONE" "$FUNCNAME"

    log "Set time zone..."

    archChroot\
        "ln -s /usr/share/zoneinfo/$LOCALIZATION_TIME_ZONE /etc/localtime"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to set time zone"

    log "Set time zone...done"
}

setHardwareClock()
{
    requiresVariable "LOCALIZATION_HW_CLOCK" "$FUNCNAME"

    log "Set hardware clock..."

    archChroot "hwclock $LOCALIZATION_HW_CLOCK"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to set hardware clock"

    log "Set hardware clock...done"
}

setConsoleKeymap()
{
    requiresVariable "CONSOLE_KEYMAP" "$FUNCNAME"

    log "Set console keymap..."

    archChroot "echo KEYMAP=$CONSOLE_KEYMAP > /etc/vconsole.conf"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to set console keymap"

    log "Set console keymap...done"
}

setConsoleFont()
{
    requiresVariable "CONSOLE_FONT" "$FUNCNAME"

    log "Set console font..."

    archChroot "echo FONT=$CONSOLE_FONT >> /etc/vconsole.conf"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to set console font"

    log "Set console font...done"
}

setWiredNetwork()
{
    requiresVariable "NETWORK_SERVICE" "$FUNCNAME"
    requiresVariable "NETWORK_INTERFACE_WIRED" "$FUNCNAME"

    log "Set wired network..."

    archChroot\
        "systemctl enable $NETWORK_SERVICE@$NETWORK_INTERFACE_WIRED.service"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to set wired network"

    log "Set wired network...done"
}

installBootloader()
{
    requiresVariable "BOOTLOADER_PACKAGE" "$FUNCNAME"

    log "Install bootloader..."

    archChroot "pacman -S $BOOTLOADER_PACKAGE --noconfirm"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install bootloader"

    log "Install bootloader...done"
}

configureSyslinux()
{
    requiresVariable "ROOT_PARTITION_HDD" "$FUNCNAME"
    requiresVariable "ROOT_PARTITION_NB" "$FUNCNAME"

    log "Configure syslinux..."

    archChroot "syslinux-install_update -i -a -m"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to update syslinux"

    local src="sda3"
    local dst="$ROOT_PARTITION_HDD$ROOT_PARTITION_NB"
    local subst="s|$src|$dst|g"
    local file="/boot/syslinux/syslinux.cfg"
    archChroot "sed -i \\\"$subst\\\" $file"
    terminateScriptOnError\
        "$?" "$FUNCNAME" "failed to change partition name in syslinux"

    log "Configure syslinux...done"
}

setRootPassword()
{
    log "Set root password..."

    local ASK=1

    while [ $ASK -ne 0 ]; do
        archChroot "passwd"
        ASK=$?
    done

    log "Set root password...done"
}

#=======================================
# Post installation actions
#=======================================

copyProjectFiles()
{
    requiresVariable "PROJECT_MNT_PATH" "$FUNCNAME"
    requiresVariable "PROJECT_ROOT_PATH" "$FUNCNAME"

    # Do not perform typical logging in this function...
    # This would spoil nice logs copied to new system

    mkdir -p $PROJECT_MNT_PATH
    terminateScriptOnError "$?" "$FUNCNAME" "failed to copy $PROJECT_NAME files"

    cp -R $PROJECT_ROOT_PATH/* $PROJECT_MNT_PATH
    terminateScriptOnError "$?" "$FUNCNAME" "failed to copy $PROJECT_NAME files"

    # This is only for livecd output and logs consistency
    log "Copy $PROJECT_NAME files..."
    log "Copy $PROJECT_NAME files...done"
}

#===============================================================================
# Main setup function
#===============================================================================

setupBasic()
{
    createLogDir

    log "Setup basic..."

    #=======================================
    # LiveCD preparation
    #=======================================

    setLivecdConsoleFont
    setLivecdPacmanTotalDownload
    updatePackageList
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
    installBaseSystem
    generateFstab
    setHostName
    setLocales
    generateLocales
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

    #=======================================
    # Post installation actions
    #=======================================

    copyProjectFiles
    #unmountRootPartition
    unmountPartitions
}

#===============================================================================
# Main setup function execution
#===============================================================================

setupBasic

