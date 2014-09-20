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
#===============================================================================

set -o nounset errexit

#===============================================================================
# Installation
#===============================================================================

#=======================================
# Pre install
#=======================================

setConsoleFontTemporarily()
{
    # Font setting is not crucial, so don't abort the script when it fails
    setfont $CONSOLE_FONT
}

installArchlinuxKeyring()
{
    log "Install archlinux keyring..."
    installPackage $ARCHLINUX_KEYRING_PACKAGES
    log "Install archlinux keyring...done"
}

installLivecdVim()
{
    log "Install livecd vim..."
    installPackage $VIM_PACKAGES
    log "Install livecd vim...done"
}

#=======================================
# Partitioning
#=======================================

createSwapPartition()
{
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
    log "Set boot partition bootable..."
    setPartitionBootable\
        "$PARTITION_PREFIX$BOOT_PARTITION_HDD"\
        "$BOOT_PARTITION_NB"
    log "Set boot partition bootable...done"
}

createSwap()
{
    log "Create swap..."
    cmd "mkswap $PARTITION_PREFIX$SWAP_PARTITION_HDD$SWAP_PARTITION_NB"
    err "$?" "$FUNCNAME" "failed to create swap"
    log "Create swap...done"
}

activateSwap()
{
    log "Activate swap..."
    cmd "swapon $PARTITION_PREFIX$SWAP_PARTITION_HDD$SWAP_PARTITION_NB"
    err "$?" "$FUNCNAME" "failed to activate swap"
    log "Activate swap...done"
}

createBootFileSystem()
{
    log "Create boot file system..."
    cmd "mkfs.$BOOT_PARTITION_FS"\
        "$PARTITION_PREFIX$BOOT_PARTITION_HDD$BOOT_PARTITION_NB"
    err "$?" "$FUNCNAME" "failed to create boot file system"
    log "Create boot file system...done"
}

createRootFileSystem()
{
    log "Create root file system..."
    cmd "mkfs.$ROOT_PARTITION_FS"\
        " $PARTITION_PREFIX$ROOT_PARTITION_HDD$ROOT_PARTITION_NB"
    err "$?" "$FUNCNAME" "failed to create root file system"
    log "Create root file system...done"
}

mountRootPartition()
{
    log "Mount root partition..."
    cmd "mount $PARTITION_PREFIX$ROOT_PARTITION_HDD$ROOT_PARTITION_NB"\
        " $ROOT_PARTITION_MOUNT_POINT"
    err "$?" "$FUNCNAME" "failed to mount root partition"
    log "Mount root partition...done"
}

mountBootPartition()
{
    log "Mount boot partition..."
    cmd "mkdir $BOOT_PARTITION_MOUNT_POINT"
    err "$?" "$FUNCNAME" "failed to create boot partition mount point"
    cmd "mount $PARTITION_PREFIX$BOOT_PARTITION_HDD$BOOT_PARTITION_NB"\
        " $BOOT_PARTITION_MOUNT_POINT"
    err "$?" "$FUNCNAME" "failed to mount boot partition"
    log "Mount boot partition...done"
}

unmountPartitions()
{
    log "Unmount partitions..."
    cmd "umount -R $LIVECD_MOUNT_POINT"
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
    log "Rank mirrors..."
    # Backup original file
    cmd "cp $MIRROR_LIST_FILE $MIRROR_LIST_FILE_BACKUP"
    err "$?" "$FUNCNAME" "failed to backup mirrors file"
    cmd "rankmirrors -n $MIRROR_COUNT $MIRROR_LIST_FILE_BACKUP >"\
        "$MIRROR_LIST_FILE"
    err "$?" "$FUNCNAME" "failed to rank mirrors"
    log "Rank mirrors...done"
}

# Note: downloadMirrorList is faster than rankMirrors but
# might give slower servers
downloadMirrorList()
{
    log "Download mirror list..."
    # Backup original file
    cmd "cp $MIRROR_LIST_FILE $MIRROR_LIST_FILE_BACKUP"
    err "$?" "$FUNCNAME" "failed to backup mirrors file"
    downloadFile $MIRROR_LIST_URL $MIRROR_LIST_FILE
    uncommentVar "Server" $MIRROR_LIST_FILE
    log "Download mirror list...done"
}

installBaseSystem()
{
    # Replace linux package with cutom version, if it is used...
    local basePkgs=$(pacman -Sqg base | sed "s|^linux$|$KERNEL_VERSION|")
    # ...change new lines into spaces
    basePkgs=$(echo $basePkgs | tr '\n' ' ')

    log "Install base system..."
    cmd "pacstrap -i $ROOT_PARTITION_MOUNT_POINT $basePkgs base-devel"
    err "$?" "$FUNCNAME" "failed to install base system"
    log "Install base system...done"
}

generateFstab()
{
    log "Generate fstab..."
    cmd "genfstab -L -p $ROOT_PARTITION_MOUNT_POINT >>"\
        " $ROOT_PARTITION_MOUNT_POINT/etc/fstab"
    err "$?" "$FUNCNAME" "failed to generate fstab"
    log "Generate fstab...done"
}

setTmpfsTmpSize()
{
    log "Set tmpfs tmp size..."
    cmd "echo \"tmpfs /tmp tmpfs size=$TMPFS_TMP_SIZE,rw 0 0\" >>"\
        " $ROOT_PARTITION_MOUNT_POINT$FSTAB_FILE"
    err "$?" "$FUNCNAME" "failed to set tmpfs tmp size"
    log "Set tmpfs tmp size...done"
}

setHostName()
{
    log "Set host name..."
    archChroot "echo $HOST_NAME > /etc/hostname"
    err "$?" "$FUNCNAME" "failed to set host name"
    log "Set host name...done"
}

setLocales()
{
    log "Set locales..."
    setLocale "$LOCALIZATION_LANGUAGE_EN"
    setLocale "$LOCALIZATION_LANGUAGE_PL"
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
    log "Set language..."
    archChroot "echo LANG=$LOCALIZATION_LANGUAGE_EN >> /etc/locale.conf"
    err "$?" "$FUNCNAME" "failed to set language"
    log "Set language...done"
}

setLocalizationCtype()
{
    log "Set localization ctype..."
    archChroot "echo LC_CTYPE=$LOCALIZATION_CTYPE >> /etc/locale.conf"
    err "$?" "$FUNCNAME" "failed to set localization ctype"
    log "Set localization ctype...done"
}

setLocalizationNumeric()
{
    log "Set localization numeric..."
    archChroot "echo LC_NUMERIC=$LOCALIZATION_NUMERIC >> /etc/locale.conf"
    err "$?" "$FUNCNAME" "failed to set localization numeric"
    log "Set localization numeric...done"
}

setLocalizationTime()
{
    log "Set localization time..."
    archChroot "echo LC_TIME=$LOCALIZATION_TIME >> /etc/locale.conf"
    err "$?" "$FUNCNAME" "failed to set localization time"
    log "Set localization time...done"
}

setLocalizationCollate()
{
    log "Set localization collate..."
    archChroot "echo LC_COLLATE=$LOCALIZATION_COLLATE >> /etc/locale.conf"
    err "$?" "$FUNCNAME" "failed to set localization collate"
    log "Set localization collate...done"
}

setLocalizationMonetary()
{
    log "Set localization monetary..."
    archChroot "echo LC_MONETARY=$LOCALIZATION_MONETARY >> /etc/locale.conf"
    err "$?" "$FUNCNAME" "failed to set localization monetary"
    log "Set localization monetary...done"
}

setLocalizationMeasurement()
{
    log "Set localization measurenent..."
    archChroot\
        "echo LC_MEASUREMENT=$LOCALIZATION_MEASUREMENT >> /etc/locale.conf"
    err "$?" "$FUNCNAME" "failed to set localization measurement"
    log "Set localization measurement...done"
}

setTimeZone()
{
    log "Set time zone..."
    archChroot\
        "ln -s /usr/share/zoneinfo/$LOCALIZATION_TIME_ZONE /etc/localtime"
    err "$?" "$FUNCNAME" "failed to set time zone"
    log "Set time zone...done"
}

setHardwareClock()
{
    log "Set hardware clock..."
    archChroot "hwclock $LOCALIZATION_HW_CLOCK"
    err "$?" "$FUNCNAME" "failed to set hardware clock"
    log "Set hardware clock...done"
}

setConsoleKeymap()
{
    log "Set console keymap..."
    archChroot "echo KEYMAP=$CONSOLE_KEYMAP > /etc/vconsole.conf"
    err "$?" "$FUNCNAME" "failed to set console keymap"
    log "Set console keymap...done"
}

setConsoleFont()
{
    log "Set console font..."
    archChroot "echo FONT=$CONSOLE_FONT >> /etc/vconsole.conf"
    err "$?" "$FUNCNAME" "failed to set console font"
    log "Set console font...done"
}

setConsoleFontmap()
{
    log "Set console fontmap..."
    archChroot "echo FONT_MAP=$CONSOLE_FONTMAP >> /etc/vconsole.conf"
    err "$?" "$FUNCNAME" "failed to set console fontmap"
    log "Set console fontmap...done"
}

setWiredNetwork()
{
    log "Set wired network..."
    archChroot\
        "systemctl enable $NETWORK_SERVICE@$NETWORK_INTERFACE_WIRED.service"
    err "$?" "$FUNCNAME" "failed to set wired network"
    log "Set wired network...done"
}

installBootloader()
{
    log "Install bootloader..."
    archChroot "pacman -S $BOOTLOADER_PACKAGE --noconfirm"
    err "$?" "$FUNCNAME" "failed to install bootloader"
    log "Install bootloader...done"
}

configureSyslinux()
{
    local src="sda3"
    local dst="$ROOT_PARTITION_HDD$ROOT_PARTITION_NB"
    local subst="s|$src|$dst|g"
    local file="/boot/syslinux/syslinux.cfg"
    local cnt=0

    log "Configure syslinux..."
    archChroot "syslinux-install_update -i -a -m"
    err "$?" "$FUNCNAME" "failed to update syslinux"

    # Workaround for monolith - if udev is mounted, unmount it
    cnt=$(mount | grep udev | wc -l)
    if [[ "$cnt" -gt 0 ]]; then
        log "Udev detected"
	    cmd "umount /mnt/dev"
    else
        log "Udev not detected"
    fi

    # Caused problems on monolith, so add delay
    delay "$BOOTLOADER_UPDATE_DELAY"
    archChroot "sed -i \\\"$subst\\\" $file"
    err "$?" "$FUNCNAME" "failed to replace parition path"
    log "Configure syslinux...done"
}

setRootPassword()
{
    local ASK=1

    log "Set root password..."

    while [ $ASK -ne 0 ]; do
        archChroot "passwd"
        ASK=$?
    done

    log "Set root password...done"
}

#=======================================
# Post install
#=======================================

copyProjectFiles()
{
    # Do not perform typical logging in this function...
    # This would spoil nice logs copied to new system
    mkdir -p $PROJECT_MNT_PATH
    cp -R $PROJECT_ROOT_PATH/* $PROJECT_MNT_PATH

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
    cmd "sed -i '/\[multilib\]/,/Include/ s|^#\(.*\)|\1|' /etc/pacman.conf"
    err "$?" "$FUNCNAME" "failed to set multilib repository"
    log "Set multilib repository...done"
}

#===================
# Common users
#===================

addUser1()
{
    log "Add user1..."
    addUser $USER1_MAIN_GROUP $USER1_ADDITIONAL_GROUPS $USER1_SHELL $USER1_NAME
    log "Add user1...done"
}

setUser1Password()
{
    log "Set user 1 password..."
    setUserPassword $USER1_NAME
    log "Set user 1 password...done"
}

setUser1Sudoer()
{
    log "Set user1 sudoer..."
    setSudoer $USER1_NAME
    log "Set user1 sudoer...done"
}

#===================
# Common system packages
#===================

installAlsa()
{
    log "Install alsa..."
    installPackage $ALSA_PACKAGES
    log "Install alsa...done"
}

#===================
# Common software packages
#===================

installVim()
{
    log "Install vim..."
    installPackage $VIM_PACKAGES
    log "Install vim...done"
}

installMc()
{
    log "Install mc..."
    installPackage $MC_PACKAGES
    log "Install mc...done"
}

installGit()
{
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
    uncommentVar "TotalDownload" "/etc/pacman.conf"
    log "Configure pacman...done"
}

configureGitUser()
{
    log "Configure git user..."
    cmd "git config --global user.email \"$GIT_USER_EMAIL\""
    err "$?" "$FUNCNAME" "failed to set git user email"
    cmd "git config --global user.name \"$GIT_USER_NAME\""
    err "$?" "$FUNCNAME" "failed to set git user name"
    log "Configure git user...done"
}

setBootloaderKernelParams()
{
    local src="APPEND root.*$"
    local path="$PARTITION_PREFIX$ROOT_PARTITION_HDD$ROOT_PARTITION_NB"
    local bkp="$BOOTLOADER_KERNEL_PARAMS"
    local params="$path $bkp"
    local dst="APPEND root=$params"
    local subst="s|$src|$dst|"
    local file="/boot/syslinux/syslinux.cfg"

    log "Set bootloader kernel params..."
    cmd "sed -i \"$subst\" $file"
    err "$?" "$FUNCNAME" "failed to set bootloader kernel params"
    log "Set bootloader kernel params...done"
}

disableSyslinuxBootMenu()
{
    log "Disable syslinux boot menu..."
    commentVar "UI" "/boot/syslinux/syslinux.cfg"
    log "Disable syslinux boot menu...done"
}

setConsoleLoginMessage()
{
    log "Set console login message..."

    # Remove welcome message
    cmd "rm -f /etc/issue"

    # Set new welcome message, if present
    if [ ! -z "$CONSOLE_LOGIN_MSG" ];then
        cmd "echo $CONSOLE_LOGIN_MSG > /etc/issue"
        err "$?" "$FUNCNAME" "failed to set welcome message"
    else
        log "Console welcome message not set, /etc/issue file deleted"
    fi

    log "Set console login message...done"
}

# This requires image recreation for changes to take effect
setMkinitcpioModules()
{
    local src="^MODULES.*$"
    local dst="MODULES=\\\"$MKINITCPIO_MODULES\\\""
    local subst="s|$src|$dst|"
    local file="/etc/mkinitcpio.conf"

    log "Setting mkinitcpio modules..."
    cmd "sed -i \"$subst\" $file"
    err "$?" "$FUNCNAME" "failed to set mkinitcpio modules"
    log "Setting mkinitcpio modules...done"
}

# This requires image recreation for changes to take effect
setMkinitcpioHooks()
{
    local src="^HOOKS.*$"
    local dst="HOOKS=\\\"$MKINITCPIO_HOOKS\\\""
    local subst="s|$src|$dst|"
    local file="/etc/mkinitcpio.conf"

    log "Set mkinitcpio hooks..."
    cmd "sed -i \"$subst\" $file"
    err "$?" "$FUNCNAME" "failed to set mkinitcpio hooks"
    log "Set mkinitcpio hooks...done"
}

initAlsa()
{
    log "Init alsa..."
    cmd "alsactl init"
    # Alsa can answer with error 99 but work fine
    #err "$?" "$FUNCNAME" "failed to init alsa"
    log "Init alsa...done"
}

unmuteAlsa()
{
    log "Unmute alsa..."
    cmd "amixer sset Master unmute"
    err "$?" "$FUNCNAME" "failed to unmute alsa"
    log "Unmute alsa...done"
}

setPcmModuleLoading()
{
    log "Set snd-pcm-oss module loading..."
    cmd "echo $SND_PCM_OSS_MODULE >> $KERNEL_MODULES_PATH/$SND_PCM_OSS_FILE"
    err "$?" "$FUNCNAME" "failed to set pcm module loading"
    log "Set snd-pcm-oss module loading...done"
}

disablePcSpeaker()
{
    log "Disable pc speaker..."
    cmd "echo \"blacklist $PCSPEAKER_MODULE\" >>"\
        " $MODPROBE_PATH/$NO_PCSPEAKER_FILE"
    err "$?" "$FUNCNAME" "failed to disable pc speaker"
    log "Disable pc speaker...done"
}

#=======================================
# Project repository cloning
#=======================================

cloneProjectRepo()
{
    log "Clone $PROJECT_NAME repo..."
    cmd "git clone $PROJECT_REPO_URL $USER1_HOME/$PROJECT_NAME"
    err "$?" "$FUNCNAME" "failed to clone project repo"
    log "Clone $PROJECT_NAME repo...done"
}

checkoutCurrentBranch()
{
    log "Checkout current branch..."
    # Execute git commands from destination path
    cmd "git -C $USER1_HOME/$PROJECT_NAME checkout $PROJECT_BRANCH"
    err "$?" "$FUNCNAME" "failed to checkout current branch"
    log "Checkout current branch...done"
}

copyOverProjectFiles()
{
    log "Copy over $PROJECT_NAME files..."
    cmd "cp -r $PROJECT_ROOT_PATH $USER1_HOME"
    err "$?" "$FUNCNAME" "failed to copy over project files"
    log "Copy over $PROJECT_NAME files...done"
}

createVariantLink()
{
    local target="$USER1_HOME/$PROJECT_NAME/$VARIANT"
    local name="$USER1_HOME/$PROJECT_NAME/$VARIANT_LINK_NAME"

    log "Create variant link..."
    createLink "$target" "$name"
    err "$?" "$FUNCNAME" "failed to create variant link"
    log "Create variant link...done"
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
    log "Install xorg basics..."
    installPackage $XORG_BASIC_PACKAGES
    log "Install xorg basics...done"
}

installXorgAdditional()
{
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
    log "Install dvtm..."
    installPackage $DVTM_PACKAGES
    log "Install dvtm...done"
}

installCustomizedDvtm()
{
    # Change default blue color to something brighter
    # to make it visible on older CRT monitor
    local src="BLUE"
    local dst="$DVTM_ACTIVE_COLOR"
    local subst="s|$src|$dst|g"
    local file="$DVTM_BUILD_PATH/config.def.h"

    log "Install customized dvtm..."

    cmd "git clone $DVTM_GIT_REPO $DVTM_BUILD_PATH"
    err "$?" "$FUNCNAME" "failed to clone dvtm repo"
    cmd "git -C $DVTM_BUILD_PATH checkout -b $DVTM_CUSTOM_BRANCH"
    err "$?" "$FUNCNAME" "failed to checkout custom dvtm branch"
    cmd "sed -i \"$subst\" $file"
    err "$?" "$FUNCNAME" "failed to change dvtm color"

    # Change default mod key - 'g' is not convenient to be used with CTRL key
    src="#define MOD CTRL('g')"
    dst="#define MOD CTRL('$DVTM_MOD_KEY')"
    subst="s|$src|$dst|g"
    file="$DVTM_BUILD_PATH/config.def.h"

    cmd "sed -i \"$subst\" $file"
    err "$?" "$FUNCNAME" "failed to change dvtm default mod key"
    cmd "git -C $DVTM_BUILD_PATH commit -a -m \"$CUSTOM_COMMIT_COMMENT\""
    err "$?" "$FUNCNAME" "failed to commit changes"
    cmd "make -C $DVTM_BUILD_PATH"
    err "$?" "$FUNCNAME" "failed to make dvtm"
    cmd "make -C $DVTM_BUILD_PATH install"
    err "$?" "$FUNCNAME" "failed to install dvtm"

    log "Install customized dvtm...done"
}

installElinks()
{
    log "Install elinks..."
    installPackage $ELINKS_PACKAGES
    log "Install elinks...done"
}

installCmus()
{
    log "Install cmus..."
    installPackage $CMUS_PACKAGES
    log "Install cmus...done"
}

installJdk()
{
    log "Install jdk..."
    installAurPackage $JDK_AUR_PACKAGES
    log "Install jdk...done"
}

installAndroidEnv()
{
    log "Install android env"
    installAurPackage $ANDROID_ENV_PACKAGES
    # Needed to update sdk manually using 'android' tool
    cmd "chmod -R 755 /opt/android-sdk"
    err "$?" "$FUNCNAME" "failed to change android-sdk file permissions"
    log "Install android env...done"
}

installVirtualboxGuestAdditions()
{
    log "Install virtualbox guest additions..."

    # Install the packages
    installPackage $VIRTUALBOX_GUEST_UTILS_PACKAGES

    # Load required modules
    cmd "modprobe -a $VIRTUALBOX_GUEST_UTILS_MODULES"
    err "$?" "$FUNCNAME" "failed to load virtualbox guest utils modules"

    # Setup modules to be loaded on startup
    if [ ! -z "$VIRTUALBOX_GUEST_UTILS_MODULES" ]; then
        for module in $VIRTUALBOX_GUEST_UTILS_MODULES
        do
            cmd "echo $module >> $VIRTUALBOX_GUEST_UTILS_MODULES_FILE"
            err "$?" "$FUNCNAME" "failed to set modules to be loaded on startup"
        done
    fi

    log "Install virtualbox guest additions...done"
}

#=========
# GUI-based
#=========

installRxvtUnicode()
{
    log "Install rxvt unicode..."
    installPackage $RXVTUNICODE_PACKAGES
    log "Install rxvt unicode...done"
}

installGuiFonts()
{
    log "Install gui fonts..."
    installPackage $GUI_FONT_PACKAGES
    log "Install gui fonts...done"
}

installDwm()
{
    log "Install dwm..."
    installPackage $DWM_PACKAGES
    log "Install dwm...done"
}

installCustomizedDwm()
{
    local patch="$USER1_HOME/$PROJECT_NAME/$VARIANT/$PATCHES_DIR_NAME"
          patch="$patch/$DWM_CUSTOM_PATCH_FILE"

    log "Installing customized dwm..."
    # Clone project from git
    cmd "git clone $DWM_GIT_REPO $DWM_BUILD_PATH"
    err "$?" "$FUNCNAME" "failed to clone dwm repo"
    # Newest commit was not working... use specific, working version
    cmd "git -C $DWM_BUILD_PATH checkout $DWM_BASE_COMMIT -b $DWM_CUSTOM_BRANCH"
    err "$?" "$FUNCNAME" "failed to checkout specific dwm branch"
    # Apply patch with customizations
    cmd "git -C $DWM_BUILD_PATH apply $patch"
    err "$?" "$FUNCNAME" "failed to apply dwm patch"
    # Add changes introduced with patch. Use add . since new files may be added.
    cmd "git -C $DWM_BUILD_PATH add ."
    err "$?" "$FUNCNAME" "failed to add changes introduced with patch"
    # Save configuration as new commit
    cmd "git -C $DWM_BUILD_PATH commit -m \"$CUSTOM_COMMIT_COMMENT\""
    err "$?" "$FUNCNAME" "failed to commit dwm changes"
    # Install
    cmd "make -C $DWM_BUILD_PATH clean install"
    err "$?" "$FUNCNAME" "failed to install dwm"
    log "Installing customized dwm...done"
}

installDmenu()
{
    log "Install dmenu..."
    installPackage $DMENU_PACKAGES
    log "Install dmenu...done"
}

installOpera()
{
    log "Install opera..."
    installPackage $OPERA_PACKAGES
    log "Install opera...done"
}

installConky()
{
    log "Install conky..."
    installPackage $CONKY_PACKAGES
    log "Install conky...done"
}

# To be able to bind special keyboard keys to commands
installXbindkeys()
{
    log "Install xbindkeys..."
    installPackage $XBINDKEYS_PACKAGES
    log "Install xbindkeys...done"
}

# To fix misbehaving Java windows
installWmname()
{
    log "Install wmname..."
    installPackage $WMNAME_PACKAGES
    log "Install wmname...done"
}

installVlc()
{
    log "Install vlc..."
    installPackage $VLC_PACKAGES
    log "Install vlc...done"
}

#===================
# Individual configuration
#===================

setVirtualboxSharedFolder()
{
    log "Set virtualbox shared folder..."
    # Create /media folder
    cmd "mkdir /media"
    err "$?" "$FUNCNAME" "failed to create media folder"
    # Add user1 to vboxsf group
    cmd "gpasswd -a $USER1_NAME vboxsf"
    err "$?" "$FUNCNAME" "failed to add user to vboxsf group"
    # Enable vboxservice service
    enableService "vboxservice"
    # Start vboxservice (needed for link creation)
    startService "vboxservice"
    # Wait a moment for a started service to do its job
    cmd "sleep 5"
    # Create link for easy access
    createLink\
        "/media/sf_$VIRTUALBOX_SHARED_FOLDER_NAME"\
        "$USER1_HOME/$VIRTUALBOX_SHARED_FOLDER_NAME"
    err "$?" "$FUNCNAME" "failed to create shared folder link"
    log "Set virtualbox shared folder...done"
}

setDataPartition()
{
    local mntDir="/mnt/$DATA_PARTITION_DIR_NAME"
    local entry="UUID=$DATA_PARTITION_UUID"
    entry="$entry /mnt/$DATA_PARTITION_DIR_NAME"
    entry="$entry $DATA_PARTITION_TYPE"
    entry="$entry $DATA_PARTITION_MNT_OPTIONS"
    entry="$entry $DATA_PARTITION_DUMP"
    entry="$entry $DATA_PARTITION_PASS"

    log "Set data partition..."
    cmd "echo -e \"\n$entry\" >> $FSTAB_FILE"
    err "$?" "$FUNCNAME" "failed to add entry to fstab"
    createDir "$mntDir"
    err "$?" "$FUNCNAME" "failed to create mount dir"
    createLink "$mntDir" "$USER1_HOME/$DATA_PARTITION_DIR_NAME"
    err "$?" "$FUNCNAME" "failed to create link"
    log "Set data partition...done"
}

#=========
# Dotfiles
#=========

# Bash etc.

installBashprofileDotfile()
{
    log "Install bash_profile dotfile..."
    installDotfile ".bash_profile" ""
    err "$?" "$FUNCNAME" "failed to install bash_profile dotfile"
    log "Install bash_profile dotfile...done"
}

installBashrcDotfile()
{
    log "Install bashrc dotfile..."
    installDotfile ".bashrc" ""
    err "$?" "$FUNCNAME" "failed to install bashrc dotfile"
    log "Install bashrc dotfile...done"
}

installDircolorssolarizedDotfile()
{
    log "Install .dir_colors_solarized dotfile..."
    installDotfile ".dir_colors_solarized" ""
    err "$?" "$FUNCNAME" "failed to install dir_colors_solarized dotfile"
    log "Install .dir_colors_solarized dotfile...done"
}

# vim

installVimrcDotfile()
{
    log "Install vimrc dotfile..."
    installDotfile ".vimrc" ""
    err "$?" "$FUNCNAME" "failed to install vimrc dotfile"
    log "Install vimrc dotfile...done"
}

installVimsolarizedDotfile()
{
    log "Install solarized.vim dotfile..."
    installDotfile "solarized.vim" ".vim/colors"
    err "$?" "$FUNCNAME" "failed to install solarized.vim dotfile"
    log "Install solarized.vim dotfile...done"
}

# mc

installMcsolarizedDotfile()
{
    log "Install mc_solarized.ini dotfile..."
    installDotfile "mc_solarized.ini" ".config/mc"
    err "$?" "$FUNCNAME" "failed to install mc_solarized.ini dotfile"
    log "Install mc_solarized.ini dotfile...done"
}

# git

installGitconfigDotfile()
{
    log "Install .gitconfig dotfile..."
    installDotfile ".gitconfig" ""
    err "$?" "$FUNCNAME" "failed to install gitconfig dotfile"
    log "Install .gitconfig dotfile...done"
}

# cmus

installCmusColorThemeDotfile()
{
    log "Install cmus color theme dotfile..."
    installDotfile "solarized.theme" ".cmus"
    err "$?" "$FUNCNAME" "failed to install cmus color theme dotfile"
    log "Install cmus color theme dotfile...done"
}

# X

installXinitrcDotfile()
{
    log "Install .xinitrc dotfile..."
    installDotfile ".xinitrc" ""
    err "$?" "$FUNCNAME" "failed to install xinitrc dotfile"
    log "Install .xinitrc dotfile...done"
}

installXresourcesDotfile()
{
    log "Install .Xresources dotfile..."
    installDotfile ".Xresources" ""
    err "$?" "$FUNCNAME" "failed to install Xresources dotfile"
    log "Install .Xresources dotfile...done"
}

installConkyDotfile()
{
    log "Install .conkyrc dotfile..."
    installDotfile ".conkyrc" ""
    err "$?" "$FUNCNAME" "failed to install conkyrc dotfile"
    log "Install .conkyrc dotfile...done"
}

installXbindkeysDotfile()
{
    log "Install .xbindkeysrc dotfile..."
    installDotfile ".xbindkeysrc" ""
    err "$?" "$FUNCNAME" "failed to install xbindkeys dotfile"
    log "Install .xbindkeysrc dotfile...done"
}

#===================
# Other
#===================

recreateImage()
{
    log "Recreate linux image..."
    cmd "mkinitcpio -p $KERNEL_VERSION"
    err "$?" "$FUNCNAME" "failed to recreate image"
    log "Recreate linux image...done"
}

changeUser1HomeOwnership()
{
    log "Change user1 home ownership..."
    changeHomeOwnership "$USER1_NAME" "$USER1_HOME"
    log "Change user1 home ownership...done"
}

#=======================================
# Post setup actions
#=======================================

copyProjectLogFiles()
{
    # Do not perform typical logging in this function...
    # This would spoil nice logs copied to user's dir

    cp -r $LOG_DIR $USER1_HOME/$PROJECT_NAME/$VARIANT
}

