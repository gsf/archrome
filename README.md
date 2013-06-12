archrome
========

Arch Linux chroot for Chrome OS


Install
-------
Switch your device to developer mode and run the following:
```
curl https://raw.github.com/gsf/archrome/master/install.sh | sudo sh
```

You should feel free to inspect [install.sh](/install.sh) before you run it
locally, of course. Note that the default mirror and directory can be
overridden by environment variables.

When the script finishes, you will have a chroot with the minimal base needed
to build a system.


Usage
-----
Enter the chroot with the newly-installed `archrome` script, which wraps the
`chroot` command to handle the mounting of various directories. Enter a chroot
other than the default ("arch") by passing it as an argument:
```
sudo archrome myarch
```

