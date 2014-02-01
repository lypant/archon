#!/bin/bash

echo clone.sh

cloneArchonRepo()
{
    requiresVariable "ARCHON_REPO_URL" "$FUNCNAME"
    requiresVariable "ARCHON_REPO_DST" "$FUNCNAME"

    log "Clone archon repo..."

    executeCommand "git clone $ARCHON_REPO_URL $ARCHON_REPO_DST"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to clone archon repo"

    log "Clone archon repo...done"
}

checkoutCurrentBranch()
{
    requiresVariable "ARCHON_REPO_DST" "$FUNCNAME"
    requiresVariable "ARCHON_BRANCH" "$FUNCNAME"
    
    log "Checkout current branch..."

    # Execute git commands from destination path
    executeCommand "git -C $ARCHON_REPO_DST checkout $ARCHON_BRANCH"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to checkout current branch"

    log "Checkout current branch...done"
}

createNewBranch()
{
    requiresVariable "ARCHON_REPO_DST" "$FUNCNAME"
    requiresVariable "ARCHON_NEW_BRANCH_NAME" "$FUNCNAME"

    log "Create new branch..."

    executeCommand "git -C $ARCHON_REPO_DST checkout -b \"$ARCHON_NEW_BRANCH_NAME\""
    terminateScriptOnError "$?" "$FUNCNAME" "failed to create new archon branch"

    log "Create new branch...done"
}

copyOverArchonFiles()
{
    requiresVariable "ARCHON_ROOT_PATH" "$FUNCNAME"
    requiresVariable "USER1_HOME" "$FUNCNAME"

    log "Copy over archon files..."

    executeCommand "cp -r $ARCHON_ROOT_PATH $USER1_HOME"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to copy over archon files"

    log "Copy over archon files...done"
}

commitAdjustments()
{
    requiresVariable "ARCHON_REPO_DST" "$FUNCNAME"

    log "Commit adjustments..."

    if [[ -n "$(git status --porcelain)" ]]; then
        executeCommand "git -C $ARCHON_REPO_DST commit -a -m \"Adjustments done during archon installation\""
        terminateScriptOnError "$?" "$FUNCNAME" "failed to commit adjustments"
    else
        log "No changes detected, no need to commit"
    fi

    log "Commit adjustments...done"
}

