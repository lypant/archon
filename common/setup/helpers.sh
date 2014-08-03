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

