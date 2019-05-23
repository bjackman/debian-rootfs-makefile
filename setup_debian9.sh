#!/bin/bash

# This script will get run from inside a chroot environment. Here you can run
# your setup for Debian that will get written to the rootfs file that QEMU uses.
set -ex

APT_PROXY_CONF_FILE=/etc/apt/apt.conf.d/50-http-proxy
echo HTTP PROXY IS $http_proxy
if [ ! -z "$http_proxy" ]; then
    echo Acquire::http::Proxy "\"$http_proxy\";" > $APT_PROXY_CONF_FILE
fi

set -u

do_install() {
    apt install -y --allow-unauthenticated $*
}

# We'll also need to add a user
adduser brendan --disabled-password </dev/null
echo -e "password\npassword\n" | passwd brendan

# Install sudo and enable it with no password
do_install sudo
usermod -aG sudo brendan
cat <<EOF >/etc/sudoers
#
# This file MUST be edited with the 'visudo' command as root.
#
# Please consider adding local content in /etc/sudoers.d/ instead of
# directly modifying this file.
#
# See the man page for details on how to write a sudoers file.
#
Defaults	env_reset
Defaults	mail_badpass
Defaults	secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Host alias specification

# User alias specification

# Cmnd alias specification

# User privilege specification
root	ALL=(ALL:ALL) ALL

# Allow members of group sudo to execute any command with no password
%sudo	ALL=(ALL:ALL) NOPASSWD:ALL

# See sudoers(5) for more information on "#include" directives:

#includedir /etc/sudoers.d
EOF

# Set up fstab so that root gets remounted rw
# NB we didn't set up a partition table hence /dev/sda not /dev/sda1
cat <<EOF >/etc/fstab
/dev/sda         /            ext4          noatime          0      1
EOF

# Install stuff that might be useful
do_install pciutils net-tools openssh-server less vim trace-cmd build-essential

# TODO libssl1.0.0 only seems available in older Debian dists???
echo deb http://security.debian.org/debian-security jessie/updates main >> /etc/apt/sources.list
apt update
do_install libssl1.0.0

# In QEMU we will have an ethernet interface connected to user networking. QEMU will
# set up a virtual DHCP server. Configure that device to use the DHCP:
# This is taken from https://www.debian.org/doc/manuals/debian-reference/ch05
# We need to do it the systemd way instead of the old /etc/network/interfaces
# way, seems like installing openssh-server awoke the systemd balrog here.
do_install network-manager
cat << EOF > /etc/systemd/network/dhcp.network
[Match]
Name=en*

[Network]
DHCP=yes
EOF

# Default hostname is the same as the host we build on, which is a bit confusing
echo 'debian9-qemu-guest' > /etc/hostname
echo -e "127.0.0.1\t$(cat /etc/hostname)" >> /etc/hosts

# Undo the apt proxy configuration, if we did it. It only works in chroot, not
# in a VM.
rm $APT_PROXY_CONF_FILE || true
