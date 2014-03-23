#!/bin/bash
#===============================================================================
# FILE:         basic_setup.sh
#
# USAGE:        Execute from shell, e.g. ./basic_setup.sh
#
# DESCRIPTION:  Functions used to perform basic system setup.
#               Executes main setup function.
#===============================================================================

#===============================================================================
# Other scripts usage
#===============================================================================

# Load settings specific for given machine
source "settings.conf"

# Load basic setup script common for all machines
source "../../common/setup/settings.conf"

# Load generic helper functions
source "../../common/setup/functions.sh"

# Load basic setup functions
source "../../common/setup/basic_setup.sh"

#===============================================================================
# Main setup function execution
#===============================================================================

# Perform installation
setupBasic

