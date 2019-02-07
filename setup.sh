#!/bin/bash

#general system/user settings
default_root_password=root
default_username=alarm
custom_username=user
new_password=notsosafe

#rename/move home directory and change login name
usermod -d /home/$custom_username -m $default_username
usermod -l $custom_username $default_username

#set new password for the new password
printf "$new_password\n$new_password\n" | passwd $custom_username

#configure some nameservers to enable internet access within a systemd-nspawn
#container. This change is temporary and will be lost after reoot.
cat >  /etc/resolv.conf <<EOF
# OpenDNS
nameserver 208.67.222.222
nameserver 208.67.220.220

# Cloudflare
nameserver 1.1.1.1
nameserver 1.0.0.1

# Google
nameserver 8.8.8.8
nameserver 8.8.4.4

# Quad9
nameserver 9.9.9.9
nameserver 149.112.112.112
EOF

#init pacman and update the system
pacman-key --init
pacman-key --populate archlinuxarm
pacman -Syu --noconfirm

#install some required and nice to have packages
pacman -S sudo --noconfirm
pacman -S git --noconfirm
pacman -S base-devel --noconfirm
pacman -S wireshark-cli --noconfirm
pacman -S radvd --noconfirm

#give all members of wheel sudo access
sed --in-place -E "s/^#( %wheel ALL=\(ALL\) ALL)/\1/" /etc/sudoers

#enable nopass for all wheel users *temporarily* -> will be reverted later
sudoers_line_wheel_no_pw="%wheel ALL=(ALL) NOPASSWD: ALL"
echo $sudoers_line_wheel_no_pw >> /etc/sudoers

# install wpan-tools
mkdir /opt/src
chown $custom_username /opt/src
cd /opt/src
git clone https://github.com/linux-wpan/wpan-tools
cd /opt/src/wpan-tools
./autogen.sh
./configure CFLAGS='-g -O0' --prefix=/usr --sysconfdir=/etc --libdir=/usr/lib
make
make install

# install lowpan helpers
cd /opt/src
git clone https://github.com/riot-makers/wpan-raspbian
cd wpan-raspbian
cp -r usr/local/sbin/* /usr/local/sbin/.
chmod +x /usr/local/sbin/*
cp etc/default/lowpan /etc/default/.
cp etc/systemd/system/lowpan.service /etc/systemd/system/.
systemctl enable lowpan.service

# install yay
cd /opt/src
git clone https://aur.archlinux.org/yay.git
cd yay
chown -R $custom_username .
#execute su with -l to workaround a build problem in makepgk with go/qemu
curdir=$(pwd)
su -l -c "cd $curdir && makepkg -si --noconfirm" $custom_username

#install current version of kernel and overlays
su -c "yes | yay -S linux-aarch64-raspberrypi-bin raspberrypi-overlays" $custom_username

#enable overlay for the at86rf233 radio module e.g. (openlabs rpi radio)
echo -e "\ndtoverlay=at86rf233" >> /boot/config.txt

#disable nopass for all wheel users -> revert the temporary change from above
sed --in-place "s/^$sudoers_line_wheel_no_pw//" /etc/sudoers
