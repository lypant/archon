#!/bin/bash

echo clone.sh

cloneArchonRepo()
{
    requiresVariable "ARCHON_REPO_URL" "$FUNCNAME"
    requiresVariable "ARCHON_REPO_DST" "$FUNCNAME"

    log "Clone archon repo..."

    # Execute git commands from destination path
    executeCommand "git -C $ARCHON_REPO_DST clone $ARCHON_REPO_URL"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to clone archon repo"

    log "Clone archon repo...done"
}

checkoutCurrentBranch()
{
    requiresVariable "ARCHON_REPO_DST" "$FUNCNAME"
    requiresVariable "ARCHON_BRANCH" "$FUNCNAME"
    
    log "Checkout current branch..."

    executeCommand "git -C $ARCHON_REPO_DST checkout $ARCHON_BRANCH"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to checkout current branch"

    log "Checkout current branch...done"
}

