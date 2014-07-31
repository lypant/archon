#!/bin/bash
#===============================================================================
# FILE:         all_steps.sh
#
# USAGE:        Include in ohter scripts, e.g. source all_steps.sh
#
# DESCRIPTION:  Each function is a step of a target system preparation.
#               This file contains all step functions.
#               Other files (custom, individual) may group the steps to
#               form logically related compositions.
#               Contains only function definitions - they are not executed.
#
# CONVENTIONS:  A function should either return an error code or abort a script
#               on failure.
#               Names of functions returning value start with an underscore.
#               Exception:  log function - returns result but always neglected,
#                           so without an underscore - for convenience
#===============================================================================

#===============================================================================
# TODO:
#===============================================================================

