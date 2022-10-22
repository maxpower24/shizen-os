#!/bin/bash

# Arch Install Script by maxpower24
# Last updated 11.05.2022

# Custom script to install arch and all required packages and configs.
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

# The meat and potatoes
main () {
    banner # Calls the banner function below, only displays does nothing else
    var_input
    if [[ $reinstall == false ]]; then
        prep_disks
    elif [[ $reinstall == true ]]; then
        wipe_disks
    fi
    installer

    # Print errors and check for reboot
    while [[ $REPLY != [YyNn]* ]]; do
        read -p "Installation complete, reboot now (y/n)?"
        if [[ $REPLY == [Yy]* ]]; then
            umount -a
            reboot
        fi
    done
}

# Displays the banner, nothing else
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

prep_disks () {
    # Partition the drives for UEFI on GPT.
    parted -s -a optimal $root_disk \
        mklabel gpt \
        mkpart "'"'"EFI system partition"'"'" fat32 1MiB 512MiB \
        mkpart "'"'"root partition"'"'" ext4 512MiB 75% \
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

wipe_disks () {
    get_partitions
    cryptsetup open $root_part cryptroot
    mount /dev/mapper/cryptroot /mnt
    mount $boot_part /mnt/boot
    cd /mnt && rm -r *
}

installer () {
    # Update the system clock
    timedatectl set-ntp true

    # Copy the mirror list
    sleep 2
    curl -L $raw_git_url/etc/pacman.d/mirrorlist -o /etc/pacman.d/mirrorlist

    # Enable multilib repo in live environment for 32-bit packages
    sleep 2
    curl -L $raw_git_url/etc/pacman.conf -o /etc/pacman.conf

    # Install pacstrap packages
    sleep 2
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
    sleep 2
    chmod +x /mnt/rootinstall.sh
    sleep 2
    arch-chroot /mnt ./rootinstall.sh $username $hostname $git_repo $git_branch $install_ssh $root_part
    rm /mnt/rootinstall.sh
}

get_partitions () {
    # Assign partition numbers
    if [[ $root_disk == *nvme* ]]; then
        root_disk=$root_disk'p'
    fi
    boot_part=$root_disk'1'
    root_part=$root_disk'2'
}

main