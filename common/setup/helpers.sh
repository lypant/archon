#!/bin/bash
#===============================================================================
# FILE:         helpers.sh
#
# USAGE:        Include in ohter scripts, e.g. source helpers.sh
#
# DESCRIPTION:  Simple functions used by other scripts to perform larger tasks.
#               Contains only function definitions - they are not executed.
#
# CONVENTIONS:  A function should either return an error code or abort a script
#               on failure.
#               Names of functions returning value start with an underscore.
#               Exception:  log function - returns result but always neglected,
#                           so without an underscore - for convenience
#===============================================================================

set -o nounset errexit

#===============================================================================
# Helper functions
#===============================================================================

# Requires:
#   LOG_DIR
createLogDir()
{
    # Check if log dir variable is set.
    # Since there is no standard logging mechanism available at that stage,
    # just check the variable and echo on screen instead of using
    # req function.
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

changeHomeOwnership()
{
    if [[ $# -lt 2 ]];then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        return 1
    fi

    log "Change home dir ownership..."

    local userName="$1"
    local userHome="$2"

    _cmd "chown -R $userName:users $userHome"
    err "$?" "$FUNCNAME" "failed to change home dir ownership"

    log "Change home dir ownership...done"
}

_enableService()
{
    if [[ $# -lt 1 ]]; then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        return 1
    fi

    _cmd "systemctl enable $1"
    return $?
}

_startService()
{
    if [[ $# -lt 1 ]]; then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        return 1
    fi

    _cmd "systemctl start $1"
    return $?
}

_createLink()
{
    if [[ $# -lt 2 ]]; then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        return 1
    fi

    local linkTarget=$1
    local linkName=$2
    local retval=0

    # Check if target exists
    if [[ -e $linkTarget ]]; then
        # File exists
        # create symlink
        _cmd "ln -s $linkTarget $linkName"
        retval=$?
    else
        log "Link target does not exist!"
        retval=2
    fi

    return $retval
}

_createDir()
{
    if [[ $# -lt 1 ]]; then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        return 1
    fi

    local dir="$1"
    local retval=0

    # Check if backup dir exists
    if [[ ! -d $dir ]]; then
        _cmd "mkdir -p $dir"
        retval="$?"
    fi

    return $retval
}

_backupFile()
{
    if [[ $# -lt 2 ]]; then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        return 1
    fi

    local original=$1
    local backup=$2
    local retval=0

    # If original file exists, move it to backup dir
    if [[ -e $original ]]; then
        _cmd "cp $original $backup"
        retval=$?
    fi

    return $retval
}

_installDotfile()
{
    req DOTFILES_BACKUP_DIR $FUNCNAME
    req DOTFILES_SOURCE_DIR $FUNCNAME
    req USER1_HOME $FUNCNAME

    if [[ $# -lt 2 ]]; then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        return 1
    fi

    local dotfileName="$1"
    local dotfileHomePath="$2"
    local dotfile=""
    local nested=0
    local now=`date +"%Y%m%d_%H%M"`

    # Avoid extra slash when path is empty
    if [[ -z "$dotfileHomePath" ]]; then
        dotfile="$dotfileName"
        nested=0
    else
        dotfile="$dotfileHomePath/$dotfileName"
        nested=1
    fi

    # Ensure that dotfiles backup dir exists
    _createDir "$DOTFILES_BACKUP_DIR"
    retval="$?"
    if [[ $retval -ne 0  ]]; then
        log "$FUNCNAME: failed to create dotfiles backup dir: $retval"
        return 2
    fi

    # Backup original dotfile, if it exists
    _backupFile "$USER1_HOME/$dotfile" "$DOTFILES_BACKUP_DIR/$dotfile"_"$now"
    retval="$?"
    if [[ $retval -ne 0  ]]; then
        log "$FUNCNAME: failed to backup dotfile $dotfile: $retval"
        return 3
    fi

    # Remove original dotfile
    _cmd "rm -f $USER1_HOME/$dotfile"
    retval="$?"
    if [[ $retval -ne 0  ]]; then
        log "$FUNCNAME: failed to delete original dotfile"\
            " $USER1_HOME/$dotfile: $retval"
        return 4
    fi

    # Ensure that for nested dotfile the path exists
    if [[ $nested -eq 1 ]]; then
        _cmd "mkdir -p $USER1_HOME/$dotfileHomePath"
        retval="$?"
        if [[ $retval -ne 0  ]]; then
            log "$FUNCNAME: failed to create path for nested dotfile: $retval"
            return 5
        fi
    fi

    # Create link to new dotfile
    _createLink "$DOTFILES_SOURCE_DIR/$dotfile" "$USER1_HOME/$dotfile"
    retval="$?"
    if [[ $retval -ne 0  ]]; then
        log "$FUNCNAME: failed to create link to new dotfile"\
            "$DOTFILES_SOURCE_DIR/$dotfile: $retval"
        return 6
    fi

    return $retval
}

installAurPackage()
{
    if [[ $# -lt 1 ]]; then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        exit 1
    fi

    local buildDir="/tmp"
    local url="https://aur.archlinux.org/packages"

    for p in $@
    do
        local pkgFile="$url/${p:0:2}/$p/$p.tar.gz"

        cd $buildDir
        _cmd "curl \"$pkgFile\" | tar xz"
        err "$?" "$FUNCNAME" "failed to download $pkgFile package file"

        cd $buildDir/$p
        # TODO: Consider another solution to avoid --asroot
        _cmd "makepkg -si --asroot --noconfirm"
        err "$?" "$FUNCNAME" "failed to make package $p"
    done
}

