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

# Include necessary files from specific machine folder

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

    cmd "curl -so $dst --create-dirs $src"
    return $?
}

archChroot()
{
    reqVar "ROOT_PARTITION_MOUNT_POINT" "$FUNCNAME"

    if [[ $# -lt 1 ]];then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        return 1
    fi

    cmd arch-chroot $ROOT_PARTITION_MOUNT_POINT /bin/bash -c \""$@"\"
    return $?
}

setLocale()
{
    if [[ $# -lt 1 ]]; then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        err "1" "$FUNCNAME" "failed to set locale"
    fi

    log "Set locale for  $1..."

    #archChroot "sed -i \\\"s|^#\\\\\(${1}.*\\\\\)$|\\\\\1|\\\" /etc/locale.gen"

    local subst="s|^#\\\\\(${1}.*\\\\\)$|\1|"
    local file="/etc/locale.gen"
    archChroot "sed -i \\\"$subst\\\" $file"
    err "$?" "$FUNCNAME" "failed to set locale"

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
    reqVar "CONSOLE_FONT" "$FUNCNAME"

    log "Set livecd console font..."

    cmd "setfont $CONSOLE_FONT"
    err "$?" "$FUNCNAME" "failed to set livecd console font"

    log "Set livecd console font...done"
}

setLivecdPacmanTotalDownload()
{
    log "Set livecd pacman total download..."

    uncommentVar "TotalDownload" "/etc/pacman.conf"
    err "$?" "$FUNCNAME" "failed to set livecd pacman total download"

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
    reqVar "PARTITION_PREFIX" "$FUNCNAME"
    reqVar "SWAP_PARTITION_HDD" "$FUNCNAME"
    reqVar "SWAP_PARTITION_TYPE" "$FUNCNAME"
    reqVar "SWAP_PARTITION_NB" "$FUNCNAME"
    reqVar "SWAP_PARTITION_SIZE" "$FUNCNAME"
    reqVar "SWAP_PARTITION_CODE" "$FUNCNAME"

    log "Create swap partition..."

    createPartition\
        "$PARTITION_PREFIX$SWAP_PARTITION_HDD"\
        "$SWAP_PARTITION_TYPE"\
        "$SWAP_PARTITION_NB"\
        "$SWAP_PARTITION_SIZE"\
        "$SWAP_PARTITION_CODE"
    err "$?" "$FUNCNAME" "failed to create swap partition"

    log "Create swap partition...done"
}

createBootPartition()
{
    reqVar "PARTITION_PREFIX" "$FUNCNAME"
    reqVar "BOOT_PARTITION_HDD" "$FUNCNAME"
    reqVar "BOOT_PARTITION_TYPE" "$FUNCNAME"
    reqVar "BOOT_PARTITION_NB" "$FUNCNAME"
    reqVar "BOOT_PARTITION_SIZE" "$FUNCNAME"
    reqVar "BOOT_PARTITION_CODE" "$FUNCNAME"

    log "Create boot partition..."

    createPartition\
        "$PARTITION_PREFIX$BOOT_PARTITION_HDD"\
        "$BOOT_PARTITION_TYPE"\
        "$BOOT_PARTITION_NB"\
        "$BOOT_PARTITION_SIZE"\
        "$BOOT_PARTITION_CODE"
    err "$?" "$FUNCNAME" "failed to create boot partition"

    log "Create boot partition...done"
}

createRootPartition()
{
    reqVar "PARTITION_PREFIX" "$FUNCNAME"
    reqVar "ROOT_PARTITION_HDD" "$FUNCNAME"
    reqVar "ROOT_PARTITION_TYPE" "$FUNCNAME"
    reqVar "ROOT_PARTITION_NB" "$FUNCNAME"
    #reqVar "ROOT_PARTITION_SIZE" "$FUNCNAME" # Use remaining space
    reqVar "ROOT_PARTITION_CODE" "$FUNCNAME"

    log "Create root partition..."

    createPartition\
        "$PARTITION_PREFIX$ROOT_PARTITION_HDD"\
        "$ROOT_PARTITION_TYPE"\
        "$ROOT_PARTITION_NB"\
        "$ROOT_PARTITION_SIZE"\
        "$ROOT_PARTITION_CODE"
    err "$?" "$FUNCNAME" "failed to create root partition"

    log "Create root partition...done"
}

setBootPartitionBootable()
{
    reqVar "PARTITION_PREFIX" "$FUNCNAME"
    reqVar "BOOT_PARTITION_HDD" "$FUNCNAME"
    reqVar "BOOT_PARTITION_NB" "$FUNCNAME"

    log "Set boot partition bootable..."

    setPartitionBootable\
        "$PARTITION_PREFIX$BOOT_PARTITION_HDD"\
        "$BOOT_PARTITION_NB"

    err "$?" "$FUNCNAME" "failed to set boot partition bootable"

    log "Set boot partition bootable...done"
}

createSwap()
{
    reqVar "PARTITION_PREFIX" "$FUNCNAME"
    reqVar "SWAP_PARTITION_HDD" "$FUNCNAME"
    reqVar "SWAP_PARTITION_NB" "$FUNCNAME"

    log "Create swap..."

    cmd "mkswap $PARTITION_PREFIX$SWAP_PARTITION_HDD$SWAP_PARTITION_NB"
    err "$?" "$FUNCNAME" "failed to create swap"

    log "Create swap...done"
}

activateSwap()
{
    reqVar "PARTITION_PREFIX" "$FUNCNAME"
    reqVar "SWAP_PARTITION_HDD" "$FUNCNAME"
    reqVar "SWAP_PARTITION_NB" "$FUNCNAME"

    log "Activate swap..."

    cmd "swapon $PARTITION_PREFIX$SWAP_PARTITION_HDD$SWAP_PARTITION_NB"
    err "$?" "$FUNCNAME" "failed to activate swap"

    log "Activate swap...done"
}

createBootFileSystem()
{
    reqVar "BOOT_PARTITION_FS" "$FUNCNAME"
    reqVar "BOOT_PARTITION_HDD" "$FUNCNAME"
    reqVar "BOOT_PARTITION_NB" "$FUNCNAME"

    log "Create boot file system..."

    cmd "mkfs.$BOOT_PARTITION_FS"\
        "$PARTITION_PREFIX$BOOT_PARTITION_HDD$BOOT_PARTITION_NB"
    err "$?" "$FUNCNAME" "failed to create boot file system"

    log "Create boot file system...done"
}

createRootFileSystem()
{
    reqVar "ROOT_PARTITION_FS" "$FUNCNAME"
    reqVar "PARTITION_PREFIX" "$FUNCNAME"
    reqVar "ROOT_PARTITION_HDD" "$FUNCNAME"
    reqVar "ROOT_PARTITION_NB" "$FUNCNAME"

    log "Create root file system..."

    cmd "mkfs.$ROOT_PARTITION_FS"\
        " $PARTITION_PREFIX$ROOT_PARTITION_HDD$ROOT_PARTITION_NB"
    err "$?" "$FUNCNAME" "failed to create root file system"

    log "Create root file system...done"
}

mountBootPartition()
{
    reqVar "PARTITION_PREFIX" "$FUNCNAME"
    reqVar "BOOT_PARTITION_HDD" "$FUNCNAME"
    reqVar "BOOT_PARTITION_NB" "$FUNCNAME"
    reqVar "BOOT_PARTITION_MOUNT_POINT" "$FUNCNAME"

    log "Mount boot partition..."

    cmd "mkdir $BOOT_PARTITION_MOUNT_POINT"
    err "$?" "$FUNCNAME" "failed to create boot partition mount point"

    cmd "mount $PARTITION_PREFIX$BOOT_PARTITION_HDD$BOOT_PARTITION_NB"\
        " $BOOT_PARTITION_MOUNT_POINT"
    err "$?" "$FUNCNAME" "failed to mount boot partition"

    log "Mount boot partition...done"
}

mountRootPartition()
{
    reqVar "PARTITION_PREFIX" "$FUNCNAME"
    reqVar "ROOT_PARTITION_HDD" "$FUNCNAME"
    reqVar "ROOT_PARTITION_NB" "$FUNCNAME"
    reqVar "ROOT_PARTITION_MOUNT_POINT" "$FUNCNAME"

    log "Mount root partition..."

    cmd "mount $PARTITION_PREFIX$ROOT_PARTITION_HDD$ROOT_PARTITION_NB"\
        " $ROOT_PARTITION_MOUNT_POINT"
    err "$?" "$FUNCNAME" "failed to mount root partition"

    log "Mount root partition...done"
}

unmountPartitions()
{
    reqVar "LIVECD_MOUNT_POINT" "$FUNCNAME"

    log "Unmount partitions..."

    cmd "umount -R $LIVECD_MOUNT_POINT"
    err "$?" "$FUNCNAME" "failed to unmount partitions"

    log "Unmount partitions...done"
}

#=======================================
# Installation
#=======================================

# Note: rankMirrors takes longer time but
# might provide faster servers than downloadMirrorList
rankMirrors()
{
    reqVar "MIRROR_LIST_FILE" "$FUNCNAME"
    reqVar "MIRROR_LIST_FILE_BACKUP" "$FUNCNAME"
    reqVar "MIRROR_COUNT" "$FUNCNAME"

    log "Rank mirrors..."

    # Backup original file
    cmd "cp $MIRROR_LIST_FILE $MIRROR_LIST_FILE_BACKUP"
    err "$?" "$FUNCNAME" "failed to rank mirrors"

    cmd "rankmirrors -n $MIRROR_COUNT $MIRROR_LIST_FILE_BACKUP >"\
        "$MIRROR_LIST_FILE"
    err "$?" "$FUNCNAME" "failed to rank mirrors"

    log "Rank mirrors...done"
}

# Note: downloadMirrorList is faster than rankMirrors but
# might give slower servers
downloadMirrorList()
{
    reqVar "MIRROR_LIST_FILE" "$FUNCNAME"
    reqVar "MIRROR_LIST_FILE_BACKUP" "$FUNCNAME"
    reqVar "MIRROR_LIST_URL" "$FUNCNAME"

    log "Download mirror list..."

    # Backup original file
    cmd "cp $MIRROR_LIST_FILE $MIRROR_LIST_FILE_BACKUP"
    err "$?" "$FUNCNAME" "failed to download mirror list"

    downloadFile $MIRROR_LIST_URL $MIRROR_LIST_FILE
    err "$?" "$FUNCNAME" "failed to download mirror list"

    uncommentVar "Server" $MIRROR_LIST_FILE
    err "$?" "$FUNCNAME" "failed to download mirror list"

    log "Download mirror list...done"
}

installBaseSystem()
{
    reqVar "ROOT_PARTITION_MOUNT_POINT" "$FUNCNAME"
    reqVar "BASE_SYSTEM_PACKAGES" "$FUNCNAME"

    log "Install base system..."

    cmd "pacstrap -i $ROOT_PARTITION_MOUNT_POINT $BASE_SYSTEM_PACKAGES"
    err "$?" "$FUNCNAME" "failed to install base system"

    log "Install base system...done"
}

generateFstab()
{
    reqVar "ROOT_PARTITION_MOUNT_POINT" "$FUNCNAME"

    log "Generate fstab..."

    cmd "genfstab -L -p $ROOT_PARTITION_MOUNT_POINT >>"\
        " $ROOT_PARTITION_MOUNT_POINT/etc/fstab"
    err "$?" "$FUNCNAME" "failed to generate fstab"

    log "Generate fstab...done"
}

setHostName()
{
    reqVar "HOST_NAME" "$FUNCNAME"

    log "Set host name..."

    archChroot "echo $HOST_NAME > /etc/hostname"
    err "$?" "$FUNCNAME" "failed to set host name"

    log "Set host name...done"
}

setLocales()
{
    reqVar "LOCALIZATION_LANGUAGE_EN" "$FUNCNAME"
    reqVar "LOCALIZATION_LANGUAGE_PL" "$FUNCNAME"

    log "Set locales..."

    setLocale "$LOCALIZATION_LANGUAGE_EN"
    err "$?" "$FUNCNAME" "failed to set locale"

    setLocale "$LOCALIZATION_LANGUAGE_PL"
    err "$?" "$FUNCNAME" "failed to set locale"

    log "Set locales...done"
}

generateLocales()
{
    log "Generate locales..."

    archChroot "locale-gen"
    err "$?" "$FUNCNAME" "failed to generate locales"

    log "Generate locales...done"
}

setLanguage()
{
    reqVar "LOCALIZATION_LANGUAGE_EN" "$FUNCNAME"

    log "Set language..."

    archChroot "echo LANG=$LOCALIZATION_LANGUAGE_EN >> /etc/locale.conf"
    err "$?" "$FUNCNAME" "failed to set language"

    log "Set language...done"
}

setLocalizationCtype()
{
    reqVar "LOCALIZATION_CTYPE" "$FUNCNAME"

    log "Set localization ctype..."

    archChroot "echo LC_CTYPE=$LOCALIZATION_CTYPE >> /etc/locale.conf"
    err "$?" "$FUNCNAME" "failed to set localization ctype"

    log "Set localization ctype...done"
}

setLocalizationNumeric()
{
    reqVar "LOCALIZATION_NUMERIC" "$FUNCNAME"

    log "Set localization numeric..."

    archChroot "echo LC_NUMERIC=$LOCALIZATION_NUMERIC >> /etc/locale.conf"
    err "$?" "$FUNCNAME" "failed to set localization numeric"

    log "Set localization numeric...done"
}

setLocalizationTime()
{
    reqVar "LOCALIZATION_TIME" "$FUNCNAME"

    log "Set localization time..."

    archChroot "echo LC_TIME=$LOCALIZATION_TIME >> /etc/locale.conf"
    err "$?" "$FUNCNAME" "failed to set localization time"

    log "Set localization time...done"
}

setLocalizationCollate()
{
    reqVar "LOCALIZATION_COLLATE" "$FUNCNAME"

    log "Set localization collate..."

    archChroot "echo LC_COLLATE=$LOCALIZATION_COLLATE >> /etc/locale.conf"
    err "$?" "$FUNCNAME" "failed to set localization collate"

    log "Set localization collate...done"
}

setLocalizationMonetary()
{
    reqVar "LOCALIZATION_MONETARY" "$FUNCNAME"

    log "Set localization monetary..."

    archChroot "echo LC_MONETARY=$LOCALIZATION_MONETARY >> /etc/locale.conf"
    err "$?" "$FUNCNAME" "failed to set localization monetary"

    log "Set localization monetary...done"
}

setLocalizationMeasurement()
{
    reqVar "LOCALIZATION_MEASUREMENT" "$FUNCNAME"

    log "Set localization measurenent..."

    archChroot\
        "echo LC_MEASUREMENT=$LOCALIZATION_MEASUREMENT >> /etc/locale.conf"
    err "$?" "$FUNCNAME" "failed to set localization monetary"

    log "Set localization measurement...done"
}

setTimeZone()
{
    reqVar "LOCALIZATION_TIME_ZONE" "$FUNCNAME"

    log "Set time zone..."

    archChroot\
        "ln -s /usr/share/zoneinfo/$LOCALIZATION_TIME_ZONE /etc/localtime"
    err "$?" "$FUNCNAME" "failed to set time zone"

    log "Set time zone...done"
}

setHardwareClock()
{
    reqVar "LOCALIZATION_HW_CLOCK" "$FUNCNAME"

    log "Set hardware clock..."

    archChroot "hwclock $LOCALIZATION_HW_CLOCK"
    err "$?" "$FUNCNAME" "failed to set hardware clock"

    log "Set hardware clock...done"
}

setConsoleKeymap()
{
    reqVar "CONSOLE_KEYMAP" "$FUNCNAME"

    log "Set console keymap..."

    archChroot "echo KEYMAP=$CONSOLE_KEYMAP > /etc/vconsole.conf"
    err "$?" "$FUNCNAME" "failed to set console keymap"

    log "Set console keymap...done"
}

setConsoleFont()
{
    reqVar "CONSOLE_FONT" "$FUNCNAME"

    log "Set console font..."

    archChroot "echo FONT=$CONSOLE_FONT >> /etc/vconsole.conf"
    err "$?" "$FUNCNAME" "failed to set console font"

    log "Set console font...done"
}

setConsoleFontmap()
{
    reqVar "CONSOLE_FONTMAP" "$FUNCNAME"

    log "Set console fontmap..."

    archChroot "echo FONT_MAP=$CONSOLE_FONTMAP >> /etc/vconsole.conf"
    err "$?" "$FUNCNAME" "failed to set console fontmap"

    log "Set console fontmap...done"
}

setWiredNetwork()
{
    reqVar "NETWORK_SERVICE" "$FUNCNAME"
    reqVar "NETWORK_INTERFACE_WIRED" "$FUNCNAME"

    log "Set wired network..."

    archChroot\
        "systemctl enable $NETWORK_SERVICE@$NETWORK_INTERFACE_WIRED.service"
    err "$?" "$FUNCNAME" "failed to set wired network"

    log "Set wired network...done"
}

installBootloader()
{
    reqVar "BOOTLOADER_PACKAGE" "$FUNCNAME"

    log "Install bootloader..."

    archChroot "pacman -S $BOOTLOADER_PACKAGE --noconfirm"
    err "$?" "$FUNCNAME" "failed to install bootloader"

    log "Install bootloader...done"
}

configureSyslinux()
{
    reqVar "ROOT_PARTITION_HDD" "$FUNCNAME"
    reqVar "ROOT_PARTITION_NB" "$FUNCNAME"

    log "Configure syslinux..."

    archChroot "syslinux-install_update -i -a -m"
    err "$?" "$FUNCNAME" "failed to update syslinux"

    local src="sda3"
    local dst="$ROOT_PARTITION_HDD$ROOT_PARTITION_NB"
    local subst="s|$src|$dst|g"
    local file="/boot/syslinux/syslinux.cfg"
    archChroot "sed -i \\\"$subst\\\" $file"
    err "$?" "$FUNCNAME" "failed to change partition name in syslinux"

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
    reqVar "PROJECT_MNT_PATH" "$FUNCNAME"
    reqVar "PROJECT_ROOT_PATH" "$FUNCNAME"

    # Do not perform typical logging in this function...
    # This would spoil nice logs copied to new system

    mkdir -p $PROJECT_MNT_PATH
    err "$?" "$FUNCNAME" "failed to copy $PROJECT_NAME files"

    cp -R $PROJECT_ROOT_PATH/* $PROJECT_MNT_PATH
    err "$?" "$FUNCNAME" "failed to copy $PROJECT_NAME files"

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
    setLocalizationCtype
    setLocalizationNumeric
    setLocalizationTime
    setLocalizationCollate
    setLocalizationMonetary
    setLocalizationMeasurement
    setTimeZone
    setHardwareClock
    setConsoleKeymap
    setConsoleFont
    setConsoleFontmap
    setWiredNetwork
    installBootloader
    configureSyslinux
    setRootPassword

    log "Setup basic...done"

    #=======================================
    # Post installation actions
    #=======================================

    copyProjectFiles
    unmountPartitions
}

