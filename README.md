# archrome

Arch Linux chroot for Chrome OS


## Install
Switch your device to developer mode and run the following:
```
curl https://raw.github.com/gsf/archrome/master/install.sh | sudo sh
```

You should feel free to inspect [install.sh](/install.sh) before you run it
locally, of course. Note that some defaults can be overridden by environment
variables.

When the script finishes, you will have a chroot with a minimal base for
building a system.


## Usage
Enter the chroot with the newly-installed `archrome` script, which wraps the
`chroot` command to handle the mounting of various directories.  If a command
is passed to `archrome`, it will be executed in the chroot instead of the
usual `/bin/bash`. For example:
```
sudo archrome date
```

Archrome aims to be the minimal environment necessary for further building of
the system. Some base packages (shadow, tzdata, etc.) and basic necessities
(git, less, vim) will need to be installed once one is in the chroot to do
much of anything. Also, users may need to be created, locales and timezones
set, etc.

### SSH
To set up an SSH server, run the following in the chroot:
```
# pacman -S openssh shadow
# ssh-keygen -A
```

Start it up with `/bin/sshd` or from outside the chroot with `sudo archrome /bin/sshd`.

### Package signing
Arch package signing has been disabled because the generating of the master key takes
a significant amount of time during installation. Also, that level of security seems
unwarranted for a chroot on a chromebook.

To enable package signing, complete the following steps:

1. Install `archlinux-keyring`
1. Run `pacman-key --init`
1. Run `pacman-key --populate archlinux`
1. Delete or comment out the `SigLevel = Never` line in /etc/pacman.conf


## Cleanup
Remember to unmount things before running `rm -rf` on a chroot! A
`grep chroot /etc/mtab` or two will help, as will this:
```
sudo umount /usr/local/chroots/arch/{proc,sys,dev/pts,dev,var/host/media,var/host/shill,var/host/Downloads}
```
