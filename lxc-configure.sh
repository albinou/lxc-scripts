#!/bin/bash

set -e
set -u
set -x

# Define default configuration values
LXC_CREATE_USER_SHELL=/bin/bash
LXC_CREATE_TOOLS=""
LXC_APT_CACHER=""
LXC_CREATE_USER=""
LXC_CREATE_SMTP_RELAY=""

# Load personal config if it exists
[ ! -f $(dirname $0)/lxc-configrc ] || . $(dirname $0)/lxc-configrc

# Set umask so that anyone can read created files
umask 022

# Disable root authentication
passwd -l root

# Enable SSH socket
systemctl stop ssh.service
systemctl disable ssh.service
systemctl enable ssh.socket
systemctl start ssh.socket

# Configure APT
apt-get install -y lsb-release
cat << EOF >> /etc/apt/sources.list
deb http://ftp.fr.debian.org/debian/ $(lsb_release --codename --short)-updates main
EOF
cat << EOF > /etc/apt/apt.conf.d/01norecommends
APT::Install-Recommends "false";
APT::Install-Suggests "false";
EOF
if [ -n "$LXC_APT_CACHER" ]; then
	echo "Acquire::http { Proxy \"http://$LXC_APT_CACHER:3142\"; };" > /etc/apt/apt.conf.d/02apt-cacher
fi
apt-get update
apt-get install -y aptitude

# Set $HOME if unset because some git commands may fail
if ! [[ -v HOME ]]; then
	export HOME="/root"
fi

aptitude install -y git
git config --global user.email "root@$(hostname)"
git config --global user.name "Root"
aptitude install -y etckeeper

# Install tools
aptitude install -y sudo $LXC_CREATE_TOOLS

# Add user with sudo rights
if [ -n "$LXC_CREATE_USER" ]; then
	groupadd -g 1000 "$LXC_CREATE_USER"
	useradd -u 1000 -g 1000 -G sudo -m -s "$LXC_CREATE_USER_SHELL" "$LXC_CREATE_USER"
	if [ -n "LXC_CREATE_USER_SSH_PUB_KEY" ]; then
		mkdir -m 711 "/home/${LXC_CREATE_USER}/.ssh"
		chown "${LXC_CREATE_USER}:${LXC_CREATE_USER}" "/home/${LXC_CREATE_USER}/.ssh"
		echo "$LXC_CREATE_USER_SSH_PUB_KEY" > "/home/${LXC_CREATE_USER}/.ssh/authorized_keys"
		chmod 644 "/home/${LXC_CREATE_USER}/.ssh/authorized_keys"
		chown "${LXC_CREATE_USER}:${LXC_CREATE_USER}" "/home/${LXC_CREATE_USER}/.ssh/authorized_keys"
	fi
fi

# Install base services
if [ -n "$LXC_CREATE_SMTP_RELAY" ]; then
	debconf-set-selections <<< "postfix postfix/main_mailer_type string Satellite system"
	debconf-set-selections <<< "postfix postfix/relayhost string $LXC_CREATE_SMTP_RELAY"
	DEBIAN_FRONTEND=noninteractive aptitude install -y postfix
	if [ -n "$LXC_CREATE_USER" ]; then
		echo "root: $LXC_CREATE_USER" >> /etc/aliases
		echo "$LXC_CREATE_USER: $LXC_CREATE_USER_EMAIL" >> /etc/aliases
		newaliases
	fi
	aptitude install -y bsd-mailx
fi

aptitude install -y unattended-upgrades apt-listchanges iso-codes
sed -ri 's_//(Unattended-Upgrade::Mail .*)$_\1_' /etc/apt/apt.conf.d/50unattended-upgrades
if [ ! -f "/etc/apt/apt.conf.d/20auto-upgrades" ]; then
	cat << EOF > /etc/apt/apt.conf.d/20auto-upgrades
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF
fi
