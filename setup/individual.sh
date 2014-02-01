#!/bin/bash

echo individual.sh

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

