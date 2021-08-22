#!/bin/bash

# Arch Install Script by maxpower24
# Last updated 22.8.21

# This is a custom arch install script so I don't have to manually go through the steps each time.
# It allows for input so I can adapt to each device but it's written to fit my needs so I don't recommend using it without reading through it first.
# Eventually I might create an archiso with calamares to replace this process.

# Set static variables
username='maxpower'
errorlog=$'Errors:\n'
gituser="maxpower24"
gitrepo="shizen-os"
gitbranch="main"
rawgiturl="https://raw.githubusercontent.com/$gituser/$gitrepo/$gitbranch"

# Welcome message and list connected disks and sizes
echo -e "\nWelcome $username...\n"
echo 'Connected disks: '
parted -l | grep 'Disk /' | cut -d " " -f 2,3

# While loop for selecting and confirming primary/secondary disks and if new partition tables are needed
retry=true
while $retry
do
    echo
    PS3=' Please enter the primary disk: '
    disks=$(sudo parted -l | grep "Disk /" | cut -d ' ' -f 2 | sed 's/.$//')
    choices=( $disks )
    select answer in "${choices[@]}"
    do
        for choice in "${choices[@]}"
        do
            if [[ $choice == $answer ]]
            then
                primdisk=$choice
                break 2
            fi
        done
    done

    echo
    PS3=' Please enter the secondary disk: '
    choices=( "${choices[@]/$primdisk}" )
    select answer in ${choices[@]}
    do
        for choice in ${choices[@]}
        do
            if [[ $choice == $answer ]]
            then
                secdisk=$choice
                break 2
            fi
        done
    done

    newpart=false
    echo
    read -p 'Do you need to create new parition tables (y/n)? ' -n 1 -r
    echo
    if [[ $REPLY == [Yy]* ]]
    then
        newpart=true
    fi

    installssh=false
    echo
    read -p 'Install OpenSSH server (y/n)? ' -n 1 -r
    echo
    if [[ $REPLY == [Yy]* ]]
    then
        installssh=true
    fi

    echo
    read -p 'Enter hostname: ' hostname

    echo
    echo "Primary disk: $primdisk"
    echo "Secondary disk: $secdisk"
    echo "New partition table: $newpart"
    echo "Hostname: $hostname"
    echo "Install OpenSSH server: $installssh"
    echo "Git branch: $gitbranch"
    echo

    read -p "Are these settings correct (y/n)? " -n 1 -r
    echo
    if [[ $REPLY == [Yy]* ]]
    then
        retry=false
    fi
done

# Partition the drives for UEFI on GPT.
if $newpart
then
    parted -s -a optimal $primdisk \
        mklabel gpt \
        mkpart "'"'"EFI system partition"'"'" fat32 1MiB 521MiB \
        mkpart "'"'"root partition"'"'" ext4 521MiB 100% \
        set 1 esp on

    parted -s -a optimal $secdisk \
        mklabel gpt \
        mkpart "'"'"home partition"'"'" ext4 0% 100%
fi

# Assign partition numbers
if [[ $primdisk == *nvme* ]]
then
    primdisk=$primdisk'p'
elif [[ $secdisk == *nvme* ]]
then
    secdisk=$secdisk'p'
fi

efipart=$primdisk'1'
rootpart=$primdisk'2'
homepart=$secdisk'1'

# Format the partitions
mkfs.fat -F 32 $efipart
mkfs.ext4 $rootpart
mkfs.ext4 $homepart

# Make directories and mount the new partitions on "/"", "/efi" and "/home"
mount $rootpart /mnt
mkdir /mnt/efi /mnt/home
mount $efipart /mnt/efi
mount $homepart /mnt/home

# Update the system clock
timedatectl set-ntp true

# Copy the mirror list
curl -L $rawgiturl/etc/pacman.d/mirrorlist -o /etc/pacman.d/mirrorlist

# Enable multilib repo in live environment for 32-bit packages
curl -L $rawgiturl/etc/pacman.conf -o /etc/pacman.conf

# Install pacstrap packages
curl -L $rawgiturl/packages -o packages
sed -i '/^[[:blank:]]*#/d;s/#.*//' packages
pacstrap /mnt - < packages

# Generate the fstab file to save mounted drives
genfstab -U /mnt > /mnt/etc/fstab

# Change root and run setup script
curl -L $rawgiturl/scripts/rootinstall.sh -o /mnt/rootinstall.sh
chmod +x /mnt/rootinstall.sh
arch-chroot /mnt ./rootinstall.sh $username $hostname $installssh $gituser $gitrepo $gitbranch
rm /mnt/rootinstall.sh

# Print errors and check for reboot
echo
echo "$errorlog"
read -p "Installation complete, reboot now (y/n)?" -n 1 -r
echo
if [[ $REPLY == [Yy]* ]]
then
    reboot
fi