#!/bin/sh

function tester () {
    local string=$1
    echo 'test'
    echo $string
}

function wipe_disks () {
    local wipe_home=$1
    local root_part=$2
    local home_part=$3

    echo $root_part $home_part $wipe_home
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

function prep_disks (){
    echo 'prep'
}