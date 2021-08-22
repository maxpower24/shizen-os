# Install yay
mkdir ~/temp/yay
git clone https://aur.archlinux.org/yay.git ~/temp/yay
( cd ~/temp/yay && makepkg -i )

# Install yay packages
yay -S protonvpn unityhub code-marketplace

# Firewall config
sudo ufw default deny incoming
sudo ufw allow ssh
sudo ufw default allow outgoing
sudo ufw enable