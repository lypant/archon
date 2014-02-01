#!/bin/bash

echo individual.sh

createDotfilesBackupDir()
{
    requiresVariable "DOTFILES_BACKUP_DIR" "$FUNCNAME"

    local retval=0

    # Check if backup dir exists
    if [[ ! -d $DOTFILES_BACKUP_DIR ]]; then
        executeCommand "mkdir -p $DOTFILES_BACKUP_DIR"
        retval="$?"
    fi

    return $retval
}

installDotfile()
{
    requiresVariable "DOTFILES_BACKUP_DIR" "$FUNCNAME"
    requiresVariable "DOTFILES_SOURCE_DIR" "$FUNCNAME"
    requiresVariable "USER1_HOME" "$FUNCNAME"

    if [[ $# -lt 2 ]]; then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        return 1
    fi

    local dotfileName="$1"
    local dotfileHomePath="$2"
    local dotfile=""
    local now=`date +"%Y%m%d_%H%M"`

    # Avoid extra slash when path is empty
    if [[ -z "$dotfileHomePath" ]]; then
        dotfile="$dotfileName"
    else
        dotfile="$dotfileHomePath/$dotfileName"
    fi

    # Ensure that dotfiles backup dir exists
    createDotfilesBackupDir
    retval="$?"
    if [[ $retval -ne 0  ]]; then
        log "$FUNCNAME: failed to create dotfiles backup dir: $retval"
        return 2
    fi

    # Backup original dotfile, if it exists
    backupFile "$USER1_HOME/$dotfile" "$DOTFILES_BACKUP_DIR/$dotfile"_"$now"
    retval="$?"
    if [[ $retval -ne 0  ]]; then
        log "$FUNCNAME: failed to backup dotfile $dotfile: $retval"
        return 3
    fi

    # Remove original dotfile
    executeCommand "rm -f $USER1_HOME/$dotfile"
    retval="$?"
    if [[ $retval -ne 0  ]]; then
        log "$FUNCNAME: failed to delete original dotfile $USER1_HOME/$dotfile: $retval"
        return 4
    fi

    # Create link to new dotfile
    createLink "$DOTFILES_SOURCE_DIR/$dotfile" "$USER1_HOME/$dotfile"
    retval="$?"
    if [[ $retval -ne 0  ]]; then
        log "$FUNCNAME: failed to create link to new dotfile $DOTFILES_SOURCE_DIR/$dotfile: $retval"
        return 4
    fi

    return $retval
}

installBashprofileDotfile()
{
    log "Install bash_profile dotfile..."

    installDotfile ".bash_profile" ""
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install bash_profile dotfile"

    log "Install bash_profile dotfile...done"
}

installBashrcDotfile()
{
    log "Install bashrc dotfile..."

    installDotfile ".bashrc" ""
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install bashrc dotfile"

    log "Install bashrc dotfile...done"
}

installDircolorssolarizedDotfile()
{
    log "Install .dir_colors_solarized dotfile..."

    installDotfile ".dir_colors_solarized" ""
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install .dir_colors_solarized dotfile"

    log "Install .dir_colors_solarized dotfile...done"
}

installVimrcDotfile()
{
    log "Install vimrc dotfile..."

    installDotfile ".vimrc" ""
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install vimrc dotfile"

    log "Install vimrc dotfile...done"
}

installVimsolarizedDotfile()
{
    log "Install solarized.vim dotfile..."

    installDotfile "solarized.vim" ".vim/colors"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install solarized.vim dotfile"

    log "Install solarized.vim dotfile...done"
}

installMcsolarizedDotfile()
{
    log "Install mc_solarized.ini dotfile..."

    installDotfile "mc_solarized.ini" ".config/mc"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install mc_solarized.ini dotfile"

    log "Install mc_solarized.ini dotfile...done"
}

installGitconfigDotfile()
{
    log "Install .gitconfig dotfile..."

    installDotfile ".gitconfig" ""
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install .gitconfig dotfile"

    log "Install .gitconfig dotfile...done"
}

installXinitrcDotfile()
{
    log "Install .xinitrc dotfile..."

    installDotfile ".xinitrc" ""
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install .xinitrc dotfile"

    log "Install .xinitrc dotfile...done"
}

installXresourcesDotfile()
{
    log "Install .Xresources dotfile..."

    installDotfile ".Xresources" ""
    terminateScriptOnError "$?" "$FUNCNAME" "failed to install .Xresources dotfile"

    log "Install .Xresources dotfile...done"
}

changeHomeOwnership()
{
    if [[ $# -lt 2 ]];then
        log "$FUNCNAME: not enough parameters \($#\): $@"
        return 1
    fi

    log "Change home dir ownership..."

    local userName="$1"
    local userHome="$2"

    executeCommand "chown -R $userName:users $userHome"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to change home dir ownership"

    log "Change home dir ownership...done"
}

changeUser1HomeOwnership()
{
    requiresVariable "USER1_NAME" "$FUNCNAME"
    requiresVariable "USER1_HOME" "$FUNCNAME"

    log "Change user1 home ownership..."

    changeHomeOwnership "$USER1_NAME" "$USER1_HOME"
    # TODO: following tSOE is redundand - function above already cheks that - improve in future
    terminateScriptOnError "$?" "$FUNCNAME" "failed to change user1 home dir ownership"

    log "Change user1 home ownership...done"
}

