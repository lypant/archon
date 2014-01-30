#!/bin/bash

echo setup_custom.sh

source "setup.conf"
source "functions.sh"
source "common.sh"
source "individual.sh"
source "clone.sh"

# Set log file for custom setup
LOG_FILE="/root/archon/logs/setup_custom.log"

setupCustom()
{
    log "Setup custom..."

    ########################    COMMON SETUP

    # USERS

    # User1
    addUser1
    setUser1Password
    setUser1Sudoer

    # SYSTEM PACKAGES

    updatePackageList
    installAlsa

    # SOFTWARE PACKAGES

    installVim
    installMc
    installGit

    # CONFIGURATION

    configurePacman

    ########################    INDIVIDUAL SETUP

    ########################    REPOSITORY CLONING

    cloneArchonRepo
    checkoutCurrentBranch

    log "Setup custom...done"
}

setupCustom

