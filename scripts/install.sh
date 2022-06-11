#!/bin/bash

# Arch Install Script by maxpower24
# Last updated 11.05.2022

# Custom script to install arch and all required packages and configs.
# Eventually I might create an archiso with calamares to replace this process but this is a learning experience

# CONVENTIONS TO REMEMBER
# use local variables within functions
# naming - run_function, my_variable, MY_CONSTANT, _eval_variable
# set statements and constants -> functions -> main function -> run main
# functions should return some values instead of modifying global variables

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
display_banner () {
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

# Function to define settings used by the installation via user input
define_settings () {
    # Declare local variables and array
    local save_settings=false
    local disks
    local index

    declare -n settings="$1"

    # Get user input for variables such as username, hostname, disks, etc... Will loop unless settings are confirmed by user.
    while [[ $save_settings != true ]]; do
        echo
        read -r -p 'Enter username: ' settings[username]
        read -r -p 'Enter hostname: ' settings[hostname]

        # Use ask_user function to define variables with true/false.
        settings[optional_packages]=$(ask_user "Install optional packages? [y/N]: ")
        settings[reinstall]=$(ask_user "Reinstall from existing encrypted Arch installation? [y/N]: ")
        settings[seperate_home]=$(ask_user "Install /home on a seperate disk to /root? [y/N]: ")

        # Get list of disks and pass on to function to define root disk. If user wants a seperate home disk, unset the root disk and pass remaining ones on to the function to define.
        disks=($(fdisk -l | grep "Disk /" | awk '{print $2 $3 $4}' | sed -e 's/,/\)/g' -e 's/\:/\(/g'))
        settings[root_disk]=$(define_disk "/root" "${disks[@]}" | tr -d '\n')
        if [[ ${settings[seperate_home]} == true ]]; then
            for index in "${!disks[@]}"; do
                if [[ "${disks[$index]}" == *"${settings[root_disk]}"* ]]; then
                    unset 'disks[index]'
                fi
            done
            settings[home_disk]=$(define_disk "/home" "${disks[@]}" | tr -d '\n')
        fi

        # Print out current settings and confirm with user
        echo
        echo "Username: ${settings[username]}"
        echo "Hostname: ${settings[hostname]}"
        echo "Install optional packages: ${settings[optional_packages]}"
        echo "Reinstall: ${settings[reinstall]}"
        echo "Install /root on: ${settings[root_disk]}"
        if [[ ${settings[seperate_home]} == true ]]; then
            echo "Install /home on: ${settings[home_disk]}"
        fi
        echo

        save_settings=$(ask_user "Are these settings correct? [y/N]: ")
    done

    echo
    echo "${ORANGE}[*] ${GREEN}Installation started...${WHITE}"
    echo
}

# Function for getting user input with true or false output. If a question is input as a parameter it will use that, otherwise default one is defined
ask_user () {
    # Define local variables used by this and downstream functions
    local response

    while [[ $response != [yn]* ]]; do
        read -r -p "${1:-Are you sure? [y/N]: }" response
        response=${response,,} # to lowercase
    done
    if [[ $response =~ ^(yes|y)$ ]]; then
        echo true
    else
        echo false
    fi
}

# Function to assign disks to a variable.
define_disk () {
    # Define local variables used by this and downstream functions
    local dir
    local disk_arr
    local disk

    # Define the directory from first parameter, shift all params to the left and all remaining are part of the disk array
    dir=$1
    shift
    disk_arr=($@)

    # Select disk from given array
    echo
    PS3="Select disk to install $dir on: "
    select disk in "${disk_arr[@]}"; do
        echo $disk | cut -d '(' -f 1
        break
    done
}

# Remove everything from /root and optionally /home
wipe_disks () {
    local seperate_home=$1
    local root_disk=$2
    local home_disk=$3
    local wipe_home

    if [[ $seperate_home == true ]]; then
        wipe_home=$(user_query "$(ORANGE)INPUT REQUIRED: $(GREEN)Wipe /home as well? [y/N]: $(WHITE)")
    fi
    echo $seperate_home $root_disk $home_disk
    #get_partitions
    #cryptsetup open $root_part cryptroot
    #mount /dev/mapper/cryptroot /mnt
    #if [[ $wipe_home == true ]]; then
    #    cryptsetup open $home_part crypthome
    #    mount /dev/mapper/crypthome /mnt/home
    #fi
    #mount $boot_part /mnt/boot
    #cd /mnt && rm -r *
}

prep_disks () {
    # Partition the drives for UEFI on GPT.
    parted -s -a optimal $root_disk \
        mklabel gpt \
        mkpart "'"'"EFI system partition"'"'" fat32 1MiB 512MiB \
        mkpart "'"'"root partition"'"'" ext4 512MiB 100% \
        set 1 esp on

    get_partitions

    # Format and encrypt partitions
    cryptsetup -y -v luksFormat $root_part
    cryptsetup open $root_part cryptroot
    mkfs.ext4 /dev/mapper/cryptroot
    mkfs.fat -F 32 $boot_part

    # Make directories and mount the new partitions on "/"", "/efi" and "/home"
    mount /dev/mapper/cryptroot /mnt
    mkdir /mnt/boot /mnt/home
    mount $boot_part /mnt/boot
}

# Assign partition numbers
get_partitions () {
    if [[ $root_disk == *nvme* ]]; then
        root_disk=$root_disk'p'
    fi
    boot_part=$root_disk'1'
    root_part=$root_disk'2'
}

installer () {
    local raw_git_url="https://raw.githubusercontent.com/$GIT_REPO/$GIT_BRANCH"

    # Update the system clock
    timedatectl set-ntp true

    # Copy the mirror list
    curl -L $raw_git_url/etc/pacman.d/mirrorlist -o /etc/pacman.d/mirrorlist

    # Enable multilib repo in live environment for 32-bit packages
    curl -L $raw_git_url/etc/pacman.conf -o /etc/pacman.conf

    # Install pacstrap packages
    curl -L $raw_git_url/packages -o packages
    if $install_ssh; then
        echo -e "\nopenssh" >> packages
    fi
    sed -i '/^[[:blank:]]*#/d;s/#.*//' packages
    sleep 2
    pacstrap /mnt - < packages

    # Generate the fstab file to save mounted drives
    genfstab -U /mnt > /mnt/etc/fstab

    # Change root and run setup script
    curl -L $raw_git_url/scripts/rootinstall.sh -o /mnt/rootinstall.sh
    chmod +x /mnt/rootinstall.sh
    arch-chroot /mnt ./rootinstall.sh $username $hostname $GIT_REPO $GIT_BRANCH $install_ssh $root_part
    rm /mnt/rootinstall.sh
}

# The meat and potatoes
main () {
    # Declare settings assosciative array
    declare -A inst_settings

    display_banner
    define_settings inst_settings
    if [[ ${inst_settings[reinstall]} == true ]]; then
        wipe_disks ${inst_settings[seperate_home]} ${inst_settings[root_disk]} ${inst_settings[home_disk]}
    else
        #prep_disks
    fi
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