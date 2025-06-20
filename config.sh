#!/bin/bash
#
set -euxo pipefail

# functions
#
test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile

# selinux, needed for kde and maybe others
#
setsebool -P selinuxuser_execmod 1

# set a hostname
#
echo "pumice" > /etc/hostname

# clear machine id and random seed
#
rm -f /etc/machine-id
echo 'uninitialized' > /etc/machine-id
rm -f /var/lib/systemd/random-seed

# grub
#
echo "GRUB_DEFAULT=saved" >> /etc/default/grub
echo "GRUB_DISABLE_SUBMENU=true" >> /etc/default/grub
echo "GRUB_DISABLE_RECOVERY=true" >> /etc/default/grub
grub2-editenv /boot/grub2/grubenv set menu_auto_hide=1 boot_success=1

# persistent logs
#
mkdir -p /var/log/journal

# clear root password
#
passwd -d root
passwd -l root

# we are live
#
echo 'livesys_session="cosmic"' > /etc/sysconfig/livesys

# set default boot target (gui or cli)
#
systemctl set-default graphical.target
#systemctl set-default multi-user.target

# setup flathub repo
#
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# dnf stuff
#
dnf -y install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm 
dnf -y install https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
dnf -y install intel-media-driver
dnf -y install rpmfusion-nonfree-release-tainted
dnf -y --repo=rpmfusion-nonfree-tainted install "*-firmware" --allowerasing
# installing the multimedia group in the xml file errors out, no errors doing it here!
dnf -y group install multimedia
dnf -y --refresh update && dnf clean all && dnf makecache

exit 0
