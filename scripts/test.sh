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
readonly GIT_BRANCH="main"

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
    # Set local variables used by this and downstream functions
    local save_settings
    local seperate_home
    local disks
    local disk

    save_settings=false

    # Get user input for variables such as username, hostname, disks, etc... Will loop unless settings are confirmed by user.
    while [[ $save_settings != true ]]; do
        echo
        read -r -p 'Enter username: ' username
        read -r -p 'Enter hostname: ' hostname

        optional_packages=$(user_query "Install optional packages? [y/N]: ")
        reinstall=$(user_query "Reinstall from existing encrypted Arch installation? [y/N]: ")
        seperate_home=$(user_query "Install /home on a seperate disk to /root? [y/N]: ")

        disks=($(fdisk -l | grep "Disk /" | awk '{print $2 $3 $4}' | sed -e 's/,/\)/g' -e 's/\:/\(/g'))
        echo
        PS3='Select disk to install /root on: ' # Could put this block in it's own function since it's repeated, but how could I unset?
        select disk in "${disks[@]}"; do
            root_disk=$(echo $disk | cut -d '(' -f 1)
            unset 'disks[REPLY-1]'
            break
        done
        if [[ $seperate_home == true ]]; then
            echo
            PS3='Select disk to install /home on: '
            select disk in "${disks[@]}"; do
                home_disk=$(echo $disk | cut -d '(' -f 1)
                unset 'disks[REPLY-1]'
                break
            done
        fi

        echo
        echo "Username: $username"
        echo "Hostname: $hostname"
        echo "Install optional packages: $optional_packages"
        echo "Reinstall: $reinstall"
        echo "Install /root on: $root_disk"
        if [[ $seperate_home == true ]]; then
            echo "Install /home on: $home_disk"
        fi
        echo

        save_settings=$(user_query "Are these settings correct? [y/N]: ")
    done

    echo
    echo "${ORANGE}[*] ${GREEN}Installation started...${WHITE}"
    echo
}

user_query () {
    # Function for getting user input with true or false output.
    local response
    while [[ $response != [yn]* ]]; do
        read -r -p "${1:-Are you sure? [y/N]: }" response
        response=${response,,} # to lowercase
        if [[ $response =~ ^(yes|y)$ ]]; then
            echo true
        else
            echo false
        fi
    done
}

# The meat and potatoes
main () {
    # Set local variables used by this and downstream functions
    local username
    local hostname
    local optional_packages
    local reinstall
    local root_disk
    local home_disk

    banner
    var_input
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