#!/bin/bash

echo installation.sh

# Note: rankMirrors takes longer time but might provide faster servers than downloadMirrorList
rankMirrors()
{
    requiresVariable "MIRROR_LIST_FILE" "$FUNCNAME"
    requiresVariable "MIRROR_LIST_FILE_BACKUP" "$FUNCNAME"
    requiresVariable "MIRROR_COUNT" "$FUNCNAME"

    log "Rank mirrors..."

    # Backup original file
    executeCommand "cp $MIRROR_LIST_FILE $MIRROR_LIST_FILE_BACKUP"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to rank mirrors"

    executeCommand "rankmirrors -n $MIRROR_COUNT $MIRROR_LIST_FILE_BACKUP > $MIRROR_LIST_FILE"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to rank mirrors"

    log "Rank mirrors...done"
}

# Note: downloadMirrorList is faster than rankMirrors but might give slower servers
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

    executeCommand "pacstrap -i $ROOT_PARTITION_MOUNT_POINT $BASE_SYSTEM_PACKAGES"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install base system"

    log "Install base system...done"
}

generateFstab()
{
    requiresVariable "ROOT_PARTITION_MOUNT_POINT" "$FUNCNAME"

    log "Generate fstab..."

    executeCommand "genfstab -L -p $ROOT_PARTITION_MOUNT_POINT >> $ROOT_PARTITION_MOUNT_POINT/etc/fstab"
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

setLocale()
{
    if [[ $# -lt 1 ]]; then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        terminateScriptOnError "1" "$FUNCNAME" "failed to set locale"
    fi

    log "Set locale for  $1..."

    archChroot "sed -i \\\"s/^#\\\\\(${1}.*\\\\\)$/\\\\\1/\\\" /etc/locale.gen"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to set locale"

    log "Set locale for $1...done"
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

    # TODO: This was causing additional output to be shown and changed console screen to green...
    # TODO: Probably this is not needed
    #archChroot "export LANG=$LOCALIZATION_LANGUAGE_EN"
    #terminateScriptOnError "$?" "$FUNCNAME" "failed to set language"

    log "Set language...done"
}

setTimeZone()
{
    requiresVariable "LOCALIZATION_TIME_ZONE" "$FUNCNAME"

    log "Set time zone..."

    archChroot "ln -s /usr/share/zoneinfo/$LOCALIZATION_TIME_ZONE /etc/localtime"
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

    archChroot "systemctl enable $NETWORK_SERVICE@$NETWORK_INTERFACE_WIRED.service"
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
    requiresVariable "BOOT_PARTITION_HDD" "$FUNCNAME"
    requiresVariable "BOOT_PARTITION_NB" "$FUNCNAME"

    log "Configure syslinux..."

    archChroot "syslinux-install_update -i -a -m"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to update syslinux"

    archChroot "sed -i \"s/sda3/$BOOT_PARTITION_HDD$BOOT_PARTITION_NB/g\" /boot/syslinux/syslinux.cfg"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to change partition name in syslinux"

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

