#!/bin/bash
#===============================================================================
# FILE:         customize.sh
#
# USAGE:        Execute from shell, e.g. ./customize.sh
#
# DESCRIPTION:  TODO: Describe
#===============================================================================

#===============================================================================
# Includes
#===============================================================================

source individual_settings.conf
source ../../common/setup/project_settings.conf
source ../../common/setup/common_settings.conf
source ../../common/setup/project_settings.conf
source individual_settings.conf
source ../../common/setup/functions.sh
source ../../common/setup/helpers.sh
source ../../common/setup/all_steps.sh
source individual_steps.sh
source ../../common/setup/common_steps.sh

#===============================================================================
#  Log file
#===============================================================================

LOG_FILE="$CUSTOMIZE_LOG_FILE"

#===============================================================================
# Perform customization
#===============================================================================

customize

