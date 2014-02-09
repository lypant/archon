#!/bin/bash

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

installPackage()
{
    log "Installing package $@..."

    executeCommand "pacman -S $@ --noconfirm"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install package $@"

    log "Installing package $@...done"
}

updatePackageList()
{
    log "Update package list..."

    executeCommand "pacman -Syy"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to update package list"

    log "Update package list...done"
}

