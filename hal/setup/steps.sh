#!/bin/bash
#===============================================================================
# FILE:         steps.sh
#
# USAGE:        Include in other scripts, e.g. source steps.sh
#
# DESCRIPTION:  Defines but does not execute functions that can be used
#               in other scripts.
#               TODO: Describe in more details
#===============================================================================

# Treat unset variables as an error when peforming parameter expansion
# Exit immediately on errors
set -o nounset errexit

# Include functions definitions
source functions.sh

#-------------------------------------------------------------------------------
# Installation
#-------------------------------------------------------------------------------

createLogDir()
{
    mkdir ../logs
}

setLivecdFont()
{
   setfont Lat2-Terminus16 
}

# TODO: Remove when basic include and execution mechanism is tested
helloArch()
{
    log "Introduce yourself..."
    cmd "echo Hello Arch!"
    log "Introduce yourself...done"
}

