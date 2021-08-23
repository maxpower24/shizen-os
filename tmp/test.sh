## ANSI Colors (FG & BG)
RED="$(printf '\033[31m')"  GREEN="$(printf '\033[32m')"  ORANGE="$(printf '\033[33m')"  BLUE="$(printf '\033[34m')"
MAGENTA="$(printf '\033[35m')"  CYAN="$(printf '\033[36m')"  WHITE="$(printf '\033[37m')" BLACK="$(printf '\033[30m')"
REDBG="$(printf '\033[41m')"  GREENBG="$(printf '\033[42m')"  ORANGEBG="$(printf '\033[43m')"  BLUEBG="$(printf '\033[44m')"
MAGENTABG="$(printf '\033[45m')"  CYANBG="$(printf '\033[46m')"  WHITEBG="$(printf '\033[47m')" BLACKBG="$(printf '\033[40m')"

# Set static variables
username='maxpower'
errorlog=$'Errors:\n'
gitrepo="maxpower24/shizen-os"
gitbranch="main"
rawgiturl="https://raw.githubusercontent.com/$gitrepo/$gitbranch"

# Welcome message and list connected disks and sizes
echo -e "\nWelcome $username...\n"
echo 'Connected disks: '
parted -l | grep 'Disk /' | cut -d " " -f 2,3

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

## Banner
banner () {
    #clear
    cat <<- _EOF_
		${GREEN}┌──────────────────────────────────────────────────┐
		│░░░█▀█░█▀▄░█▀▀░█░█░█▀▀░█▀▄░█▀█░█▀▀░▀█▀░░░█▀█░█▀▀░░│
		│░░░█▀█░█▀▄░█░░░█▀█░█░░░█▀▄░█▀█░█▀▀░░█░░░░█░█░▀▀█░░│
		│░░░▀░▀░▀░▀░▀▀▀░▀░▀░▀▀▀░▀░▀░▀░▀░▀░░░░▀░░░░▀▀▀░▀▀▀░░│
		└──────────────────────────────────────────────────┘
		${GREEN}[*] ${MAGENTA}By: Max Power
		${GREEN}[*] ${MAGENTA}Github: @maxpower24
	_EOF_
}

banner