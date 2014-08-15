#!/bin/bash
#===============================================================================
# FILE:         all_steps.sh
#
# USAGE:        Include in ohter scripts, e.g. source all_steps.sh
#
# DESCRIPTION:  Each function is a step of a target system preparation.
#               This file contains all step functions.
#               Other files (custom, individual) may group the steps to
#               form logically related compositions.
#               Contains only function definitions - they are not executed.
#
# CONVENTIONS:  A function should either return an error code or abort a script
#               on failure.
#               Names of functions returning value start with an underscore.
#               Exception:  log function - returns result but always neglected,
#                           so without an underscore - for convenience
#===============================================================================

#===============================================================================
# Installation
#===============================================================================

#=======================================
# Pre install
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
# Partitioning
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
# Install
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
# Post install
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
# Customization TODO: Rename sections appropriately, when sorted and fixed
#===============================================================================

#=======================================
# Common setup
#=======================================

setMultilibRepository()
{
    log "Set multilib repository..."

    # Use repository for multilib support - to allow 32B apps on 64B system
    # Needed for Android development
    _cmd "sed -i '/\[multilib\]/,/Include/ s|^#\(.*\)|\1|' /etc/pacman.conf"
    err "$?" "$FUNCNAME" "failed to set multilib repository"

    log "Set multilib repository...done"
}

#===================
# Common users
#===================

addUser1()
{
    req USER1_MAIN_GROUP $FUNCNAME
    req USER1_ADDITIONAL_GROUPS $FUNCNAME
    req USER1_SHELL $FUNCNAME
    req USER1_NAME $FUNCNAME

    log "Add user1..."

    addUser $USER1_MAIN_GROUP $USER1_ADDITIONAL_GROUPS $USER1_SHELL $USER1_NAME

    log "Add user1...done"
}

setUser1Password()
{
    req USER1_NAME $FUNCNAME

    log "Set user 1 password..."

    setUserPassword $USER1_NAME

    log "Set user 1 password...done"
}

setUser1Sudoer()
{
    req USER1_NAME $FUNCNAME

    log "Set user1 sudoer..."

    setSudoer $USER1_NAME

    log "Set user1 sudoer...done"
}

#===================
# Common system packages
#===================

installAlsa()
{
    req ALSA_PACKAGES $FUNCNAME

    log "Install alsa..."

    installPackage $ALSA_PACKAGES

    log "Install alsa...done"
}

#===================
# Common software packages
#===================

installVim()
{
    req VIM_PACKAGES $FUNCNAME

    log "Install vim..."

    installPackage $VIM_PACKAGES

    log "Install vim...done"
}

installMc()
{
    req MC_PACKAGES $FUNCNAME

    log "Install mc..."

    installPackage $MC_PACKAGES

    log "Install mc...done"
}

installGit()
{
    req GIT_PACKAGES $FUNCNAME

    log "Install git..."

    installPackage $GIT_PACKAGES

    log "Install git...done"
}

#===================
# Common configuration
#===================

configurePacman()
{
    log "Configure pacman..."

    # Present total download instead of single package percentage
    _uncommentVar "TotalDownload" "/etc/pacman.conf"
    err "$?" "$FUNCNAME" "failed to configure pacman"

    log "Configure pacman...done"
}

configureGitUser()
{
    req GIT_USER_EMAIL $FUNCNAME
    req GIT_USER_NAME $FUNCNAME

    log "Configure git user..."

    _cmd "git config --global user.email \"$GIT_USER_EMAIL\""
    err "$?" "$FUNCNAME" "failed to configure git user email"

    _cmd "git config --global user.name \"$GIT_USER_NAME\""
    err "$?" "$FUNCNAME" "failed to configure git user name"

    log "Configure git user...done"
}

setBootloaderKernelParams()
{
    req ROOT_PARTITION_HDD $FUNCNAME
    req ROOT_PARTITION_NB $FUNCNAME
    req BOOTLOADER_KERNEL_PARAMS $FUNCNAME

    log "Set bootloader kernel params..."

    local src="APPEND root.*$"
    local path="$PARTITION_PREFIX$ROOT_PARTITION_HDD$ROOT_PARTITION_NB"
    local bkp="$BOOTLOADER_KERNEL_PARAMS"
    local params="$path $bkp"
    local dst="APPEND root=$params"
    local subst="s|$src|$dst|"
    local file="/boot/syslinux/syslinux.cfg"
    _cmd "sed -i \"$subst\" $file"
    err "$?" "$FUNCNAME" "failed to set bootloader kernel params"

    log "Set bootloader kernel params...done"
}

disableSyslinuxBootMenu()
{
    log "Disable syslinux boot menu..."

    _commentVar "UI" "/boot/syslinux/syslinux.cfg"
    err "$?" "$FUNCNAME" "failed to disable syslinux boot menu"

    log "Disable syslinux boot menu...done"
}

setConsoleLoginMessage()
{
    log "Set console login message..."

    # Remove welcome message
    _cmd "rm -f /etc/issue"
    err "$?" "$FUNCNAME" "failed to remove /etc/issue file"

    # Set new welcome message, if present
    if [ ! -z "$CONSOLE_LOGIN_MSG" ];then
        _cmd "echo $CONSOLE_LOGIN_MSG > /etc/issue"
        err "$?" "$FUNCNAME" "failed to set console login message"
    else
        log "Console welcome message not set, /etc/issue file deleted"
    fi

    log "Set console login message...done"
}

# This requires image recreation for changes to take effect
setMkinitcpioModules()
{
    req MKINITCPIO_MODULES $FUNCNAME

    log "Setting mkinitcpio modules..."

    local src="^MODULES.*$"
    local dst="MODULES=\\\"$MKINITCPIO_MODULES\\\""
    local subst="s|$src|$dst|"
    local file="/etc/mkinitcpio.conf"
    _cmd "sed -i \"$subst\" $file"
    err "$?" "$FUNCNAME" "failed to set mkinitcpio modules"

    log "Setting mkinitcpio modules...done"
}

# This requires image recreation for changes to take effect
setMkinitcpioHooks()
{
    req MKINITCPIO_HOOKS $FUNCNAME

    log "Set mkinitcpio hooks..."

    # Set hooks
    local src="^HOOKS.*$"
    local dst="HOOKS=\\\"$MKINITCPIO_HOOKS\\\""
    local subst="s|$src|$dst|"
    local file="/etc/mkinitcpio.conf"
    _cmd "sed -i \"$subst\" $file"
    err "$?" "$FUNCNAME" "failed to set mkinitcpio hooks"

    log "Set mkinitcpio hooks...done"
}

initAlsa()
{
    log "Init alsa..."

    _cmd "alsactl init"
    # May return error 99 - ignore it

    log "Init alsa...done"
}

unmuteAlsa()
{
    log "Unmute alsa..."

    _cmd "amixer sset Master unmute"
    err "$?" "$FUNCNAME" "failed to unmute alsa"

    log "Unmute alsa...done"
}

setPcmModuleLoading()
{
    req KERNEL_MODULES_PATH $FUNCNAME
    req SND_PCM_OSS_FILE $FUNCNAME
    req SND_PCM_OSS_MODULE $FUNCNAME

    log "Set snd-pcm-oss module loading..."

    _cmd "echo $SND_PCM_OSS_MODULE >> $KERNEL_MODULES_PATH/$SND_PCM_OSS_FILE"
    err "$?" "$FUNCNAME" "failed to set snd-pcm-oss module loading"

    log "Set snd-pcm-oss module loading...done"
}

disablePcSpeaker()
{
    req PCSPEAKER_MODULE $FUNCNAME
    req MODPROBE_PATH $FUNCNAME
    req NO_PCSPEAKER_FILE $FUNCNAME

    log "Disable pc speaker..."

    _cmd "echo \"blacklist $PCSPEAKER_MODULE\" >>"\
        " $MODPROBE_PATH/$NO_PCSPEAKER_FILE"
    err "$?" "$FUNCNAME" "failed to disable pc speaker"

    log "Disable pc speaker...done"
}

#=======================================
# Project repository cloning
#=======================================

cloneProjectRepo()
{
    req PROJECT_REPO_URL $FUNCNAME
    req PROJECT_REPO_DST $FUNCNAME

    log "Clone $PROJECT_NAME repo..."

    _cmd "git clone $PROJECT_REPO_URL $PROJECT_REPO_DST"
    err "$?" "$FUNCNAME" "failed to clone $PROJECT_NAME repo"

    log "Clone $PROJECT_NAME repo...done"
}

checkoutCurrentBranch()
{
    req PROJECT_REPO_DST $FUNCNAME
    req PROJECT_BRANCH $FUNCNAME

    log "Checkout current branch..."

    # Execute git commands from destination path
    _cmd "git -C $PROJECT_REPO_DST checkout $PROJECT_BRANCH"
    err "$?" "$FUNCNAME" "failed to checkout current branch"

    log "Checkout current branch...done"
}

copyOverProjectFiles()
{
    req PROJECT_ROOT_PATH $FUNCNAME
    req USER1_HOME $FUNCNAME

    log "Copy over $PROJECT_NAME files..."

    _cmd "cp -r $PROJECT_ROOT_PATH $USER1_HOME"
    err "$?" "$FUNCNAME" "failed to copy over $PROJECT_NAME files"

    log "Copy over $PROJECT_NAME files...done"
}

#=======================================
# Individual setup
#=======================================

#===================
# Individual users
#===================

#===================
# Individual system packages
#===================

installXorgBasic()
{
    req XORG_BASIC_PACKAGES $FUNCNAME

    log "Install xorg basics..."

    installPackage $XORG_BASIC_PACKAGES

    log "Install xorg basics...done"
}

installXorgAdditional()
{
    req XORG_ADDITIONAL_PACKAGES $FUNCNAME

    log "Install xorg additional..."

    installPackage $XORG_ADDITIONAL_PACKAGES

    log "Install xorg additional...done"
}

#===================
# Individual software packages
#===================

#=========
# Console-based
#=========

installDvtm()
{
    req DVTM_PACKAGES $FUNCNAME
    log "Install dvtm..."

    installPackage $DVTM_PACKAGES

    log "Install dvtm...done"
}

installCustomizedDvtm()
{
    req DVTM_GIT_REPO $FUNCNAME
    req DVTM_BUILD_PATH $FUNCNAME
    req DVTM_CUSTOM_BRANCH $FUNCNAME
    req DVTM_ACTIVE_COLOR $FUNCNAME
    req DVTM_MOD_KEY $FUNCNAME
    req CUSTOM_COMMIT_COMMENT $FUNCNAME

    log "Install customized dvtm..."

    _cmd "git clone $DVTM_GIT_REPO $DVTM_BUILD_PATH"
    err "$?" "$FUNCNAME" "failed to clone dvtm repository"

    _cmd "git -C $DVTM_BUILD_PATH checkout -b $DVTM_CUSTOM_BRANCH"
    err "$?" "$FUNCNAME" "failed to checkout new branch"

    # Change default blue color to something brighter
    # to make it visible on older CRT monitor
    local src="BLUE"
    local dst="$DVTM_ACTIVE_COLOR"
    local subst="s|$src|$dst|g"
    local file="$DVTM_BUILD_PATH/config.def.h"
    _cmd "sed -i \"$subst\" $file"
    err "$?" "$FUNCNAME" "failed to change active color"

    # Change default mod key - 'g' is not convenient to be used with CTRL key
    src="#define MOD CTRL('g')"
    dst="#define MOD CTRL('$DVTM_MOD_KEY')"
    subst="s|$src|$dst|g"
    file="$DVTM_BUILD_PATH/config.def.h"
    _cmd "sed -i \"$subst\" $file"
    err "$?" "$FUNCNAME" "failed to change mod key"

    _cmd "git -C $DVTM_BUILD_PATH commit -a -m \"$CUSTOM_COMMIT_COMMENT\""
    err "$?" "$FUNCNAME" "failed to commit adjustments"

    _cmd "make -C $DVTM_BUILD_PATH"
    err "$?" "$FUNCNAME" "failed to make dvtm"

    _cmd "make -C $DVTM_BUILD_PATH install"
    err "$?" "$FUNCNAME" "failed to install dvtm"

    log "Install customized dvtm...done"
}

installElinks()
{
    req ELINKS_PACKAGES $FUNCNAME

    log "Install elinks..."

    installPackage $ELINKS_PACKAGES

    log "Install elinks...done"
}

installCmus()
{
    req CMUS_PACKAGES $FUNCNAME

    log "Install cmus..."

    installPackage $CMUS_PACKAGES

    log "Install cmus...done"
}

installJdk()
{
    req JDK_AUR_PACKAGES $FUNCNAME

    log "Install jdk..."

    installAurPackage $JDK_AUR_PACKAGES

    log "Install jdk...done"
}

installAndroidEnv()
{
    req ANDROID_ENV_PACKAGES $FUNCNAME

    log "Install android env"

    installAurPackage $ANDROID_ENV_PACKAGES

    # Needed to update sdk manually using 'android' tool
    _cmd "chmod -R 755 /opt/android-sdk"
    err "$?" "$FUNCNAME" "failed to set permissions to /opt/android-sdk"

    log "Install android env...done"
}

installVirtualboxGuestAdditions()
{
    req VIRTUALBOX_GUEST_UTILS_PACKAGES $FUNCNAME
    req VIRTUALBOX_GUEST_UTILS_MODULES $FUNCNAME
    req VIRTUALBOX_GUEST_UTILS_MODULES_FILE $FUNCNAME

    log "Install virtualbox guest additions..."

    # Install the packages
    installPackage $VIRTUALBOX_GUEST_UTILS_PACKAGES

    # Load required modules
    _cmd "modprobe -a $VIRTUALBOX_GUEST_UTILS_MODULES"
    err "$?" "$FUNCNAME" "failed to load required modules"

    # Setup modules to be loaded on startup
    if [ ! -z "$VIRTUALBOX_GUEST_UTILS_MODULES" ]; then
        for module in $VIRTUALBOX_GUEST_UTILS_MODULES
        do
            _cmd "echo $module >> $VIRTUALBOX_GUEST_UTILS_MODULES_FILE"
            err "$?" "$FUNCNAME"\
                "failed to setup module to be loaded on startup"
        done
    fi

    log "Install virtualbox guest additions...done"
}

#=========
# GUI-based
#=========

installRxvtUnicode()
{
    req RXVTUNICODE_PACKAGES $FUNCNAME

    log "Install rxvt unicode..."

    installPackage $RXVTUNICODE_PACKAGES

    log "Install rxvt unicode...done"
}

installGuiFonts()
{
    req GUI_FONT_PACKAGES $FUNCNAME

    log "Install gui fonts..."

    installPackage $GUI_FONT_PACKAGES

    log "Install gui fonts...done"
}

installDwm()
{
    req DWM_PACKAGES $FUNCNAME

    log "Install dwm..."

    installPackage $DWM_PACKAGES

    log "Install dwm...done"
}

installCustomizedDwm()
{
    req DWM_GIT_REPO $FUNCNAME
    req DWM_BUILD_PATH $FUNCNAME
    req DWM_BASE_COMMIT $FUNCNAME
    req DWM_CUSTOM_BRANCH $FUNCNAME
    req PATCHES_DIR $FUNCNAME
    req DWM_CUSTOM_PATCH_FILE $FUNCNAME
    req CUSTOM_COMMIT_COMMENT $FUNCNAME

    log "Installing customized dwm..."

    # Clone project from git
    _cmd "git clone $DWM_GIT_REPO $DWM_BUILD_PATH"
    err "$?" "$FUNCNAME" "failed to clone dwm repository"

    # Newest commit was not working... use specific, working version
    _cmd "git -C $DWM_BUILD_PATH checkout $DWM_BASE_COMMIT -b $DWM_CUSTOM_BRANCH"
    err "$?" "$FUNCNAME" "failed to checkout older commit as a new branch"

    # Apply patch with customizations
    _cmd "git -C $DWM_BUILD_PATH apply $PATCHES_DIR/$DWM_CUSTOM_PATCH_FILE"
    err "$?" "$FUNCNAME" "failed to apply custom dwm patch"

    # Add changes introduced with patch. Use add . since new files may be added.
    _cmd "git -C $DWM_BUILD_PATH add ."
    err "$?" "$FUNCNAME" "failed to add patch changes"

    # Save configuration as new commit
    _cmd "git -C $DWM_BUILD_PATH commit -m \"$CUSTOM_COMMIT_COMMENT\""
    err "$?" "$FUNCNAME" "failed to commit adjustments"

    # Install
    _cmd "make -C $DWM_BUILD_PATH clean install"
    err "$?" "$FUNCNAME" "failed to build and install dwm"

    log "Installing customized dwm...done"
}

installDmenu()
{
    req DMENU_PACKAGES $FUNCNAME

    log "Install dmenu..."

    installPackage $DMENU_PACKAGES

    log "Install dmenu...done"
}

installOpera()
{
    req OPERA_PACKAGES $FUNCNAME

    log "Install opera..."

    installPackage $OPERA_PACKAGES

    log "Install opera...done"
}

installConky()
{
    req CONKY_PACKAGES $FUNCNAME

    log "Install conky..."

    installPackage $CONKY_PACKAGES

    log "Install conky...done"
}

# To be able to bind special keyboard keys to commands
installXbindkeys()
{
    req XBINDKEYS_PACKAGES $FUNCNAME

    log "Install xbindkeys..."

    installPackage $XBINDKEYS_PACKAGES

    log "Install xbindkeys...done"
}

# To fix misbehaving Java windows
installWmname()
{
    req WMNAME_PACKAGES $FUNCNAME

    log "Install wmname..."

    installPackage $WMNAME_PACKAGES

    log "Install wmname...done"
}

installVlc()
{
    req VLC_PACKAGES $FUNCNAME

    log "Install vlc..."

    installPackage $VLC_PACKAGES

    log "Install vlc...done"
}

#===================
# Individual configuration
#===================

setVirtualboxSharedFolder()
{
    req USER1_NAME $FUNCNAME
    req USER1_HOME $FUNCNAME
    req VIRTUALBOX_SHARED_FOLDER_NAME $FUNCNAME

    log "Set virtualbox shared folder..."

    # Create /media folder
    _cmd "mkdir /media"
    err "$?" "$FUNCNAME" "failed to create /media dir"

    # Add user1 to vboxsf group
    _cmd "gpasswd -a $USER1_NAME vboxsf"
    err "$?" "$FUNCNAME" "failed to add user to vboxsf group"

    # Enable vboxservice service
    _enableService "vboxservice"
    err "$?" "$FUNCNAME" "failed to enable vboxservice"

    # Start vboxservice (needed for link creation)
    _startService "vboxservice"
    err "$?" "$FUNCNAME" "failed to start vboxservice"

    # Wait a moment for a started service to do its job
    _cmd "sleep 5"

    # Create link for easy access
    _createLink\
        "/media/sf_$VIRTUALBOX_SHARED_FOLDER_NAME"\
        "$USER1_HOME/$VIRTUALBOX_SHARED_FOLDER_NAME"
    err "$?" "$FUNCNAME" "failed to create link to shared folder"

    log "Set virtualbox shared folder...done"
}

#=========
# Dotfiles
#=========

# Bash etc.

installBashprofileDotfile()
{
    log "Install bash_profile dotfile..."

    _installDotfile ".bash_profile" ""
    err "$?" "$FUNCNAME" "failed to install bash_profile dotfile"

    log "Install bash_profile dotfile...done"
}

installBashrcDotfile()
{
    log "Install bashrc dotfile..."

    _installDotfile ".bashrc" ""
    err "$?" "$FUNCNAME" "failed to install bashrc dotfile"

    log "Install bashrc dotfile...done"
}

installDircolorssolarizedDotfile()
{
    log "Install .dir_colors_solarized dotfile..."

    _installDotfile ".dir_colors_solarized" ""
    err "$?" "$FUNCNAME" "failed to install .dir_colors_solarized dotfile"

    log "Install .dir_colors_solarized dotfile...done"
}

# vim

installVimrcDotfile()
{
    log "Install vimrc dotfile..."

    _installDotfile ".vimrc" ""
    err "$?" "$FUNCNAME" "failed to install vimrc dotfile"

    log "Install vimrc dotfile...done"
}

installVimsolarizedDotfile()
{
    log "Install solarized.vim dotfile..."

    _installDotfile "solarized.vim" ".vim/colors"
    err "$?" "$FUNCNAME" "failed to install solarized.vim dotfile"

    log "Install solarized.vim dotfile...done"
}

# mc

installMcsolarizedDotfile()
{
    log "Install mc_solarized.ini dotfile..."

    _installDotfile "mc_solarized.ini" ".config/mc"
    err "$?" "$FUNCNAME" "failed to install mc_solarized.ini dotfile"

    log "Install mc_solarized.ini dotfile...done"
}

# git

installGitconfigDotfile()
{
    log "Install .gitconfig dotfile..."

    _installDotfile ".gitconfig" ""
    err "$?" "$FUNCNAME" "failed to install .gitconfig dotfile"

    log "Install .gitconfig dotfile...done"
}

# cmus

installCmusColorThemeDotfile()
{
    log "Install cmus color theme dotfile..."

    _installDotfile "solarized.theme" ".cmus"
    err "$?" "$FUNCNAME" "failed to install cmus color theme"

    log "Install cmus color theme dotfile...done"
}

# X

installXinitrcDotfile()
{
    log "Install .xinitrc dotfile..."

    _installDotfile ".xinitrc" ""
    err "$?" "$FUNCNAME" "failed to install .xinitrc dotfile"

    log "Install .xinitrc dotfile...done"
}

installXresourcesDotfile()
{
    log "Install .Xresources dotfile..."

    _installDotfile ".Xresources" ""
    err "$?" "$FUNCNAME" "failed to install .Xresources dotfile"

    log "Install .Xresources dotfile...done"
}

installConkyDotfile()
{
    log "Install .conkyrc dotfile..."

    _installDotfile ".conkyrc" ""
    err "$?" "$FUNCNAME" "failed to install .conkyrc dotfile"

    log "Install .conkyrc dotfile...done"
}

installXbindkeysDotfile()
{
    log "Install .xbindkeysrc dotfile..."

    _installDotfile ".xbindkeysrc" ""
    err "$?" "$FUNCNAME" "failed to install .xbindkeys dotfile"

    log "Install .xbindkeysrc dotfile...done"
}

#===================
# Other
#===================

recreateImage()
{
    log "Recreate linux image..."

    _cmd "mkinitcpio -p linux"
    err "$?" "$FUNCNAME" "failed to set recreate linux image"

    log "Recreate linux image...done"
}

changeUser1HomeOwnership()
{
    req USER1_NAME $FUNCNAME
    req USER1_HOME $FUNCNAME

    log "Change user1 home ownership..."

    changeHomeOwnership "$USER1_NAME" "$USER1_HOME"

    log "Change user1 home ownership...done"
}

#=======================================
# Post setup actions
#=======================================

copyProjectLogFiles()
{
    req LOG_DIR $FUNCNAME
    req PROJECT_REPO_DST $FUNCNAME
    req MACHINE $FUNCNAME

    # Do not perform typical logging in this function...
    # This would spoil nice logs copied to user's dir

    cp -r $LOG_DIR $PROJECT_REPO_DST/$MACHINE
    err "$?" "$FUNCNAME" "failed to copy project log files"
}

