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
        if ${settings[seperate_home]}; then
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
        if ${settings[seperate_home]}; then
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

# The meat and potatoes
main () {
    # Declare settings assosciative array
    declare -A inst_settings

    display_banner
    define_settings inst_settings
    if ${inst_settings[reinstall]}; then
        echo "wipe_disks"
    else
        echo "prep_disks"
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