#!/bin/bash

# multilib
sudo sh -c "sed -i '/\[multilib\]/,/Include/s/^[ ]*#//' /etc/pacman.conf"
sudo pacman -Syy

# fish shell
sudo pacman --needed --noconfirm -Syu fish
cat <<EOF >> .bashrc
if [[ $- == *i* ]]; then 
    exec fish
fi
EOF

# aurman
sudo pacman --needed --noconfirm -Syu git
git clone https://aur.archlinux.org/aurman-git.git
cd aurman-git/
makepkg -si --needed --noconfirm
cd ..
rm -rf aurman-git/

# makepkg
aurman --needed --noconfirm --noedit -Syu ccache
sudo sh -c "sed -i '/^[ ]*BUILDENV=/s/!ccache/ccache/' /etc/makepkg.conf"
grep "^[ ]*export PATH=\"/usr/lib/ccache/bin/:\$PATH\"" ~/.bashrc >/dev/null
if [ "$?" -eq 1 ]
then
    echo "export PATH=\"/usr/lib/ccache/bin/:\$PATH\"" >> ~/.bashrc
fi
fish -c "set -U fish_user_paths /usr/lib/ccahce/bin"
sudo sh -c "sed -i '/MAKEFLAGS=/s/^.*$/MAKEFLAGS=\"-j\$(nproc)\"/' /etc/makepkg.conf"
sudo sh -c "sed -i '/PKGEXT=/s/^.*$/PKGEXT=\".pkg.tar\"/' /etc/makepkg.conf"

# mirrors
aurman --needed --noconfirm --noedit -Syu reflector
sudo reflector --save /etc/pacman.d/mirrorlist --sort rate --age 1 --country Germany --latest 10 --score 10 --number 5 --protocol http
sudo pacman --noconfirm -Syyu

# xorg + kde
aurman --needed --noconfirm --noedit -Syu xorg-server networkmanager sddm plasma dolphin konsole yakuake
sudo systemctl enable sddm
sudo systemctl enable NetworkManager

# nvidia
aurman --needed --noconfirm --noedit -Syu nvidia-dkms lib32-nvidia-utils dkms linux-headers nvidia-settings

# nano environment variable
grep "^[ ]*export EDITOR=\"/usr/bin/nano\"" ~/.bashrc >/dev/null
if [ "$?" -eq 1 ]
then
    echo "export EDITOR=\"/usr/bin/nano\"" >> ~/.bashrc
fi
sudo sh -c "grep '^[ ]*Defaults[ ]\+env_keep[ ]*+=[ ]*\"[ ]*EDITOR[ ]*\"' /etc/sudoers >/dev/null"
if [ "$?" -eq 1 ]
then
    echo 'Defaults env_keep += "EDITOR"' | sudo EDITOR='tee -a' visudo
fi
fish -c "set -Ux EDITOR /usr/bin/nano"

# time
sudo timedatectl set-ntp true

# ssh
aurman --needed --noconfirm --noedit -Syu openssh
sudo sh -c "sed -i '/^[ ]*[#]*[ ]*PasswordAuthentication[ ]\+/s/^.*$/PasswordAuthentication no/' /etc/ssh/sshd_config"
sudo sh -c "sed -i '/^[ ]*[#]*[ ]*PermitRootLogin[ ]\+/s/^.*$/PermitRootLogin no/' /etc/ssh/sshd_config"
sudo systemctl enable sshd

# miscellaneous
aurman --needed --noconfirm --noedit -Syu net-tools ntfs-3g android-tools android-udev google-chrome jdk rsync htop nload netdata wireshark-qt
sudo gpasswd -a $USER adbusers
sudo gpasswd -a $USER wireshark
sudo systemctl enable netdata
