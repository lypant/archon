#!/bin/bash
#===============================================================================
# FILE:         functions.sh
#
# USAGE:        Include in other scripts, e.g. source functions.sh
#
# DESCRIPTION:  Functions used by both setup scripts.
#               Contains only function definitions - they are not executed.
#===============================================================================

createLogDir()
{
    # Check if all required variables are set
    if [[ -z "$PROJECT_LOG_DIR" ]]; then
        echo "$FUNCNAME: variable PROJECT_LOG_DIR not set"
        echo "Aborting script!"
        exit 1
    fi

    mkdir -p $PROJECT_LOG_DIR
    if [[ "$?" -ne 0 ]]; then
        echo "Failed to create log dir $PROJECT_LOG_DIR"
        echo "Aborting script!"
        exit 2
    fi
}

cmd()
{
    # Check if all required variables are set
    if [[ -z "$LOG_FILE" ]]; then
        echo "$FUNCNAME: variable LOG_FILE not set"
        return 1
    fi

    if [[ -z "$PROJECT_CMD_PREFIX" ]]; then
        echo "$FUNCNAME: variable PROJECT_CMD_PREFIX not set"
        return 2
    fi

    # Record command to be executed to the log file
    echo "$PROJECT_CMD_PREFIX$@" >> $LOG_FILE

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

    if [[ -z "$PROJECT_LOG_PREFIX" ]]; then
        echo "$FUNCNAME: variable PROJECT_LOG_PREFIX not set"
        return 2
    fi

    # Use msg with prefix to distinguish Archconfig logs
    local msg="$PROJECT_LOG_PREFIX$@"

    # Write message to screen and log file
    (echo "$msg" 2>&1) | tee -a $LOG_FILE
    return ${PIPESTATUS[0]}
}

# Requires variable
# Usage: reqVar "MY_VAR" "$FUNCNAME"
reqVar()
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
# Usage: err "$?" "$FUNCNAME" "message to be shown and logged"
err()
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

    cmd "sed -i \"s|^#\(${var}.*\)$|\1|\" ${file}"
    return $?
}

commentVar()
{
    if [[ $# -lt 2 ]]; then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        return 1
    fi

	local var="$1"
	local file="$2"

    cmd "sed -i \"s|^\(${var}.*\)$|#\1|\" ${file}"
    return $?
}

installPackage()
{
    log "Installing package $@..."

    cmd "pacman -S $@ --noconfirm"
    err "$?" "$FUNCNAME" "failed to install package $@"

    log "Installing package $@...done"
}

updatePackageList()
{
    log "Update package list..."

    cmd "pacman -Syy"
    err "$?" "$FUNCNAME" "failed to update package list"

    log "Update package list...done"
}

delay()
{
    if [[ $# -lt 1 ]]; then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        return 1
    fi

    local seconds="$1"

    log "Waiting $seconds""s..."
    cmd "sleep $seconds"
    log "Waiting $seconds""s...done"
}

