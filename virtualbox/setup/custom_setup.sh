#!/bin/bash
#===============================================================================
# FILE:         custom_setup.sh
#
# USAGE:        Execute from shell, e.g. ./custom_setup.sh
#
# DESCRIPTION:  Functions used to perform custom system setup.
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

# Load common custom setup functions
source "../../common/setup/custom_setup.sh"

#===============================================================================
# Setup functions
#===============================================================================

#=======================================
# Individual setup
#=======================================

#===================
# Individual users
#===================

#===================
# Individual system packages
#===================

#===================
# Individual software packages
#===================

#=========
# Console-based
#=========

installVirtualboxGuestAdditions()
{
    reqVar "VIRTUALBOX_GUEST_UTILS_PACKAGES" "$FUNCNAME"
    reqVar "VIRTUALBOX_GUEST_UTILS_MODULES" "$FUNCNAME"
    reqVar "VIRTUALBOX_GUEST_UTILS_MODULES_FILE" "$FUNCNAME"

    log "Install virtualbox guest additions..."

    # Install the packages
    installPackage $VIRTUALBOX_GUEST_UTILS_PACKAGES
    err "$?" "$FUNCNAME" "failed to install virtualbox package"

    # Load required modules
    cmd "modprobe -a $VIRTUALBOX_GUEST_UTILS_MODULES"
    err "$?" "$FUNCNAME" "failed to load required modules"

    # Setup modules to be loaded on startup
    if [ ! -z "$VIRTUALBOX_GUEST_UTILS_MODULES" ]; then
        for module in $VIRTUALBOX_GUEST_UTILS_MODULES
        do
            cmd "echo $module >> $VIRTUALBOX_GUEST_UTILS_MODULES_FILE"
            err "$?" "$FUNCNAME"\
                "failed to setup module to be loaded on startup"
        done
    fi

    log "Install virtualbox guest additions...done"
}

#=========
# GUI-based
#=========

#===================
# Individual configuration
#===================

setVirtualboxSharedFolder()
{
    reqVar "USER1_NAME" "$FUNCNAME"
    reqVar "USER1_HOME" "$FUNCNAME"
    reqVar "VIRTUALBOX_SHARED_FOLDER_NAME" "$FUNCNAME"

    log "Set virtualbox shared folder..."

    # Create /media folder
    cmd "mkdir /media"
    err "$?" "$FUNCNAME" "failed to create /media dir"

    # Add user1 to vboxsf group
    cmd "gpasswd -a $USER1_NAME vboxsf"
    err "$?" "$FUNCNAME" "failed to add user to vboxsf group"

    # Enable vboxservice service
    enableService "vboxservice"
    err "$?" "$FUNCNAME" "failed to enable vboxservice"

    # Start vboxservice (needed for link creation)
    startService "vboxservice"
    err "$?" "$FUNCNAME" "failed to start vboxservice"

    # Wait a moment for a started service to do its job
    cmd "sleep 5"

    # Create link for easy access
    createLink\
        "/media/sf_$VIRTUALBOX_SHARED_FOLDER_NAME"\
        "$USER1_HOME/$VIRTUALBOX_SHARED_FOLDER_NAME"
    err "$?" "$FUNCNAME" "failed to create link to shared folder"

    log "Set virtualbox shared folder...done"
}

#===================
# Other
#===================

#=======================================
# Post setup actions
#=======================================

#===============================================================================
# Main setup function
#===============================================================================

setupIndividualCustom()
{
    createLogDir    # Should be created by basic setup; just to be sure

    log "Setup individual custom..."

    #=======================================
    # Individual setup
    #=======================================

    #===================
    # Individual users
    #===================

    #===================
    # Individual system packages
    #===================

    #===================
    # Individual software packages
    #===================

    #=========
    # Console-based
    #=========

    installVirtualboxGuestAdditions

    #=========
    # GUI-based
    #=========

    #===================
    # Individual configuration
    #===================

    setVirtualboxSharedFolder

    #===================
    # Other
    #===================

    changeUser1HomeOwnership

    log "Setup individual custom...done"

    #=======================================
    # Post setup actions
    #=======================================

    copyProjectLogFiles
}

#===============================================================================
# Main setup function execution
#===============================================================================

setupCommonCustom
setupIndividualCustom

