#!/bin/bash

set -e
set -u
set -x

# Define default configuration values
LXC_ARCH="x86_64"
LXC_SUITE="stretch"
LXC_DEBIAN_MIRROR="http://ftp.fr.debian.org/debian"
LXC_DEBIAN_SECURITY_MIRROR="http://security.debian.org"

# Load personal config if it exists
[ ! -f $(dirname $0)/lxc-configrc ] || . $(dirname $0)/lxc-configrc

NAME="$1"
IP=""
GW="${LXC_NETWORK_GW:=\"\"}"
if [ $# -gt 1 ]; then
	IP="$2"
fi
if [ $# -gt 2 ]; then
	GW="$3"
fi

# Set umask so that anyone can read created files
umask 022

cat << EOF > /tmp/lxc.conf
lxc.network.type = veth
lxc.network.flags = up
lxc.network.link = $LXC_NETWORK_BRIDGE
EOF
if [ -n "$IP" ]; then
	echo "lxc.network.ipv4 = $IP" >> /tmp/lxc.conf
fi
if [ -n "$GW" ]; then
	echo "lxc.network.ipv4.gateway = $GW" >> /tmp/lxc.conf
fi

# Create and configure LXC
lxc-create -n $NAME --dir /srv/lxc/$NAME -t debian -f /tmp/lxc.conf -- \
	--arch="$LXC_ARCH"                                             \
	--release="$LXC_SUITE"                                         \
	--mirror="$LXC_DEBIAN_MIRROR"                                  \
	--security-mirror="$LXC_DEBIAN_SECURITY_MIRROR"
rmdir /var/lib/lxc/$NAME/rootfs
chmod go+rx /var/lib/lxc/$NAME
chmod go+r /var/lib/lxc/$NAME/*

# Configure network and deactivate DHCP if static IP
if [ -n "$IP" ]; then
	sed -ri '/^$/d' /srv/lxc/$NAME/etc/network/interfaces
	sed -ri '/^auto eth0$/d' /srv/lxc/$NAME/etc/network/interfaces
	sed -ri '/^iface eth0 inet dhcp$/d' /srv/lxc/$NAME/etc/network/interfaces
fi
figlet -w 80 "/*  $NAME  */" > /srv/lxc/$NAME/etc/motd

# Configure UMASK to 077 for users
sed -ri 's/^(UMASK[[:space:]]+)[[:digit:]]+$/\1077/' /srv/lxc/$NAME/etc/login.defs
sed -ri 's/^(# end of pam-auth-update config)$/session\toptional\tpam_umask.so \n\1/' /srv/lxc/$NAME/etc/pam.d/common-session

# Run LXC and install packages
lxc-start -d -n $NAME
sleep 5
if [ -z "$IP" ]; then
	sleep 5
fi
cp $(dirname $0)/lxc-configure.sh /srv/lxc/$NAME/tmp/
cp $(dirname $0)/lxc-configrc /srv/lxc/$NAME/tmp/ || true
lxc-attach -n $NAME -- /tmp/lxc-configure.sh
rm -f /srv/lxc/$NAME/tmp/lxc-configrc
rm -f /srv/lxc/$NAME/tmp/lxc-configure.sh
