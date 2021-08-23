# Get piped variables and set static ones
username=$1
hostname=$2
installssh=$3
gitrepo=$4
gitbranch=$5
homedir="/home/$username"

# Set the time zone
ln -sf /usr/share/zoneinfo/Australia/Melbourne /etc/localtime
hwclock --systohc

# Localization
sed -i "s/#en_AU.UTF-8/en_AU.UTF-8/g" /etc/locale.gen
sed -i "s/#en_US.UTF-8/en_US.UTF-8/g" /etc/locale.gen
locale-gen
echo LANG=en_AU.UTF-8 > /etc/locale.conf

# Set hostname and hosts files
echo $hostname > /etc/hostname
echo 127.0.0.1 localhost > /etc/hosts
echo ::1 localhost >> /etc/hosts
echo 127.0.1.1 $hostname.localdomain $hostname >> /etc/hosts

# Add user and configure sudo
useradd -m -G adm -s /usr/bin/zsh $username
echo $username' ALL=(ALL) ALL' | sudo EDITOR='tee -a' visudo
passwd $username

# Install and configure GRUB boot loader with microcode
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Create home folders
mkdir $homedir/audio
mkdir $homedir/bin
mkdir $homedir/docs
mkdir $homedir/downloads
mkdir $homedir/games
mkdir $homedir/pics
mkdir $homedir/source
mkdir $homedir/temp
mkdir $homedir/vids

# Clone dotfiles repo
dotfiles="$homedir/dotfiles"
git clone -b $gitbranch https://github.com/$gitrepo $dotfiles

# Copy config and other dotfile data
config="$dotfiles/config"
cp -r "$dotfiles/wallpapers" $homedir/pics
cp -r "$dotfiles/dotfiles/." $homedir

# Enable services
systemctl enable lightdm
systemctl enable dhcpcd
systemctl enable ufw

# SSH for testing
if [[ $installssh == true ]]
then
    pacman -S --noconfirm openssh
    systemctl enable sshd
fi

# Change ownership for all contents of home folder
chown -R $username:$username $homedir

# Exit chroot
echo
read -p "Exit chroot (y/n)?" -n 1 -r
echo
if [[ $REPLY == [Yy]* ]]
then
    exit
fi