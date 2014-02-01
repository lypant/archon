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
    configureGitUser

    ########################    REPOSITORY CLONING

    cloneArchonRepo
    checkoutCurrentBranch
    createNewBranch
    copyOverArchonFiles
    commitAdjustments

    ########################    INDIVIDUAL SETUP

    # USERS

    # SYSTEM PACKAGES

    # SOFTWARE PACKAGES

    # CONFIGURATION

    # Dotfiles - bash etc.
    installBashprofileDotfile
    installBashrcDotfile
    installDircolorssolarizedDotfile

    # Dotfiles - vim
    installVimrcDotfile
    installVimsolarizedDotfile

    # Dotfiles- mc
    installMcsolarizedDotfile

    # Dotfiles - git
    installGitconfigDotfile

    # Dotfiles - X
    installXinitrcDotfile
    installXresourcesDotfile

    # This should be the last step (or almost last ;)
    changeUser1HomeOwnership

    log "Setup custom...done"
}

setupCustom

