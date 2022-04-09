# Install yay
mkdir ~/temp/yay
git clone https://aur.archlinux.org/yay.git ~/temp/yay
( cd ~/temp/yay && makepkg -i )

# Install yay packages
yay -S spotify protonvpn unityhub code-marketplace polybar

# Firewall config
sudo ufw default deny incoming
#sudo ufw allow ssh
sudo ufw default allow outgoing
sudo ufw enable

cat <<- _EOF_
    To Do:
    - Install VSCode extensions.    
_EOF_