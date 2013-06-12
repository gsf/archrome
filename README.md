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

Usage
-----
Enter the chroot with the newly-installed `archrome` script. This will handle 
the mounting and umounting of various directories within the chroot. Enter a
chroot other than the default ("arch") by passing it as an argument:
```
sudo archrome myarch
```

