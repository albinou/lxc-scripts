#!/bin/bash

set -e
set -u
set -x

NAME=$1
IP=$2
NETWORK_CONF='lxc.network.ipv4.gateway = 192.168.20.2'

export SUITE=jessie
export MIRROR=http://ftp.fr.debian.org/debian

# Set umask so that anyone can read created files
umask 022

cat << EOF > /tmp/lxc.conf
lxc.network.type = veth
lxc.network.flags = up
lxc.network.link = br0
lxc.network.ipv4 = $IP/24
EOF

# Create and configure LXC
lxc-create -n $NAME --dir /srv/lxc/$NAME -t debian -f /tmp/lxc.conf
rmdir /var/lib/lxc/$NAME/rootfs
chmod go+rx /var/lib/lxc/$NAME
chmod go+r /var/lib/lxc/$NAME/*
sed -ri "s/^(lxc\.network\.ipv4 = .*)\$/\1\n$NETWORK_CONF/" /var/lib/lxc/$NAME/config

# Configure network
sed -ri '/^$/d' /srv/lxc/$NAME/etc/network/interfaces
sed -ri '/^auto eth0$/d' /srv/lxc/$NAME/etc/network/interfaces
sed -ri '/^iface eth0 inet dhcp$/d' /srv/lxc/$NAME/etc/network/interfaces
figlet -w 80 "/*  $NAME  */" > /srv/lxc/$NAME/etc/motd

# Configure UMASK to 077 for users
sed -ri 's/^(UMASK[[:space:]]+)[[:digit:]]+$/\1077/' /srv/lxc/$NAME/etc/login.defs
sed -ri 's/^(# end of pam-auth-update config)$/session\toptional\tpam_umask.so \n\1/' /srv/lxc/$NAME/etc/pam.d/common-session

# Run LXC and install packages
lxc-start -d -n $NAME
sleep 5
cp $(dirname $0)/lxc-configure.sh /srv/lxc/$NAME/tmp/
cp $(dirname $0)/lxc-configrc /srv/lxc/$NAME/tmp/ || true
lxc-attach -n $NAME -- /tmp/lxc-configure.sh
rm -f /srv/lxc/$NAME/tmp/lxc-configrc
rm -f /srv/lxc/$NAME/tmp/lxc-configure.sh
