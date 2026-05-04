#!/bin/bash
#
set -euxo pipefail

# functions
#
test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile

# selinux booleans, somehow breaks the build when making gnome images but works fine with cosmic?!
# either way it should not be needed unless you use kde, which nobody sane should use lol
#setsebool -P selinuxuser_execmod 1

# clear machine configuration
#
rm -f /etc/machine-id
echo 'uninitialized' > /etc/machine-id
rm -f /var/lib/systemd/random-seed

# setup grub
#
echo "GRUB_DEFAULT=saved" >> /etc/default/grub
echo "GRUB_DISABLE_SUBMENU=true" >> /etc/default/grub
echo "GRUB_DISABLE_RECOVERY=true" >> /etc/default/grub
grub2-editenv /boot/grub2/grubenv set menu_auto_hide=1 boot_indeterminate=1

# delete & lock the root user password
#
passwd -d root
passwd -l root

# setup default services
#
echo 'livesys_session="gnome"' > /etc/sysconfig/livesys

# stop this annoying "service" from delaying boots
#
systemctl disable --now NetworkManager-wait-online
systemctl mask NetworkManager-wait-online

# persistent logs
#
mkdir -p /var/log/journal
systemd-tmpfiles --create --prefix /var/log/journal

# Setup default target
#
systemctl set-default graphical.target
#systemctl set-default multi-user.target

# apply custom gnome stuff in /etc/dconf/db/local.d/99-pumice
#
dconf update

# setup flathub repo
#
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# rpmfusion stuff
#
dnf -y --nogpgcheck install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
dnf -y --nogpgcheck install https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
dnf -y install rpmfusion-free-release-tainted rpmfusion-nonfree-release-tainted
dnf -y config-manager setopt fedora-cisco-openh264.enabled=1
dnf -y swap ffmpeg-free ffmpeg --allowerasing
dnf -y install libdvdcss
dnf -y install @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin

# amd media driver
dnf -y install mesa-va-drivers-freeworld

# intel media driver
dnf -y install intel-media-driver

# older intel needs this instead
#dnf -y install libva-intel-driver

# nvidia
#dnf -y install install libva-nvidia-driver

dnf install rpmfusion-\*-appstream-data

# setup brave origin
#sudo dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
#sudo dnf install brave-origin

dnf -y --refresh update && dnf clean all && dnf makecache && pkcon refresh force

exit 0
