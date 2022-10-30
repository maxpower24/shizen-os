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

# Remove everything from /root and optionally /home
wipe_disks () {
    local wipe_home

    wipe_home=false
    if [[ inst_settings[seperate_home] == true ]]; then
        wipe_home=$(user_query "Wipe /home as well? [y/N]: ")
    fi
    get_partitions
    cryptsetup open $root_part cryptroot
    mount /dev/mapper/cryptroot /mnt
    if [[ $wipe_home == true ]]; then
        cryptsetup open $home_part crypthome
        mount /dev/mapper/crypthome /mnt/home
    fi
    mount $boot_part /mnt/boot
    cd /mnt && rm -r *
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
    local raw_git_url="$GIT_REPO/$GIT_BRANCH" # "https://raw.githubusercontent.com/$GIT_REPO/$GIT_BRANCH"

    # Update the system clock
    timedatectl set-ntp true

    # Copy the mirror list
    cp $raw_git_url/etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist
    #curl -L $raw_git_url/etc/pacman.d/mirrorlist -o /etc/pacman.d/mirrorlist

    # Enable multilib repo in live environment for 32-bit packages
    cp $raw_git_url/etc/pacman.conf /etc/pacman.conf
    #curl -L $raw_git_url/etc/pacman.conf -o /etc/pacman.conf

    # Install pacstrap packages
    cp $raw_git_url/packages packages
    #curl -L $raw_git_url/packages -o packages
    if $install_ssh; then
        echo -e "\nopenssh" >> packages
    fi
    sed -i '/^[[:blank:]]*#/d;s/#.*//' packages
    sleep 2
    pacstrap /mnt - < packages

    # Generate the fstab file to save mounted drives
    genfstab -U /mnt > /mnt/etc/fstab

    # Change root and run setup script
    cp $raw_git_url/scripts/rootinstall.sh /mnt/rootinstall.sh
    #curl -L $raw_git_url/scripts/rootinstall.sh -o /mnt/rootinstall.sh
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
    if $reinstall; then
        echo
        #wipe_disks
    else
        prep_disks
    fi
    installer

    ## Print errors and check for reboot
    while [[ $REPLY != [YyNn]* ]]; do
        read -p "Installation complete, reboot now (y/n)?"
        if [[ $REPLY == [Yy]* ]]; then
            umount -a
            reboot
        fi
    done
}

main