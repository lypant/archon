#!/bin/bash

echo individual.sh

createDotfilesBackupDir()
{
    requiresVariable "DOTFILES_BACKUP_DIR" "$FUNCTION"

    local retval=0

    # Check if backup dir exists
    if [[ ! -d $DOTFILES_BACKUP_DIR ]]; then
        executeCommand "mkdir -p $DOTFILES_BACKUP_DIR"
        retval="$?"
    fi

    return $retval
}

installDotfile()
{
    requiresVariable "DOTFILES_BACKUP_DIR" "$FUNCTION"
    requiresVariable "DOTFILES_SOURCE_DIR" "$FUNCTION"
    requiresVariable "USER_HOME" "$FUNCTION"

    if [[ $# -lt 2 ]]; then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        return 1
    fi

    local dotfileName="$1"
    local dotfileHomePath="$2"
    local dotfile=""
    local now=`date +"%Y%m%d_%H%M"`

    # Avoid extra slash when path is empty
    if [[ -z "$dotfileHomePath" ]]; then
        dotfile="$dotfileName"
    else
        dotfile="$dotfileHomePath/$dotfileName"
    fi

    # Ensure that dotfiles backup dir exists
    createDotfilesBackupDir
    retval="$?"
    if [[ $retval -ne 0  ]]; then
        log "$FUNCNAME: failed to create dotfiles backup dir: $retval"
        return 2
    fi

    # Backup original dotfile, if it exists
    backupFile "$USER_HOME/$dotfile" "$DOTFILES_BACKUP_DIR/$dotfile"_"$now"
    retval="$?"
    if [[ $retval -ne 0  ]]; then
        log "$FUNCNAME: failed to backup dotfile $dotfile: $retval"
        return 3
    fi

    # Remove original dotfile
    executeCommand "rm -f $USER_HOME/$dotfile"
    retval="$?"
    if [[ $retval -ne 0  ]]; then
        log "$FUNCNAME: failed to delete original dotfile $USER_HOME/$dotfile: $retval"
        return 4
    fi

    # Create link to new dotfile
    createLink "$DOTFILES_SOURCE_DIR/$dotfile" "$USER_HOME/$dotfile"
    retval="$?"
    if [[ $retval -ne 0  ]]; then
        log "$FUNCNAME: failed to create link to new dotfile $DOTFILES_SOURCE_DIR/$dotfile: $retval"
        return 4
    fi

    return $retval
}

installBashrcDotfile()
{
    log "Install bashrc dotfile..."

    installDotfile ".bashrc" ""
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install bashrc dotfile"

    log "Install bashrc dotfile...done"
}

changeHomeOwnership()
{
    if [[ $# -lt 2 ]];then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        return 1
    fi

    log "Change home dir ownership..."

    local user_name="$1"
    local user_home="$2"

    executeCommand "chown -R $user_name:users $user_home"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to change home dir ownership"

    log "Change home dir ownership...done"
}

changeUser1HomeOwnership()
{
    requiresVariable "USER1_NAME" "$FUNCNAME"
    requiresVariable "USER1_HOME" "$FUNCNAME"

    log "Change user1 home ownership..."

    changeHomeOwnership "$USER1_NAME" "$USER1_HOME"
    # TODO: following tSOE is redundand - function above already cheks that - improve in future
    terminateScriptOnError "$?" "$FUNCNAME" "failed to change user1 home dir ownership"

    log "Change user1 home ownership...done"
}

