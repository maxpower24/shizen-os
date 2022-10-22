# shizen-os
If you're not me you can stop reading through my crappy little arch project. This is only public so I can access the files easily during install.

## Drive Preperation
Below are manual steps required to format and cryptographically erase data. Should only need to be done once on a device if I don't remove encryption.

### Format NVME and set sector size to 4 Kib
nvme format /dev/nvme0 -s 1 -n 1 -l 1

### Secure erase the disk (note - takes a long ass time)
cryptsetup open --type plain -d /dev/urandom /dev/nvme0n1 to_be_wiped
dd if=/dev/zero of=/dev/mapper/to_be_wiped status=progress
cryptsetup close to_be_wiped

## Installation guide
1. Connect to internet with iwctl
2. Download install script with curl
3. Run install script and follow the prompts
4. Run umount -a and reboot after exiting arch-chroot

## To Do List
- Continue down the arch general recommendations
- Decide on a theme/background
- Create a cheatsheet for shortcuts
- Configure taskbar
- Rofi config
- Install apps
- Figure out what can be themed and how
- Secure Boot
- Filesystem encryption for cloud sync

## Done
- ~~Basic desktop environment install script~~
- ~~Touchpad drivers~~
- ~~Add dm-crypt stuff to install scripts~~
- ~~Swap file~~
- ~~Audio & Bluetooth~~
- ~~Hibernation~~
- ~~Decrease swappiness~~
- ~~Login on resume from sleep~~

## Cheat Sheets
https://i3wm.org/docs/refcard.html

## Design Ideas
Polybar 
- Left: clock, media controls, global menu (?)
- Centre: Page indicators
- Right: Sound, Brightness, Ram, SSD, CPU, Wifi, BT, Battery, Power

Rofi
- Bring up on left side?
- Add icons and limit apps

Colour scheme - start with making everything gruvbox or everforest?

## OLD Issues / Bugs / Todo
- image previews in kitty
- opne text files in nvim from ranger
- colour schemes
- fonts