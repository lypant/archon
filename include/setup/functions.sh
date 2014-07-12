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

_uncommentVar()
{
    if [[ $# -lt 2 ]]; then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        return 1
    fi

	local var="$1"
	local file="$2"

    _cmd "sed -i \"s|^#\(${var}.*\)$|\1|\" ${file}"
    return $?
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

_downloadFile()
{
    if [[ $# -lt 2 ]]; then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        return 1
    fi

    local src=$1
    local dst=$2

    _cmd "curl -so $dst --create-dirs $src"
    return $?
}

_archChroot()
{
    req ROOT_PARTITION_MOUNT_POINT $FUNCNAME

    if [[ $# -lt 1 ]];then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        return 1
    fi

    _cmd arch-chroot $ROOT_PARTITION_MOUNT_POINT /bin/bash -c \""$@"\"
    return $?
}

setLocale()
{
    if [[ $# -lt 1 ]]; then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        err "1" "$FUNCNAME" "failed to set locale"
    fi

    log "Set locale for  $1..."

    local subst="s|^#\\\\\(${1}.*\\\\\)$|\1|"
    local file="/etc/locale.gen"
    _archChroot "sed -i \\\"$subst\\\" $file"
    err "$?" "$FUNCNAME" "failed to set locale"

    log "Set locale for $1...done"
}

addUser()
{
    if [[ $# -lt 4 ]];then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        err "1" "$FUNCNAME" "failed to add user"
    fi

    local mainGroup="$1"
    local additionalGroups="$2"
    local shell="$3"
    local name="$4"

    log "Add user..."

    _cmd "useradd -m -g $mainGroup -G $additionalGroups -s $shell $name"
    err "$?" "$FUNCNAME" "failed to add user"

    log "Add user...done"
}

setUserPassword()
{
    if [[ $# -lt 1 ]];then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        err "1" "$FUNCNAME" "failed to set user password"
    fi

    log "Set user password..."

    local ask=1
    local name="$1"

    while [ $ask -ne 0 ]; do
        log "Provide password for user $name"
        _cmd "passwd $name"
        ask=$?
    done

    log "Set user password...done"
}

setSudoer()
{
    if [[ $# -lt 1 ]];then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        err "1" "$FUNCNAME" "failed to set sudoer"
    fi

    log "Set sudoer..."

    local name="$1"

    # TODO - do it in a safer way... Here just for experiments
    _cmd "echo \"$name ALL=(ALL) ALL\" >> /etc/sudoers"
    err "$?" "$FUNCNAME" "failed to set sudoer"

    log "Set sudoer...done"
}

#===============================================================================
# Basic setup functions
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

#=======================================
# Installation
#=======================================

# Note: rankMirrors takes longer time but
# might provide faster servers than downloadMirrorList
rankMirrors()
{
    req MIRROR_LIST_FILE $FUNCNAME
    req MIRROR_LIST_FILE_BACKUP $FUNCNAME
    req MIRROR_COUNT $FUNCNAME

    log "Rank mirrors..."

    # Backup original file
    _cmd "cp $MIRROR_LIST_FILE $MIRROR_LIST_FILE_BACKUP"
    err "$?" "$FUNCNAME" "failed to rank mirrors"

    _cmd "rankmirrors -n $MIRROR_COUNT $MIRROR_LIST_FILE_BACKUP >"\
        "$MIRROR_LIST_FILE"
    err "$?" "$FUNCNAME" "failed to rank mirrors"

    log "Rank mirrors...done"
}

# Note: downloadMirrorList is faster than rankMirrors but
# might give slower servers
downloadMirrorList()
{
    req MIRROR_LIST_FILE $FUNCNAME
    req MIRROR_LIST_FILE_BACKUP $FUNCNAME
    req MIRROR_LIST_URL $FUNCNAME

    log "Download mirror list..."

    # Backup original file
    _cmd "cp $MIRROR_LIST_FILE $MIRROR_LIST_FILE_BACKUP"
    err "$?" "$FUNCNAME" "failed to download mirror list"

    _downloadFile $MIRROR_LIST_URL $MIRROR_LIST_FILE
    err "$?" "$FUNCNAME" "failed to download mirror list"

    _uncommentVar "Server" $MIRROR_LIST_FILE
    err "$?" "$FUNCNAME" "failed to download mirror list"

    log "Download mirror list...done"
}

installBaseSystem()
{
    req ROOT_PARTITION_MOUNT_POINT $FUNCNAME
    req BASE_SYSTEM_PACKAGES $FUNCNAME

    log "Install base system..."

    _cmd "pacstrap -i $ROOT_PARTITION_MOUNT_POINT $BASE_SYSTEM_PACKAGES"
    err "$?" "$FUNCNAME" "failed to install base system"

    log "Install base system...done"
}

generateFstab()
{
    req ROOT_PARTITION_MOUNT_POINT $FUNCNAME

    log "Generate fstab..."

    _cmd "genfstab -L -p $ROOT_PARTITION_MOUNT_POINT >>"\
        " $ROOT_PARTITION_MOUNT_POINT/etc/fstab"
    err "$?" "$FUNCNAME" "failed to generate fstab"

    log "Generate fstab...done"
}

setTmpfsTmpSize()
{
    req TMPFS_TMP_SIZE $FUNCNAME
    req ROOT_PARTITION_MOUNT_POINT $FUNCNAME
    req FSTAB_FILE $FUNCNAME

    log "Set tmpfs tmp size..."

    _cmd "echo \"tmpfs /tmp tmpfs size=$TMPFS_TMP_SIZE,rw 0 0\" >>"\
        " $ROOT_PARTITION_MOUNT_POINT$FSTAB_FILE"
    err "$?" "$FUNCNAME" "failed to set tmpfs tmp size"

    log "Set tmpfs tmp size...done"
}

setHostName()
{
    req HOST_NAME $FUNCNAME

    log "Set host name..."

    _archChroot "echo $HOST_NAME > /etc/hostname"
    err "$?" "$FUNCNAME" "failed to set host name"

    log "Set host name...done"
}

setLocales()
{
    req LOCALIZATION_LANGUAGE_EN $FUNCNAME
    req LOCALIZATION_LANGUAGE_PL $FUNCNAME

    log "Set locales..."

    setLocale "$LOCALIZATION_LANGUAGE_EN"
    setLocale "$LOCALIZATION_LANGUAGE_PL"

    log "Set locales...done"
}

generateLocales()
{
    log "Generate locales..."

    _archChroot "locale-gen"
    err "$?" "$FUNCNAME" "failed to generate locales"

    log "Generate locales...done"
}

setLanguage()
{
    req LOCALIZATION_LANGUAGE_EN $FUNCNAME

    log "Set language..."

    _archChroot "echo LANG=$LOCALIZATION_LANGUAGE_EN >> /etc/locale.conf"
    err "$?" "$FUNCNAME" "failed to set language"

    log "Set language...done"
}

setLocalizationCtype()
{
    req LOCALIZATION_CTYPE $FUNCNAME

    log "Set localization ctype..."

    _archChroot "echo LC_CTYPE=$LOCALIZATION_CTYPE >> /etc/locale.conf"
    err "$?" "$FUNCNAME" "failed to set localization ctype"

    log "Set localization ctype...done"
}

setLocalizationNumeric()
{
    req LOCALIZATION_NUMERIC $FUNCNAME

    log "Set localization numeric..."

    _archChroot "echo LC_NUMERIC=$LOCALIZATION_NUMERIC >> /etc/locale.conf"
    err "$?" "$FUNCNAME" "failed to set localization numeric"

    log "Set localization numeric...done"
}

setLocalizationTime()
{
    req LOCALIZATION_TIME $FUNCNAME

    log "Set localization time..."

    _archChroot "echo LC_TIME=$LOCALIZATION_TIME >> /etc/locale.conf"
    err "$?" "$FUNCNAME" "failed to set localization time"

    log "Set localization time...done"
}

setLocalizationCollate()
{
    req LOCALIZATION_COLLATE $FUNCNAME

    log "Set localization collate..."

    _archChroot "echo LC_COLLATE=$LOCALIZATION_COLLATE >> /etc/locale.conf"
    err "$?" "$FUNCNAME" "failed to set localization collate"

    log "Set localization collate...done"
}

setLocalizationMonetary()
{
    req LOCALIZATION_MONETARY $FUNCNAME

    log "Set localization monetary..."

    _archChroot "echo LC_MONETARY=$LOCALIZATION_MONETARY >> /etc/locale.conf"
    err "$?" "$FUNCNAME" "failed to set localization monetary"

    log "Set localization monetary...done"
}

setLocalizationMeasurement()
{
    req LOCALIZATION_MEASUREMENT $FUNCNAME

    log "Set localization measurenent..."

    _archChroot\
        "echo LC_MEASUREMENT=$LOCALIZATION_MEASUREMENT >> /etc/locale.conf"
    err "$?" "$FUNCNAME" "failed to set localization monetary"

    log "Set localization measurement...done"
}

setTimeZone()
{
    req LOCALIZATION_TIME_ZONE $FUNCNAME

    log "Set time zone..."

    _archChroot\
        "ln -s /usr/share/zoneinfo/$LOCALIZATION_TIME_ZONE /etc/localtime"
    err "$?" "$FUNCNAME" "failed to set time zone"

    log "Set time zone...done"
}

setHardwareClock()
{
    req LOCALIZATION_HW_CLOCK $FUNCNAME

    log "Set hardware clock..."

    _archChroot "hwclock $LOCALIZATION_HW_CLOCK"
    err "$?" "$FUNCNAME" "failed to set hardware clock"

    log "Set hardware clock...done"
}

setConsoleKeymap()
{
    req CONSOLE_KEYMAP $FUNCNAME

    log "Set console keymap..."

    _archChroot "echo KEYMAP=$CONSOLE_KEYMAP > /etc/vconsole.conf"
    err "$?" "$FUNCNAME" "failed to set console keymap"

    log "Set console keymap...done"
}

setConsoleFont()
{
    req CONSOLE_FONT $FUNCNAME

    log "Set console font..."

    _archChroot "echo FONT=$CONSOLE_FONT >> /etc/vconsole.conf"
    err "$?" "$FUNCNAME" "failed to set console font"

    log "Set console font...done"
}

setConsoleFontmap()
{
    req CONSOLE_FONTMAP $FUNCNAME

    log "Set console fontmap..."

    _archChroot "echo FONT_MAP=$CONSOLE_FONTMAP >> /etc/vconsole.conf"
    err "$?" "$FUNCNAME" "failed to set console fontmap"

    log "Set console fontmap...done"
}

setWiredNetwork()
{
    req NETWORK_SERVICE $FUNCNAME
    req NETWORK_INTERFACE_WIRED $FUNCNAME

    log "Set wired network..."

    _archChroot\
        "systemctl enable $NETWORK_SERVICE@$NETWORK_INTERFACE_WIRED.service"
    err "$?" "$FUNCNAME" "failed to set wired network"

    log "Set wired network...done"
}

installBootloader()
{
    req BOOTLOADER_PACKAGE $FUNCNAME

    log "Install bootloader..."

    _archChroot "pacman -S $BOOTLOADER_PACKAGE --noconfirm"
    err "$?" "$FUNCNAME" "failed to install bootloader"

    log "Install bootloader...done"
}

configureSyslinux()
{
    req ROOT_PARTITION_HDD $FUNCNAME
    req ROOT_PARTITION_NB $FUNCNAME

    log "Configure syslinux..."

    _archChroot "syslinux-install_update -i -a -m"
    err "$?" "$FUNCNAME" "failed to update syslinux"

    local src="sda3"
    local dst="$ROOT_PARTITION_HDD$ROOT_PARTITION_NB"
    local subst="s|$src|$dst|g"
    local file="/boot/syslinux/syslinux.cfg"
    _archChroot "sed -i \\\"$subst\\\" $file"
    err "$?" "$FUNCNAME" "failed to change partition name in syslinux"

    log "Configure syslinux...done"
}

setRootPassword()
{
    log "Set root password..."

    local ASK=1

    while [ $ASK -ne 0 ]; do
        _archChroot "passwd"
        ASK=$?
    done

    log "Set root password...done"
}

#=======================================
# Post installation actions
#=======================================

copyProjectFiles()
{
    req PROJECT_MNT_PATH $FUNCNAME
    req PROJECT_ROOT_PATH $FUNCNAME

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
# Custom setup functions
#===============================================================================

#=======================================
# Common setup
#=======================================

#===================
# Common users
#===================

addUser1()
{
    req USER1_MAIN_GROUP $FUNCTION
    req USER1_ADDITIONAL_GROUPS $FUNCTION
    req USER1_SHELL $FUNCTION
    req USER1_NAME $FUNCTION

    log "Add user1..."

    addUser $USER1_MAIN_GROUP $USER1_ADDITIONAL_GROUPS $USER1_SHELL $USER1_NAME

    log "Add user1...done"
}

setUser1Password()
{
    req USER1_NAME $FUNCTION

    log "Set user 1 password..."

    setUserPassword $USER1_NAME

    log "Set user 1 password...done"
}

setUser1Sudoer()
{
    req USER1_NAME $FUNCTION

    log "Set user1 sudoer..."

    setSudoer $USER1_NAME

    log "Set user1 sudoer...done"
}

#===================
# Common system packages
#===================

installAlsa()
{
    req ALSA_PACKAGES $FUNCTION

    log "Install alsa..."

    installPackage $ALSA_PACKAGES

    log "Install alsa...done"
}

#===================
# Common software packages
#===================

installVim()
{
    req VIM_PACKAGES $FUNCTION

    log "Install vim..."

    installPackage $VIM_PACKAGES

    log "Install vim...done"
}

installMc()
{
    req MC_PACKAGES $FUNCTION

    log "Install mc..."

    installPackage $MC_PACKAGES

    log "Install mc...done"
}

installGit()
{
    req GIT_PACKAGES $FUNCTION

    log "Install git..."

    installPackage $GIT_PACKAGES

    log "Install git...done"
}

