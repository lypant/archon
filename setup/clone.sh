#!/bin/bash

echo clone.sh

cloneArchonRepo()
{
    requiresVariable "ARCHON_REPO_URL" "$FUNCNAME"
    requiresVariable "USER_HOME" "$FUNCNAME"

    log "Clone archon repo..."

    executeCommand "cd $USER_HOME"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to enter user's home dir"

    executeCommand "git clone $ARCHON_REPO_URL"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to clone archon repo"

    log "Clone archon repo...done"
}

checkoutCurrentBranch()
{
    requiresVariable "USER_HOME" "$FUNCNAME"
    requiresVariable "ARCHON_BRANCH" "$FUNCNAME"
    
    log "Checkout current branch..."

    executeCommand "cd $USER_HOME/archon"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to enter archon dir"

    executeCommand "git checkout $ARCHON_BRANCH"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to checkout current branch"

    log "Checkout current branch...done"
}
