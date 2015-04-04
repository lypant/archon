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
set -o nounset -o errexit

# Include functions definitions
source functions.sh

#-------------------------------------------------------------------------------
# Configuration variables
#-------------------------------------------------------------------------------

#---------------------------------------
# System HDD
#---------------------------------------
SYSTEM_HDD="sdb"

#-------------------
# Swap partition
#-------------------
SWAP_PART_NB="1"
SWAP_PART_SIZE="+16G"

#-------------------
# Boot partition
#-------------------
BOOT_PART_NB="2"
BOOT_PART_SIZE="+512M"
BOOT_PART_FS="ext2"

#-------------------
# Root partition
#-------------------
ROOT_PART_NB="3"
ROOT_PART_SIZE=""
ROOT_PART_FS="ext4"

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
    createPartition /dev/$SYSTEM_HDD p $SWAP_PART_NB "$SWAP_PART_SIZE" 82
    log "Create swap partition...done"
}

createBootPartition()
{
    log "Create boot partition..."
    createPartition /dev/$SYSTEM_HDD p $BOOT_PART_NB "$BOOT_PART_SIZE" 83
    log "Create boot partition...done"
}

createRootPartition()
{
    log "Create root partition..."
    createPartition /dev/$SYSTEM_HDD p $ROOT_PART_NB "$ROOT_PART_SIZE" 83
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
    setPartitionBootable /dev/$SYSTEM_HDD $BOOT_PART_NB
    log "Set boot partition bootable...done"
}

createSwap()
{
    log "Create swap..."
    cmd "mkswap /dev/$SYSTEM_HDD$SWAP_PART_NB"
    err "$?" "$FUNCNAME" "failed to create swap"
    log "Create swap...done"
}

activateSwap()
{
    log "Activate swap..."
    cmd "swapon /dev/$SYSTEM_HDD$SWAP_PART_NB"
    err "$?" "$FUNCNAME" "failed to activate swap"
    log "Activate swap...done"
}

createBootFileSystem()
{
    log "Create boot file system..."
    cmd "mkfs.$BOOT_PART_FS /dev/$SYSTEM_HDD$BOOT_PART_NB"
    err "$?" "$FUNCNAME" "failed to create boot file system"
    log "Create boot file system...done"
}

createRootFileSystem()
{
    log "Create root file system..."
    cmd "mkfs.$ROOT_PART_FS /dev/$SYSTEM_HDD$ROOT_PART_NB"
    err "$?" "$FUNCNAME" "failed to create root file system"
    log "Create root file system...done"
}

mountRootPartition()
{
    log "Mount root partition..."
    cmd "mount /dev/$SYSTEM_HDD$ROOT_PART_NB /mnt"
    err "$?" "$FUNCNAME" "failed to mount root partition"
    log "Mount root partition...done"
}

mountBootPartition()
{
    log "Mount boot partition..."
    cmd "mkdir /mnt/boot"
    err "$?" "$FUNCNAME" "failed to create boot partition mount point"
    cmd "mount /dev/$SYSTEM_HDD$BOOT_PART_NB /mnt/boot"
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
    archChroot "echo hal > /etc/hostname"
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

# TODO: Remove when not needed
#       Problem was observed during syslinux installation:
#       error: failed to initialize alpm library
#       (database is incorrect version: /var/lib/pacman)
#       error: try running pacman-db-upgrade
tempAlpmWorkaround()
{
    log "Temp alpm workaround..."
    archChroot "pacman-db-upgrade"
    log "Temp alpm workaround...done"
}

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
    local dst="$SYSTEM_HDD$ROOT_PART_NB"
    local subst="s|$src|$dst|g"
    local file="/boot/syslinux/syslinux.cfg"

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

    # Disable exit on error - to get a chance of correcting misspelled password
    set +o errexit
    while [ $ASK -ne 0 ]; do
        archChroot "passwd"
        ASK=$?
    done
    # Enable exiting on error again
    set -o errexit

    log "Set root password...done"
}

#---------------------------------------
# Additional steps
#---------------------------------------

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
# Preparations
#---------------------------------------

# Use repository for multilib support - to allow 32B apps on 64B system
# Needed for Android development
setMultilibRepository()
{
    log "Set multilib repository..."
    cmd "sed -i '/\[multilib\]/,/Include/ s|^#\(.*\)|\1|' /etc/pacman.conf"
    err "$?" "$FUNCNAME" "failed to set multilib repository"
    log "Set multilib repository...done"
}

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

    # Disable exit on error - to get a chance of correcting misspelled password
    set +o errexit
    while [ $ask -ne 0 ]; do
        log "Provide password for user adam"
        cmd "passwd adam"
        ask=$?
    done
    # Enable exiting on error again
    set -o errexit

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

#--------------------------------------
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

#--------------------------------------
# GUI programs
#---------------------------------------

#-------------------
# Xorg
#-------------------

installXorg()
{
    log "Install Xorg..."
    installPackage "xorg-server xorg-server-utils xorg-xinit"
    log "Install Xorg...done"
}

removeMesaLibgl()
{
    log "Remove mesa-libgl..."
    removePackage "mesa-libgl"
    log "Remove mesa-libgl...done"
}

#-------------------
# Video driver
#-------------------

installVideoDriver()
{
    log "Install video driver..."
    installPackage "xf86-video-nouveau"
    log "Install video driver...done"
}

#-------------------
# Fonts
#-------------------

installGuiFonts()
{
    log "Install gui fonts..."
    installPackage "ttf-inconsolata ttf-dejavu terminus-font"
    log "Install gui fonts...done"
}

#-------------------
# Config
#-------------------

# To be able to bind special keyboard keys to commands
installXbindkeys()
{
    log "Install xbindkeys..."
    installPackage "xbindkeys"
    log "Install xbindkeys...done"
}

installConky()
{
    log "Install conky..."
    installPackage "conky"
    log "Install conky...done"
}

#-------------------
# Programs
#-------------------

installCustomizedDwm()
{
    local patch="/home/adam/archon/hal/patches/dwm_cdec978.diff"
    local build_path="/home/adam/forge/dwm"
    local comment="Adjustments done during archon installation"

    log "Installing customized dwm..."
    # Clone project from git
    cmd "git clone http://git.suckless.org/dwm $build_path"
    err "$?" "$FUNCNAME" "failed to clone dwm repo"
    # Newest commit was not working... use specific, working version
    cmd "git -C $build_path checkout cdec978 -b dwm_archon"
    err "$?" "$FUNCNAME" "failed to checkout specific dwm branch"
    # Apply patch with customizations
    cmd "git -C $build_path apply $patch"
    err "$?" "$FUNCNAME" "failed to apply dwm patch"
    # Add changes introduced with patch. Use add . since new files may be added.
    cmd "git -C $build_path add ."
    err "$?" "$FUNCNAME" "failed to add changes introduced with patch"
    # Save configuration as new commit
    cmd "git -C $build_path commit -m \"$comment\""
    err "$?" "$FUNCNAME" "failed to commit dwm changes"
    # Install
    cmd "make -C $build_path clean install"
    err "$?" "$FUNCNAME" "failed to install dwm"
    log "Installing customized dwm...done"
}

installDmenu()
{
    log "Install dmenu..."
    installPackage "dmenu"
    log "Install dmenu...done"
}

installRxvtUnicode()
{
    # Note: rxvt-unicode can be launched with command urxvt
    log "Install rxvt unicode..."
    installPackage "rxvt-unicode"
    log "Install rxvt unicode...done"
}

installFirefox()
{
    log "Install firefox..."
    installPackage "firefox"
    log "Install firefox...done"
}

installFlashplugin()
{
    log "Install flashplugin..."
    installPackage "flashplugin"
    log "Install flashplugin...done"
}

installThunderbird()
{
    log "Install thunderbird..."
    installPackage "thunderbird"
    log "Install thunderbird...done"
}

installVlc()
{
    log "Install vlc..."
    # TODO: Check whether libcddb is necessary
    #installPackage "vlc libcddb"
    installPackage "vlc"
    log "Install vlc...done"
}

installFeh()
{
    log "Install feh..."
    installPackage "feh"
    log "Install feh...done"
}

installEvince()
{
    log "Install evince..."
    installPackage "evince"
    log "Install evince...done"
}

# TODO: Craete another paragraph with modules used as fixes/workaronds etc?
# To fix misbehaving Java windows
installWmname()
{
    log "Install wmname..."
    installPackage "wmname"
    log "Install wmname...done"
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

disablePcSpeaker()
{
    log "Disable pc speaker..."
    cmd "echo \"blacklist pcspkr\" >> /etc/modprobe.d/no_pcspeaker.conf"
    err "$?" "$FUNCNAME" "failed to disable pc speaker"
    log "Disable pc speaker...done"
}

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

installGitconfigDotfile()
{
    log "Install .gitconfig dotfile..."
    installDotfile ".gitconfig" ""
    err "$?" "$FUNCNAME" "failed to install gitconfig dotfile"
    log "Install .gitconfig dotfile...done"
}

installCmusColorThemeDotfile()
{
    log "Install cmus solarized.theme dotfile..."
    installDotfile "solarized.theme" ".cmus"
    err "$?" "$FUNCNAME" "failed to install cmus color theme dotfile"
    log "Install cmus solarized.theme dotfile...done"
}

installTmuxConfDotfile()
{
    log "Install .tmux.conf dotfile..."
    installDotfile ".tmux.conf" ""
    err "$?" "$FUNCNAME" "failed to install .tmux.conf dotfile"
    log "Install .tmux.conf dotfile...done"
}

installXinitrcDotfile()
{
    log "Install .xinitrc dotfile..."
    installDotfile ".xinitrc" ""
    err "$?" "$FUNCNAME" "failed to install .xinitrc dotfile"
    log "Install .xinitrc dotfile...done"
}

installXresourcesDotfile()
{
    log "Install .Xresources dotfile..."
    installDotfile ".Xresources" ""
    err "$?" "$FUNCNAME" "failed to install .Xresources dotfile"
    log "Install .Xresources dotfile...done"
}

installXbindkeysrcDotfile()
{
    log "Install .xbindkeysrc dotfile..."
    installDotfile ".xbindkeysrc" ""
    err "$?" "$FUNCNAME" "failed to install .xbindkeys dotfile"
    log "Install .xbindkeysrc dotfile...done"
}

installConkyDotfile()
{
    log "Install .conkyrc dotfile..."
    installDotfile ".conkyrc" ""
    err "$?" "$FUNCNAME" "failed to install .conkyrc dotfile"
    log "Install .conkyrc dotfile...done"
}

#---------------------------------------
# Boot process configuration
#---------------------------------------

setBootloaderKernelParams()
{
    local params=""
    params="$params root=/dev/$SYSTEM_HDD$ROOT_PART_NB"
    params="$params rw"
    params="$params vga=0x0369"
    params="$params quiet"
    params="$params loglevel=0"
    params="$params rd.udev.log-priority=3"
    local src="APPEND root.*$"
    local dst="APPEND $params"
    local subst="s|$src|$dst|"
    local file="/boot/syslinux/syslinux.cfg"

    log "Set bootloader kernel params..."
    cmd "sed -i \"$subst\" $file"
    err "$?" "$FUNCNAME" "failed to set bootloader kernel params"
    log "Set bootloader kernel params...done"
}

hideSysctlConsoleMessages()
{
    log "Hide sysctl console messages..."
    cmd "echo 'kernel.printk = 3 3 3 3' >> '/etc/sysctl.d/20-quiet-printk.conf'"
    log "Hide sysctl console messages...done"
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
    # Clear screen on login
    cmd "clear > /etc/issue"
    log "Set console login message...done"
}

setLastLoginMessage()
{
    log "Set last login message..."
    # Do not display last login message
    cmd "touch /home/adam/.hushlogin"
    log "Set last login message...done"
}

# This requires image recreation for changes to take effect
setMkinitcpioHooks()
{
    local hooks="base udev autodetect modconf block filesystems keyboard"
    local src="^HOOKS.*$"
    local dst="HOOKS=\\\"$hooks\\\""
    local subst="s|$src|$dst|"
    local file="/etc/mkinitcpio.conf"

    log "Set mkinitcpio hooks..."
    cmd "sed -i \"$subst\" $file"
    err "$?" "$FUNCNAME" "failed to set mkinitcpio hooks"
    log "Set mkinitcpio hooks...done"
}

# This requires image recreation for changes to take effect
setMkinitcpioModules()
{
    # TODO: Verify modules after adding GUI and graphics driver
    local modules="nouveau"
    local src="^MODULES.*$"
    local dst="MODULES=\\\"$modules\\\""
    local subst="s|$src|$dst|"
    local file="/etc/mkinitcpio.conf"

    log "Set mkinitcpio modules..."
    cmd "sed -i \"$subst\" $file"
    err "$?" "$FUNCNAME" "failed to set mkinitcpio modules"
    log "Set mkinitcpio modules...done"
}

setBootConsoleOutputLevels()
{
    local srcPath="/usr/lib/systemd/system"
    local dstPath="/etc/systemd/system"
    local file1="systemd-fsck-root.service"
    local file2="systemd-fsck@.service"

    log "Set boot console output levels..."
    cmd "cp $srcPath/$file1 $dstPath"
    cmd "cp $srcPath/$file2 $dstPath"
    changeOutputLevels "$dstPath/$file1"
    changeOutputLevels "$dstPath/$file2"
    log "Set boot console output levels...done"
}

#---------------------------------------
# Partitions and file systems
#---------------------------------------

# Has to be done before AUR packages installation phase
# to allow larga AUR packages installation
# OOM problems were observed on VirtualBox installations without this.
setTmpfsTmpSize()
{
    # Size of /tmp partition - e.g. RAM size + SWAP size
    log "Set tmpfs tmp size..."
    cmd "echo \"tmpfs /tmp tmpfs size=16G,rw 0 0\" >> /etc/fstab"
    err "$?" "$FUNCNAME" "failed to set tmpfs tmp size"
    log "Set tmpfs tmp size...done"
}

setDataPartition()
{
    local mntDir="/mnt/data"
    local entry="LABEL=Data"
    entry="$entry /mnt/data"
    entry="$entry ext4"
    entry="$entry auto,nouser,noexec,ro"
    entry="$entry 0"    # dump backup utility: 0 - don't, 1 - do backup
    entry="$entry 2"    # fsck: 0- don't check, 1- highiest prio, 2- other prio

    log "Set data partition..."
    cmd "echo -e \"\n$entry\" >> /etc/fstab"
    err "$?" "$FUNCNAME" "failed to add entry to fstab"
    createDir "$mntDir"
    err "$?" "$FUNCNAME" "failed to create mount dir"
    createLink "$mntDir" "/home/adam/Data"
    err "$?" "$FUNCNAME" "failed to create link"
    log "Set data partition...done"
}

#-------------------
# SSD adjustments
#-------------------

setRootPartitionTrim()
{
    local old="rw,relatime,data=ordered"
    local new="rw,relatime,data=ordered,discard"
    local subst="s|$old|$new|g"
    local file="/etc/fstab"

    log "Set root partition TRIM..."
    cmd "sed -i \"$subst\" $file"
    log "Set root partition TRIM...done"
}

setIoScheduler()
{
    local file="/etc/udev/rules.d/60-schedulers.rules"
    local line='ACTION==\"add|change\", KERNEL==\"sd[a-z]\",'
    line=$line' ATTR{queue/rotational}==\"0\", ATTR{queue/scheduler}=\"noop\"'

    log "Set IO scheduler..."
    cmd "echo \"$line\" >> $file"
    log "Set IO scheduler...done"
}

setSwappiness()
{
    local file="/etc/sysctl.d/99-sysctl.conf"
    # 0-swap only to avoid OOM; 60-default; 100-max, aggresive swapping
    local line="vm.swappiness=1"

    log "Set swappiness..."
    cmd "echo $line >> $file"
    log "Set swappiness...done"
}

# Compile in tmpfs
setMakepkgBuilddir()
{
    local variable="BUILDDIR"
    local file="/etc/makepkg.conf"

    log "Set makepkg builddir..."
    uncommentVar $variable $file
    log "Set makepkg builddir...done"
}

#---------------------------------------
# Final steps
#---------------------------------------

recreateImage()
{
    log "Recreate image..."
    cmd "mkinitcpio -p linux"
    err "$?" "$FUNCNAME" "failed to recreate image"
    log "Recreate image...done"
}

changeHomeOwnership()
{
    log "Change home dir ownership..."
    cmd "chown -R adam:users /home/adam"
    log "Change home dir ownership...done"
}

copyProjectLogFiles()
{
    cp -r ../logs /home/adam/archon/hal
}

#-------------------------------------------------------------------------------
# Supplementation
#
# Note: All steps will be executed using regular user account
#-------------------------------------------------------------------------------

#---------------------------------------
# Android development environment
#---------------------------------------

installJdk()
{
    log "Install jdk..."
    installAurPackage "jdk"
    log "Install jdk...done"
}

installAndroidEnv()
{
    log "Install android env"
    installAurPackage "android-sdk"
    installAurPackage "android-sdk-platform-tools"
    installAurPackage "android-sdk-build-tools"
    installAurPackage "android-studio"
    # Needed to update sdk manually using 'android' tool
    cmd "sudo chmod -R 755 /opt/android-sdk"
    err "$?" "$FUNCNAME" "failed to change android-sdk file permissions"
    log "Install android env...done"
}

