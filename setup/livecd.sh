#!/bin/bash

echo livecd.sh

setLivecdConsoleFont()
{
    requiresVariable "CONSOLE_FONT" "$FUNCNAME"

    log "Set livecd console font..."

    executeCommand "setfont $CONSOLE_FONT"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to set livecd console font"

    log "Set livecd console font...done"
}

setLivecdPacmanTotalDownload()
{
    log "Set livecd pacman total download..."

    uncommentVar "TotalDownload" "/etc/pacman.conf"
    terminateScriptOnError "$?" "$FUNCNAME" "failed to set livecd pacman total download"

    log "Set livecd pacman total download...done"
}

installLivecdVim()
{
    log "Install livecd vim..."

    installPackage "vim"

    log "Install livecd vim...done"
}

