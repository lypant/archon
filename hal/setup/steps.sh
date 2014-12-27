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
# Preparations
#---------------------------------------

setTemporaryFont()
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

#---------------------------------------
# Disks, partitions and file systems
#---------------------------------------

SYSTEM_HDD="sdc"

checkInitialPartitions()
{
    local hdd="/dev/$SYSTEM_HDD"

    log "Check initial partitions..."
    checkPartitionsCount $hdd 0
    err "$?" "$FUNCNAME" "Disk $hdd does not have expected partitions count"
    log "Check initial partitions...done"
}

createSwapPartition()
{
    log "Create swap partition..."
    createPartition /dev/$SYSTEM_HDD p 1 +8G 82
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

createSwap()
{
    log "Create swap..."
    cmd "mkswap /dev/${SYSTEM_HDD}1"
    err "$?" "$FUNCNAME" "failed to create swap"
    log "Create swap...done"
}

activateSwap()
{
    log "Activate swap..."
    cmd "swapon /dev/${SYSTEM_HDD}1"
    err "$?" "$FUNCNAME" "failed to activate swap"
    log "Activate swap...done"
}

createBootFileSystem()
{
    log "Create boot file system..."
    cmd "mkfs.ext2 /dev/${SYSTEM_HDD}2"
    err "$?" "$FUNCNAME" "failed to create boot file system"
    log "Create boot file system...done"
}

createRootFileSystem()
{
    log "Create root file system..."
    cmd "mkfs.ext4 /dev/${SYSTEM_HDD}3"
    err "$?" "$FUNCNAME" "failed to create root file system"
    log "Create root file system...done"
}

mountRootPartition()
{
    log "Mount root partition..."
    cmd "mount /dev/${SYSTEM_HDD}3 /mnt"
    err "$?" "$FUNCNAME" "failed to mount root partition"
    log "Mount root partition...done"
}

mountBootPartition()
{
    log "Mount boot partition..."
    cmd "mkdir /mnt/boot"
    err "$?" "$FUNCNAME" "failed to create boot partition mount point"
    cmd "mount /dev/${SYSTEM_HDD}2 /mnt/boot"
    err "$?" "$FUNCNAME" "failed to mount boot partition"
    log "Mount boot partition...done"
}

#---------------------------------------
# Base system installation
#---------------------------------------

# Note: rankMirrors takes longer time but
# might provide faster servers than downloadMirrorList
rankMirrors()
{
    local file="/etc/pacman.d/mirrorlist"
    local bkp="$file.bkp"

    log "Rank mirrors..."
    # Backup original file
    cmd "cp $file $bkp"
    err "$?" "$FUNCNAME" "failed to backup mirrors file"
    cmd "rankmirrors -n 5 $bkp > $file"
    err "$?" "$FUNCNAME" "failed to rank mirrors"
    log "Rank mirrors...done"
}

# Note: downloadMirrorList is faster than rankMirrors but
# might give slower servers
downloadMirrorList()
{
    local file="/etc/pacman.d/mirrorlist"
    local bkp="$file.bkp"
    local url="https://www.archlinux.org/mirrorlist/?country=PL"

    log "Download mirror list..."
    # Backup original file
    cmd "cp $file $bkp"
    err "$?" "$FUNCNAME" "failed to backup mirrors file"
    downloadFile $url $file
    uncommentVar "Server" $file
    log "Download mirror list...done"
}

installBaseSystem()
{
    log "Install base system..."
    cmd "pacstrap -i /mnt base base-devel"
    err "$?" "$FUNCNAME" "failed to install base system"
    log "Install base system...done"
}

#---------------------------------------
# Base system configuration
#---------------------------------------

generateFstab()
{
    log "Generate fstab..."
    cmd "genfstab -L -p /mnt >> /mnt/etc/fstab"
    err "$?" "$FUNCNAME" "failed to generate fstab"
    log "Generate fstab...done"
}

setHostName()
{
    log "Set host name..."
    archChroot "echo $VARIANT > /etc/hostname"
    err "$?" "$FUNCNAME" "failed to set host name"
    log "Set host name...done"
}

#---------------------------------------
# Localization
#---------------------------------------

setLocales()
{
    log "Set locales..."
    setLocale "en_US.UTF-8"
    setLocale "pl_PL.UTF-8"
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
    archChroot "echo LANG=en_US.UTF-8 >> /etc/locale.conf"
    err "$?" "$FUNCNAME" "failed to set language"
    log "Set language...done"
}

setLocalizationCtype()
{
    log "Set localization ctype..."
    archChroot "echo LC_CTYPE=pl_PL.UTF-8 >> /etc/locale.conf"
    err "$?" "$FUNCNAME" "failed to set localization ctype"
    log "Set localization ctype...done"
}

setLocalizationNumeric()
{
    log "Set localization numeric..."
    archChroot "echo LC_NUMERIC=pl_PL.UTF-8 >> /etc/locale.conf"
    err "$?" "$FUNCNAME" "failed to set localization numeric"
    log "Set localization numeric...done"
}

setLocalizationTime()
{
    log "Set localization time..."
    archChroot "echo LC_TIME=pl_PL.UTF-8 >> /etc/locale.conf"
    err "$?" "$FUNCNAME" "failed to set localization time"
    log "Set localization time...done"
}

setLocalizationCollate()
{
    log "Set localization collate..."
    archChroot "echo LC_COLLATE=C >> /etc/locale.conf"
    err "$?" "$FUNCNAME" "failed to set localization collate"
    log "Set localization collate...done"
}

setLocalizationMonetary()
{
    log "Set localization monetary..."
    archChroot "echo LC_MONETARY=pl_PL.UTF-8 >> /etc/locale.conf"
    err "$?" "$FUNCNAME" "failed to set localization monetary"
    log "Set localization monetary...done"
}

setLocalizationMeasurement()
{
    log "Set localization measurenent..."
    archChroot "echo LC_MEASUREMENT=pl_PL.UTF-8 >> /etc/locale.conf"
    err "$?" "$FUNCNAME" "failed to set localization measurement"
    log "Set localization measurement...done"
}

#---------------------------------------
# Time
#---------------------------------------

setTimeZone()
{
    log "Set time zone..."
    archChroot "ln -s /usr/share/zoneinfo/Europe/Warsaw /etc/localtime"
    err "$?" "$FUNCNAME" "failed to set time zone"
    log "Set time zone...done"
}

setHardwareClock()
{
    log "Set hardware clock..."
    archChroot "hwclock --systohc --utc"
    err "$?" "$FUNCNAME" "failed to set hardware clock"
    log "Set hardware clock...done"
}

#---------------------------------------
# Console
#---------------------------------------

setConsoleKeymap()
{
    log "Set console keymap..."
    archChroot "echo KEYMAP=pl > /etc/vconsole.conf"
    err "$?" "$FUNCNAME" "failed to set console keymap"
    log "Set console keymap...done"
}

setConsoleFont()
{
    log "Set console font..."
    archChroot "echo FONT=Lat2-Terminus16 >> /etc/vconsole.conf"
    err "$?" "$FUNCNAME" "failed to set console font"
    log "Set console font...done"
}

setConsoleFontmap()
{
    log "Set console fontmap..."
    archChroot "echo FONT_MAP=8859-2 >> /etc/vconsole.conf"
    err "$?" "$FUNCNAME" "failed to set console fontmap"
    log "Set console fontmap...done"
}

#---------------------------------------
# Network
#---------------------------------------

setWiredNetwork()
{
    log "Set wired network..."
    archChroot "systemctl enable dhcpcd@enp4s0.service"
    #archChroot "systemctl enable dhcpcd@enp0s3.service"
    err "$?" "$FUNCNAME" "failed to set wired network"
    log "Set wired network...done"
}

#---------------------------------------
# Bootloader
#---------------------------------------

installBootloader()
{
    log "Install bootloader..."
    archChroot "pacman -S syslinux --noconfirm"
    err "$?" "$FUNCNAME" "failed to install bootloader"
    log "Install bootloader...done"
}

configureBootloader()
{
    local src="sda3"
    local dst="sdc3"
    local subst="s|$src|$dst|g"
    local file="/boot/syslinux/syslinux.cfg"
    local cnt=0

    log "Configure bootloader..."
    archChroot "syslinux-install_update -i -a -m"
    err "$?" "$FUNCNAME" "failed to update syslinux"

    archChroot "sed -i \\\"$subst\\\" $file"
    err "$?" "$FUNCNAME" "failed to replace parition path"
    log "Configure bootloader...done"
}

#---------------------------------------
# Root account
#---------------------------------------

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

#---------------------------------------
# Additional steps
#---------------------------------------

# TODO: Move this step to customization script???
setTmpfsTmpSize()
{
    # Size of /tmp partition - e.g. RAM size + SWAP size
    log "Set tmpfs tmp size..."
    cmd "echo \"tmpfs /tmp tmpfs size=16G,rw 0 0\" >> /mnt/etc/fstab"
    err "$?" "$FUNCNAME" "failed to set tmpfs tmp size"
    log "Set tmpfs tmp size...done"
}

#---------------------------------------
# Post-install steps
#---------------------------------------

copyProjectFiles()
{
    # Do not perform typical logging in this function...
    # This would spoil nice logs copied to new system
    mkdir -p /mnt/root/archon
    cp -R /root/archon/* /mnt/root/archon

    # This is only for livecd output and logs consistency
    log "Copy project files..."
    log "Copy project files...done"
}

unmountPartitions()
{
    log "Unmount partitions..."
    cmd "umount -R /mnt"
    err "$?" "$FUNCNAME" "failed to unmount partitions"
    log "Unmount partitions...done"
}

#-------------------------------------------------------------------------------
# Customization
#-------------------------------------------------------------------------------

#---------------------------------------
# Preparation steps
#---------------------------------------

configurePacman()
{
    log "Configure pacman..."
    # Present total download percentage instead of single package percentage
    uncommentVar "TotalDownload" "/etc/pacman.conf"
    log "Configure pacman...done"
}

#---------------------------------------
# User account
#---------------------------------------

addUser()
{
    log "Add user..."
    cmd "useradd -m -g users -G wheel,storage,power -s /bin/bash adam"
    log "Add user...done"
}

setUserPassword()
{
    local ask=1

    log "Set user password..."

    while [ $ask -ne 0 ]; do
        log "Provide password for user adam"
        cmd "passwd adam"
        ask=$?
    done

    log "Set user password...done"
}

setSudoRights()
{
    log "Set sudo rights..."
    cmd "echo \"adam ALL=(ALL) ALL\" >> /etc/sudoers"
    err "$?" "$FUNCNAME" "failed to set sudoer"
    log "Set sudo rights...done"
}

#---------------------------------------
# Git and archon files
#---------------------------------------

installGit()
{
    log "Install git..."
    installPackage git
    log "Install git...done"
}

configureGitUser()
{
    log "Configure git user..."
    cmd "git config --global user.email \"lypant@tlen.pl\""
    err "$?" "$FUNCNAME" "failed to set git user email"
    cmd "git config --global user.name \"lypant\""
    err "$?" "$FUNCNAME" "failed to set git user name"
    log "Configure git user...done"
}

cloneArchonRepo()
{
    log "Clone archon repo..."
    cmd "git clone https://github.com/lypant/archon /home/adam/archon"
    err "$?" "$FUNCNAME" "failed to clone project repo"
    log "Clone archon repo...done"
}

checkoutCurrentBranch()
{
    log "Checkout current branch..."
    # Execute git commands from destination path
    cmd "git -C /home/adam/archon checkout kiss"
    err "$?" "$FUNCNAME" "failed to checkout current branch"
    log "Checkout current branch...done"
}

copyOverArchonFiles()
{
    log "Copy over archon files..."
    cmd "cp -r /root/archon /home/adam"
    err "$?" "$FUNCNAME" "failed to copy over project files"
    log "Copy over archon files...done"
}

createVariantLink()
{
    log "Create variant link..."
    createLink "/home/adam/archon/$VARIANT" "/home/adam/archon/variant"
    err "$?" "$FUNCNAME" "failed to create variant link"
    log "Create variant link...done"
}

#---------------------------------------
# Console programs
#---------------------------------------

#-------------------
# vim
#-------------------

installVim()
{
    log "Install vim..."
    installPackage vim
    log "Install vim...done"
}

installPathogen()
{
    log "Install pathogen..."
    createDir "/home/adam/.vim/autoload"
    createDir "/home/adam/.vim/bundle"
    downloadFile "https://tpo.pe/pathogen.vim"\
        "/home/adam/.vim/autoload/pathogen.vim"
    log "Install pathogen...done"
}

installNerdTree()
{
    log "Install nerdtree..."
    cmd "git -C /home/adam/.vim/bundle"\
        "clone https://github.com/scrooloose/nerdtree.git"
    log "Install nerdtree...done"
}

installNerdCommenter()
{
    log "Install nerdcommenter..."
    cmd "git -C /home/adam/.vim/bundle"\
        "clone https://github.com/scrooloose/nerdcommenter.git"
    log "Install nerdcommenter...done"
}

installTagbar()
{
    log "Install tagbar..."
    cmd "git -C /home/adam/.vim/bundle"\
        "clone https://github.com/majutsushi/tagbar.git"
    log "Install tagbar...done"
}

installCtags()
{
    log "Install ctags..."
    installPackage ctags
    log "Install ctags...done"
}

installMc()
{
    log "Install mc..."
    installPackage mc
    log "Install mc...done"
}

installTmux()
{
    log "Install tmux..."
    installPackage tmux
    log "Install tmux...done"
}

#---------------------------------------
# Sound
#---------------------------------------

installAlsa()
{
    log "Install alsa..."
    installPackage alsa-utils
    log "Install alsa...done"
}

initAlsa()
{
    local ret=0

    log "Init alsa..."
    cmd "alsactl init"
    ret="$?"
    # Alsa can answer with error 99 but work fine
    if [[ "$ret" -eq 99 ]]; then
        log "alsactl init returned error code 99; accepting it as 0"
        ret=0
    fi
    err "$ret" "$FUNCNAME" "failed to init alsa"
    log "Init alsa...done"

}

# Deprecated - not needed on HAL HW nor on VM
#unmuteAlsa()
#{
#    log "Unmute alsa..."
#    cmd "amixer sset Master unmute"
#    err "$?" "$FUNCNAME" "failed to unmute alsa"
#    log "Unmute alsa...done"
#}

installCmus()
{
    log "Install cmus..."
    installPackage cmus libmad
    log "Install cmus...done"
}


#---------------------------------------
# Dotfiles
#---------------------------------------

installBashprofileDotfile()
{
    log "Install .bash_profile dotfile..."
    installDotfile ".bash_profile" ""
    err "$?" "$FUNCNAME" "failed to install .bash_profile dotfile"
    log "Install .bash_profile dotfile...done"
}


installBashrcDotfile()
{
    log "Install .bashrc dotfile..."
    installDotfile ".bashrc" ""
    err "$?" "$FUNCNAME" "failed to install .bashrc dotfile"
    log "Install .bashrc dotfile...done"
}

installDirColorsSolarizedDotfile()
{
    log "Install .dir_colors_solarized dotfile..."
    installDotfile ".dir_colors_solarized" ""
    err "$?" "$FUNCNAME" "failed to install dir_colors_solarized dotfile"
    log "Install .dir_colors_solarized dotfile...done"
}

installVimrcDotfile()
{
    log "Install .vimrc dotfile..."
    installDotfile ".vimrc" ""
    err "$?" "$FUNCNAME" "failed to install .vimrc dotfile"
    log "Install .vimrc dotfile...done"
}

installVimSolarizedDotfile()
{
    log "Install solarized.vim dotfile..."
    installDotfile "solarized.vim" ".vim/bundle/solarized/colors"
    err "$?" "$FUNCNAME" "failed to install solarized.vim dotfile"
    log "Install solarized.vim dotfile...done"
}

installMcSolarizedDotfile()
{
    log "Install mc_solarized.ini dotfile..."
    installDotfile "mc_solarized.ini" ".config/mc"
    err "$?" "$FUNCNAME" "failed to install mc_solarized.ini dotfile"
    log "Install mc_solarized.ini dotfile...done"
}

#---------------------------------------
# Final steps
#---------------------------------------

changeHomeOwnership()
{
    log "Change home dir ownership..."
    cmd "chown -R adam:users /home/adam"
    log "Change home dir ownership...done"
}

copyProjectLogFiles()
{
    cp -r ../logs /home/adam/archon/$VARIANT
}

