# Get piped variables and set static ones
username=$1
hostname=$2
git_repo=$3
git_branch=$4
install_ssh=$5
root_part=$6
home_dir="/home/$username"

# Set Swap File
fallocate -l 16GB /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap defaults 0 0' >> /etc/fstab

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

# Edit mkinitcpio hooks
sed -i "s/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base udev autodetect keyboard keymap modconf block encrypt filesystems resume keyboard fsck)/g" /etc/mkinitcpio.conf
mkinitcpio -p linux

# Install and configure GRUB boot loader with microcode
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
root_uuid=($(blkid | grep $root_part | awk '{print $2}' | sed  's/"//g'))
swap_uuid=($(findmnt -no UUID -T /swapfile))
swap_off=($(filefrag -v /swapfile | awk '$1=="0:" {print substr($4, 1, length($4)-2)}'))
sed -i "s@GRUB_CMDLINE_LINUX=\"\"@GRUB_CMDLINE_LINUX=\"cryptdevice=$root_uuid:cryptroot root=/dev/mapper/cryptroot resume=UUID=$swap_uuid resume_offset=$swap_off\"@g" /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# Create home folders
mkdir $home_dir/audio
mkdir $home_dir/bin
mkdir $home_dir/docs
mkdir $home_dir/downloads
mkdir $home_dir/games
mkdir $home_dir/pics
mkdir $home_dir/source
mkdir $home_dir/temp
mkdir $home_dir/vids

# Clone dotfiles repo
local_repo="$home_dir/shizen-os"
git clone -b $git_branch https://github.com/$git_repo $local_repo

# Copy config and other dotfile data
cp -r "$local_repo/wallpapers" $home_dir/pics
cp -r "$local_repo/dotfiles/." $home_dir
cp -r "$local_repo/etc/." /etc

# Enable services
systemctl enable lightdm
systemctl enable NetworkManager
systemctl enable ufw

# SSH for testing
if $install_ssh; then
    systemctl enable sshd
fi

# Change ownership for all contents of home folder
chown -R $username:$username $home_dir

# Exit chroot
echo
read -p "Exit chroot (y/n)?" -n 1 -r
echo
if [[ $REPLY == [Yy]* ]]
then
    exit
fi