#!/bin/bash

# Arch Install Script by maxpower24
# Last updated 22.8.21

# This is a custom arch install script so I don't have to manually go through the steps each time.
# It allows for input so I can adapt to each device but it's written to fit my needs so I don't recommend using it without reading through it first.
# Eventually I might create an archiso with calamares to replace this process.

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
    banner
    var_input
    if [[ $reinstall == false ]]; then
        prep_disks
    elif [[ $reinstall == true ]]; then
        wipe_disks
    fi
    install

    # Print errors and check for reboot
    while [[ $REPLY != [YyNn]* ]]; do
        read -p "Installation complete, reboot now (y/n)?"
        if [[ $REPLY == [Yy]* ]]; then
            reboot
        fi
    done
}

banner () {
    clear
    cat <<- _EOF_
		${CYAN}┌─────────────────────────────────────┐
		│░░░█▀▀░█░█░█░▀▀█░█▀▀░█▖█░░░█▀█░█▀▀░░░│
		│░░░▀▀█░█▀█░█░▄▀ ░█▀▀░█▝█░░░█░█░▀▀█░░░│
		│░░░▀▀▀░▀░▀░▀░▀▀▀░▀▀▀░▀░▀░░░▀▀▀░▀▀▀░░░│
		└─────────────────────────────────────┘
		${GREEN}[*] ${ORANGE}By: Max Power
		${GREEN}[*] ${ORANGE}Github: @maxpower24
		${GREEN}[*] ${ORANGE}Repo: ${git_repo}
		${GREEN}[*] ${ORANGE}Branch: ${git_branch}

		Welcome...

	_EOF_
}

var_input () {
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

prep_disks () {
    # Partition the drives for UEFI on GPT.
    parted -s -a optimal $root_disk \
        mklabel gpt \
        mkpart "'"'"EFI system partition"'"'" fat32 1MiB 521MiB \
        mkpart "'"'"root partition"'"'" ext4 521MiB 100% \
        set 1 esp on

    parted -s -a optimal $home_disk \
        mklabel gpt \
        mkpart "'"'"home partition"'"'" ext4 0% 100%

    # Assign partition numbers
    if [[ $root_disk == *nvme* ]]; then
        root_disk=$root_disk'p'
    elif [[ $home_disk == *nvme* ]]; then
        home_disk=$home_disk'p'
    fi
    efipart=$root_disk'1'
    rootpart=$root_disk'2'
    homepart=$home_disk'1'

    # Format the partitions
    mkfs.fat -F 32 $efipart
    mkfs.ext4 $rootpart
    mkfs.ext4 $homepart

    # Make directories and mount the new partitions on "/"", "/efi" and "/home"
    mount $rootpart /mnt
    mkdir /mnt/efi /mnt/home
    mount $efipart /mnt/efi
    mount $homepart /mnt/home
}

wipe_disks () {
    echo "in progress"
}

install () {
    # Update the system clock
    timedatectl set-ntp true

    # Copy the mirror list
    curl -L $raw_git_url/etc/pacman.d/mirrorlist -o /etc/pacman.d/mirrorlist

    # Enable multilib repo in live environment for 32-bit packages
    curl -L $raw_git_url/etc/pacman.conf -o /etc/pacman.conf

    # Install pacstrap packages
    curl -L $raw_git_url/packages -o packages
    if $install_ssh; then
        echo "openssh"
    sed -i '/^[[:blank:]]*#/d;s/#.*//' packages
    read -p "Press enter to continue"
    pacstrap /mnt - < packages

    # Generate the fstab file to save mounted drives
    genfstab -U /mnt > /mnt/etc/fstab

    # Change root and run setup script
    curl -L $raw_git_url/scripts/rootinstall.sh -o /mnt/rootinstall.sh
    chmod +x /mnt/rootinstall.sh
    arch-chroot /mnt ./rootinstall.sh $username $hostname $raw_git_url $install_ssh
    rm /mnt/rootinstall.sh
}

main