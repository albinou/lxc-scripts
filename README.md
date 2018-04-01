# LXC scripts

Creating LXCs under Debian Linux GNU/Linux is really easy with the standard
_lxc-create_ tool.
However configuration can be painful, especially if you want to:

* create a default user account
* configure APT so that recommended packages and suggested packages are not
installed
* install & configure postfix
* install & activate unattended-upgrades (for automatic updates)
* ...

I use these tools to easily create self-configured LXCs but they are probably
meant to be adapted for your own purpose.

## lxc-create.sh

_lxc-create.sh_ is a replacement for the Debian _lxc-create_ tool.
It:

1. reads its configuration from _lxc-configrc_ (read next section
for information on possible options)
2. creates the LXC by calling the legacy _lxc-create_
3. starts the LXC and runs _lxc-configure.sh_ in the LXC to perform the
configurations that requires the environment

_lxc-create.sh_ usage is the following:
```
./lxc-create.sh NAME [IP_ADDRESS] [GATEWAY]
```

## lxc-configrc

### LXC_ARCH

* Required
* Default value: `x86_64`

### LXC_SUITE

* Required
* Default value: `stretch`

### LXC_DEBIAN_MIRROR

* Required
* Default value: `http://ftp.fr.debian.org/debian`

### LXC_DEBIAN_SECURITY_MIRROR

* Required
* Default value: `http://security.debian.org`

### LXC_NETWORK_BRIDGE

* Required
* No default value

### LXC_NETWORK_GW

* Optional
* Overridden by the _GATEWAY_ given in the script argument

### LXC_APT_CACHER

* Optional

### LXC_CREATE_TOOLS

* Optional
* Space separated list of Debian packages to install

### LXC_CREATE_USER

* Optional

### LXC_CREATE_USER_EMAIL

* Optional

### LXC_CREATE_USER_EMAIL

* Optional

### LXC_CREATE_USER_SHELL

* Optional

### LXC_CREATE_USER_SSH_PUB_KEY

* Optional

### LXC_CREATE_SMTP_RELAY

* Optional

### LXC_SSH_SECURED

* Optional
* Default value: `false`
