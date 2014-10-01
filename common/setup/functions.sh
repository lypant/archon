#!/bin/bash
#===============================================================================
# FILE:         functions.sh
#
# USAGE:        Include in ohter scripts, e.g. source functions.sh
#
# DESCRIPTION:  Basic functions used by other scripts.
#               Contains only function definitions - they are not executed.
#===============================================================================

set -o nounset errexit

#===============================================================================
# Basic functions
#===============================================================================

# Requires:
#   LOG_FILE
#   LOG_PREFIX
log()
{
    # Use msg with prefix to distinguish logs generated by setup scripts
    local msg="$LOG_PREFIX$@"

    # Write message to screen and log file
    (echo "$msg" 2>&1) | tee -a $LOG_FILE
    return ${PIPESTATUS[0]}
}

# Requires:
#   LOG_FILE
#   CMD_PREFIX
cmd()
{
    # Record command to be executed to the log file
    echo "$CMD_PREFIX$@" >> $LOG_FILE

    # Execute command
    # Redirect stdout and stderr to screen and log file
    (eval "$@" 2>&1) | tee -a $LOG_FILE
    return ${PIPESTATUS[0]}
}

# Checks provided error code. Terminates script when it is nonzero.
# Usage: err "$?" "$FUNCNAME" "message to be shown and logged"
err()
{
    local error="$1"
    local funcname="$2"
    local msg="$3"

    if [[ "$error" -ne 0 ]]; then
        log "$funcname: $msg: $error"
        log "Aborting!"
        exit 1
    fi
}

uncommentVar()
{
	local var="$1"
	local file="$2"

    cmd "sed -i \"s|^#\(${var}.*\)$|\1|\" ${file}"
}

commentVar()
{
	local var="$1"
	local file="$2"

    cmd "sed -i \"s|^\(${var}.*\)$|#\1|\" ${file}"
}

#===============================================================================
# Helper functions
#===============================================================================

# Requires:
#   LOG_DIR
createLogDir()
{
    # Create log directory
    mkdir -p $LOG_DIR

    # Check result
    if [[ "$?" -ne 0 ]]; then
        echo "Failed to create log dir $LOG_DIR"
        echo "Aborting script!"
        exit 2
    fi
}

updatePackageList()
{
    log "Update package list..."
    cmd "pacman -Syy"
    err "$?" "$FUNCNAME" "failed to update package list"
    log "Update package list...done"
}

installPackage()
{
    log "Install package $@..."
    cmd "pacman -S $@ --noconfirm"
    err "$?" "$FUNCNAME" "failed to install package"
    log "Install package $@...done"
}

removePackage()
{
    log "Remove package $@..."
    cmd "pacman -Rdd $@ --noconfirm"
    err "$?" "$FUNCNAME" "failed to remove package"
    log "Remove package $@...done"
}

# Delay is given in seconds
delay()
{
    log "Waiting $1""s..."
    cmd "sleep $1"
    log "Waiting $1""s...done"
}

createPartition()
{
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

    err "$?" "$FUNCNAME" "failed to create partition"

    delay $PARTITION_OPERATIONS_DELAY
}

# Best executed when all (at least two) partitions are created
setPartitionBootable()
{
    local disk="$1"     # e.g. /dev/sda
    local partNb="$2"   # e.g. "1" for "/dev/sda1"

    cat <<-EOF | fdisk $disk
	a
	$partNb
	w
	EOF

    err "$?" "$FUNCNAME" "failed to set partition bootable"

    delay $PARTITION_OPERATIONS_DELAY
}

downloadFile()
{
    local src=$1
    local dst=$2

    cmd "curl -so $dst --create-dirs $src"
    err "$?" "$FUNCNAME" "failed to download file"
}

archChroot()
{
    cmd arch-chroot $ROOT_PARTITION_MOUNT_POINT /bin/bash -c \""$@"\"
}

setLocale()
{
    local subst="s|^#\\\\\(${1}.*\\\\\)$|\1|"
    local file="/etc/locale.gen"

    log "Set locale for  $1..."
    archChroot "sed -i \\\"$subst\\\" $file"
    err "$?" "$FUNCNAME" "failed to set locale"
    log "Set locale for $1...done"
}

addUser()
{
    local mainGroup="$1"
    local additionalGroups="$2"
    local shell="$3"
    local name="$4"

    log "Add user..."
    cmd "useradd -m -g $mainGroup -G $additionalGroups -s $shell $name"
    err "$?" "$FUNCNAME" "failed to add user"
    log "Add user...done"
}

setUserPassword()
{
    local ask=1
    local name="$1"

    log "Set user password..."

    while [ $ask -ne 0 ]; do
        log "Provide password for user $name"
        cmd "passwd $name"
        ask=$?
    done

    log "Set user password...done"
}

# TODO - do it in a safer way... Here just for experiments
setSudoer()
{
    local name="$1"

    log "Set sudoer..."
    cmd "echo \"$name ALL=(ALL) ALL\" >> /etc/sudoers"
    err "$?" "$FUNCNAME" "failed to set sudoer"
    log "Set sudoer...done"
}

changeHomeOwnership()
{
    local userName="$1"
    local userHome="$2"

    log "Change home dir ownership..."
    cmd "chown -R $userName:users $userHome"
    err "$?" "$FUNCNAME" "failed to change home ownership"
    log "Change home dir ownership...done"
}

enableService()
{
    cmd "systemctl enable $1"
    err "$?" "$FUNCNAME" "failed to enable service $1"
}

startService()
{
    cmd "systemctl start $1"
    err "$?" "$FUNCNAME" "failed to start service $1"
}

createLink()
{
    local linkTarget=$1
    local linkName=$2
    local retval=0

    # Check if target exists
    if [[ -e $linkTarget ]]; then
        # File exists
        # create symlink
        cmd "ln -s $linkTarget $linkName"
        retval=$?
    else
        log "Link target does not exist!"
        retval=2
    fi

    return $retval
}

createDir()
{
    local dir="$1"
    local retval=0

    # Check if backup dir exists
    if [[ ! -d $dir ]]; then
        cmd "mkdir -p $dir"
        retval="$?"
    fi

    return $retval
}

backupFile()
{
    local original=$1
    local backup=$2
    local retval=0

    # If original file exists, move it to backup dir
    if [[ -e $original ]]; then
        cmd "cp $original $backup"
        retval=$?
    fi

    return $retval
}

installDotfile()
{
    local dotfileName="$1"
    local dotfileHomePath="$2"
    local dotfile=""
    local nested=0
    local now=`date +"%Y%m%d_%H%M"`
    local dotfilesSrcDir="$USER1_HOME/$PROJECT_NAME/$VARIANT/$DOTFILES_DIR_NAME"
    local dotfilesBkpDir="$dotfilesSrcDir/$BACKUP_DIR_NAME"

    # Avoid extra slash when path is empty
    if [[ -z "$dotfileHomePath" ]]; then
        dotfile="$dotfileName"
        nested=0
    else
        dotfile="$dotfileHomePath/$dotfileName"
        nested=1
    fi

    # Ensure that dotfiles backup dir exists
    createDir "$dotfilesBkpDir"
    retval="$?"
    if [[ $retval -ne 0  ]]; then
        log "$FUNCNAME: failed to create dotfiles backup dir: $retval"
        return 2
    fi

    # Backup original dotfile, if it exists
    backupFile "$USER1_HOME/$dotfile" "$dotfilesBkpDir/$dotfile"_"$now"
    retval="$?"
    if [[ $retval -ne 0  ]]; then
        log "$FUNCNAME: failed to backup dotfile $dotfile: $retval"
        return 3
    fi

    # Remove original dotfile
    cmd "rm -f $USER1_HOME/$dotfile"
    retval="$?"
    if [[ $retval -ne 0  ]]; then
        log "$FUNCNAME: failed to delete original dotfile"\
            " $USER1_HOME/$dotfile: $retval"
        return 4
    fi

    # Ensure that for nested dotfile the path exists
    if [[ $nested -eq 1 ]]; then
        cmd "mkdir -p $USER1_HOME/$dotfileHomePath"
        retval="$?"
        if [[ $retval -ne 0  ]]; then
            log "$FUNCNAME: failed to create path for nested dotfile: $retval"
            return 5
        fi
    fi

    # Create link to new dotfile
    createLink "$dotfilesSrcDir/$dotfile" "$USER1_HOME/$dotfile"
    retval="$?"
    if [[ $retval -ne 0  ]]; then
        log "$FUNCNAME: failed to create link to new dotfile"\
            "$dotfilesSrcDir/$dotfile: $retval"
        return 6
    fi

    return $retval
}

installAurPackage()
{
    local buildDir="/tmp"
    local url="https://aur.archlinux.org/packages"

    for p in $@
    do
        local pkgFile="$url/${p:0:2}/$p/$p.tar.gz"

        cd $buildDir
        cmd "curl \"$pkgFile\" | tar xz"
        err "$?" "$FUNCNAME" "failed to download package file"

        cd $buildDir/$p
        err "$?" "$FUNCNAME" "failed to enter package dir"

        # TODO: Consider another solution to avoid --asroot
        cmd "makepkg -si --asroot --noconfirm"
        err "$?" "$FUNCNAME" "failed to install package"
    done
}

changeOutputLevels()
{
    local src="StandardOutput=journal+console"
    local dst="StandardOutput=null\nStandardError=journal+console"
    local subst="s|$src|$dst|"
    local file="$1"

    cmd "sed -i \"$subst\" $file"
    err "$?" "$FUNCNAME" "failed to change output levels for $file"
}

