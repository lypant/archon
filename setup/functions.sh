#!/bin/bash

echo functions.sh

executeCommand()
{
    # Check if all required variables are set
    if [[ -z "$LOG_FILE" ]]; then
        echo "$FUNCNAME: variable LOG_FILE not set"
        return 1
    fi

    if [[ -z "$ARCHON_CMD_PREFIX" ]]; then
        echo "$FUNCNAME: variable ARCHON_CMD_PREFIX not set"
        return 2
    fi

    # Record command to be executed to the log file
    echo "$ARCHON_CMD_PREFIX$@" >> $LOG_FILE

    # Execute command
    # Redirect stdout and stderr to screen and log file
    (eval "$@" 2>&1) | tee -a $LOG_FILE
    return ${PIPESTATUS[0]}
}

log()
{
    # Check if all required variables are set
    if [[ -z "$LOG_FILE" ]]; then
        echo "$FUNCNAME: variable LOG_FILE not set"
        return 1
    fi

    if [[ -z "$ARCHON_LOG_PREFIX" ]]; then
        echo "$FUNCNAME: variable ARCHON_LOG_PREFIX not set"
        return 2
    fi

    # Use msg with prefix to distinguish Archconfig logs
    local msg="$ARCHON_LOG_PREFIX$@"

    # Write message to screen and log file
    (echo "$msg" 2>&1) | tee -a $LOG_FILE
    return ${PIPESTATUS[0]}
}

# Usage: checkVariable "MY_VAR" "$FUNCNAME"
requiresVariable()
{
    local var="$1"
    local function="$2"

    if [[ -z "${!var}" ]]; then
        log "$function: variable $var not defined"
        log "Aborting script!"
        exit 1
    fi
}

terminateScriptOnError()
{
    # Check number of required params
    if [[ $# -lt 3 ]]; then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        return 1
    fi

    local error="$1"
    local funcname="$2"
    local msg="$3"

    if [[ "$error" -ne 0 ]]; then
        log "$funcname: $msg: $error"
        log "Aborting script!"
        exit 1
    fi
}

uncommentVar()
{
    if [[ $# -lt 2 ]]; then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        return 1
    fi

	local var="$1"
	local file="$2"

    executeCommand "sed -i \"s/^#\(${var}.*\)$/\1/\" ${file}"
    return $?
}

commentVar ()
{
    if [[ $# -lt 2 ]]; then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        return 1
    fi

	local var="$1"
	local file="$2"

    executeCommand "sed -i \"s/^\(${var}.*\)$/#\1/\" ${file}"
    return $?
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

installPackage()
{
    log "Installing package $@..."

    executeCommand "pacman -S $@ --noconfirm"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install package $@"

    log "Installing package $@...done"
}

addUser()
{
    if [[ $# -lt 4 ]];then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        terminateScriptOnError "1" "$FUNCNAME" "failed to add regular user"
    fi

    local mainGroup="$1"
    local additionalGroups="$2"
    local shell="$3"
    local name="$4"

    log "Add user..."

    executeCommand "useradd -m -g $mainGroup -G $additionalGroups -s $shell $name"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to add user"

    log "Add user...done"
}

setUserPassword()
{
    if [[ $# -lt 1 ]];then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        terminateScriptOnError "1" "$FUNCNAME" "failed to set user password"
    fi

    log "Set user password..."

    local ask=1
    local name="$1"

    while [ $ask -ne 0 ]; do
        log "Provide password for user $name"
        executeCommand "passwd $name"
        ask=$?
    done

    log "Set user password...done"
}

setSudoer()
{
    if [[ $# -lt 1 ]];then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        terminateScriptOnError "1" "$FUNCNAME" "failed to set sudoer"
    fi

    log "Set sudoer..."

    local name="$1"

    # TODO - do it in a safer way... Here just for experiments
    executeCommand "echo \"$name ALL=(ALL) ALL\" >> /etc/sudoers"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to set sudoer"

    log "Set sudoer...done"
}

updatePackageList()
{
    log "Update package list..."

    executeCommand "pacman -Syy"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to update package list"

    log "Update package list...done"
}

backupFile()
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
        executeCommand "cp $original $backup"
        retval=$?
    fi
    return $retval
}

createLink()
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
        executeCommand "ln -s $linkTarget $linkName"
        retval=$?
    else
        log "Link target does not exist!"
        retval=2
    fi

    return $retval
}

enableService()
{
    if [[ $# -lt 1 ]]; then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        return 1
    fi

    local service="$1"

    executeCommand "systemctl enable $service"
    return $?
}

startService()
{
    if [[ $# -lt 1 ]]; then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        return 1
    fi

    local service="$1"

    executeCommand "systemctl start $service"
    return $?
}

