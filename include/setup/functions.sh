#!/bin/bash
#===============================================================================
# FILE:         functions.sh
#
# USAGE:        Include in other scripts, e.g. source functions.sh
#
# DESCRIPTION:  Functions used by setup scripts.
#               Contains only function definitions - they are not executed.
#===============================================================================

#===============================================================================
# Functions
#===============================================================================

# Requires:
#   - LOG_DIR
createLogDir()
{
    # Check if log dir variable is set.
    # Since there is no standard logging mechanism available at that stage,
    # just check the variable and echo on screen instead of using
    # TODO: <reqVar function name> function.
    if [[ -z "$LOG_DIR" ]]; then
        echo "$FUNCNAME: variable LOG_DIR not defined or empty"
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

