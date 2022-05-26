# Set ANSI Colors (FG & BG)
readonly BLACK="$(printf '\033[30m')"
readonly RED="$(printf '\033[31m')"
readonly GREEN="$(printf '\033[32m')"
readonly ORANGE="$(printf '\033[33m')"
readonly BLUE="$(printf '\033[34m')"
readonly MAGENTA="$(printf '\033[35m')"
readonly CYAN="$(printf '\033[36m')"
readonly WHITE="$(printf '\033[37m')"
readonly BLACKBG="$(printf '\033[40m')"
readonly REDBG="$(printf '\033[41m')"
readonly GREENBG="$(printf '\033[42m')"
readonly ORANGEBG="$(printf '\033[43m')"
readonly BLUEBG="$(printf '\033[44m')"
readonly MAGENTABG="$(printf '\033[45m')"
readonly CYANBG="$(printf '\033[46m')"
readonly WHITEBG="$(printf '\033[47m')"

# Set other constants
readonly GIT_REPO="maxpower24/shizen-os"
readonly GIT_BRANCH="vb_update"

# Displays the banner
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
		${ORANGE}[*] ${CYAN}Repo: ${GIT_REPO}
		${ORANGE}[*] ${CYAN}Branch: ${GIT_BRANCH}

		Welcome...

	_EOF_
}

var_input () {
    local retry
    local disk
    local disks
    local root_disk
    local home_disk

    while $retry; do
        read -r -p 'Enter username: ' username
        read -r -p 'Enter hostname: ' hostname

        disks=($(fdisk -l | grep "Disk /" | awk '{print $2 $3 $4}' | sed -e 's/,/\)/g' -e 's/\:/\(/g'))

        PS3='Select disk to install root dir on: '
        select disk in "${disks[@]}"; do
            root_disk=$(echo $disk | cut -d '(' -f 1)
            unset 'disks[REPLY-1]'
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

    echo
    echo "${ORANGE}[*] ${GREEN}Installation started...${WHITE}"
    echo
}

user_query () {
    local response
    read -r -p "${1:-Are you sure? [y/N]: }" response
    response=${response,,} # to lowercase
    if [[ $response =~ ^(yes|y)$ ]]; then
        echo true
    else
        echo false
    fi    
}

# The meat and potatoes
main () {
    local username
    local hostname
    local optional_packages
    local reinstall
    local testvar

    testvar=$(user_query "test123")
    echo $testvar

    #testvar=$(user_query)
    if [[ $testvar == true ]]; then
        echo "true"
    else
        echo "false"
    fi

    
    #banner
    #var_test
    #var_input
    #if $reinstall; then
    #    wipe_disks
    #else
    #    prep_disks
    #fi
    #installer
#
    ## Print errors and check for reboot
    #while [[ $REPLY != [YyNn]* ]]; do
    #    read -p "Installation complete, reboot now (y/n)?"
    #    if [[ $REPLY == [Yy]* ]]; then
    #        umount -a
    #        reboot
    #    fi
    #done
}

main