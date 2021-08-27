#!/bin/bash

## ANSI Colors (FG & BG)
RED="$(printf '\033[31m')"  GREEN="$(printf '\033[32m')"  ORANGE="$(printf '\033[33m')"  BLUE="$(printf '\033[34m')"
MAGENTA="$(printf '\033[35m')"  CYAN="$(printf '\033[36m')"  WHITE="$(printf '\033[37m')" BLACK="$(printf '\033[30m')"
REDBG="$(printf '\033[41m')"  GREENBG="$(printf '\033[42m')"  ORANGEBG="$(printf '\033[43m')"  BLUEBG="$(printf '\033[44m')"
MAGENTABG="$(printf '\033[45m')"  CYANBG="$(printf '\033[46m')"  WHITEBG="$(printf '\033[47m')" BLACKBG="$(printf '\033[40m')"

# Set global variables
git_repo="maxpower24/shizen-os"
git_branch="main"
raw_git_url="https://raw.githubusercontent.com/$git_repo/$git_branch"
install_ssh=false
reinstall=false

main () {
    reset_color
    banner
    user_input
    if [[ $reinstall == false ]]; then
        echo "Create partitions, format drives, make directoris, mount the partitions"
    elif [[ $reinstall == true ]]; then
        echo "mount the paritions, remove all, create directories"
    fi
    echo "pacstrap and beyond"
}

banner () {
    clear
    cat <<- _EOF_
		${GREEN}┌─────────────────────────────────────┐
		│░░░█▀▀░█░█░█░▀▀█░█▀▀░█▖█░░░█▀█░█▀▀░░░│
		│░░░▀▀█░█▀█░█░▄▀ ░█▀▀░█▝█░░░█░█░▀▀█░░░│
		│░░░▀▀▀░▀░▀░▀░▀▀▀░▀▀▀░▀░▀░░░▀▀▀░▀▀▀░░░│
		└─────────────────────────────────────┘
		${ORANGE}[*] ${CYAN}By: Max Power
		${ORANGE}[*] ${CYAN}Github: @maxpower24
		${ORANGE}[*] ${CYAN}Repo: ${git_repo}
		${ORANGE}[*] ${CYAN}Branch: ${git_branch}

		Welcome...

	_EOF_
}

user_input () {
    local retry=true
    local answer=""
    local line=""
    local disk=""
    local disks=()
    local lines=($(parted -l | grep "Disk /" | sed -e 's/^[^ ]* //' -e 's/ //g'))

    while $retry; do
        read -p 'Enter username: ' username
        read -p 'Enter hostname: ' hostname

        for line in ${lines[@]}; do
            disk=$(echo $line | sed 's/:/: /g')
            disks+=("$disk")
        done

        PS3='Select disk to install root dir on: '
        select answer in "${disks[@]}"; do
            root_disk=$(echo $answer | cut -d ' ' -f 1 | sed 's/.$//')
            unset 'disks[REPLY-1]'
            break
        done

        PS3='Select disk to install home dir on: '
        select answer in "${disks[@]}"; do
            home_disk=$(echo $answer | cut -d ' ' -f 1 | sed 's/.$//')
            break
        done

        while [[ $REPLY != [YyNn]* ]]; do
            read -p 'Reinstall from existing Arch install (y/n)? ' 
            if [[ $REPLY == [Yy]* ]]; then
                reinstall=true
            fi
        done
        unset REPLY

        while [[ $REPLY != [YyNn]* ]]; do
            read -p 'Install OpenSSH server (y/n)? ' 
            if [[ $REPLY == [Yy]* ]]; then
                install_ssh=true
            fi
        done
        unset REPLY

        echo
        echo "Username: $username"
        echo "Hostname: $hostname"
        echo "Install root dir on: $root_disk"
        echo "Install home dir on: $home_disk"
        echo "Reinstall: $reinstall"
        echo "Install OpenSSH: $install_ssh"
        echo

        while [[ $REPLY != [YyNn]* ]]; do
            read -p "Are these settings correct (y/n)? "
            if [[ $REPLY == [Yy]* ]]; then
                retry=false
            fi
        done
    done
}

## Reset terminal colors
reset_color() {
	tput sgr0   # reset attributes
	tput op     # reset color
    return
}

main