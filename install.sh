#!/bin/sh
#
# archrome - Arch Linux chroot for Chrome OS
# https://github.com/gsf/archrome
# Version 0.0.2

set -e

# Default mirror and chroot directory
MIRROR="http://us.mirror.archlinuxarm.org/armv7h/core/"
DIR="arch"
LOCALE="en_US.UTF-8"

# Environment variable overrides
[ -n "$ARCHMIRROR" ] && MIRROR="$ARCHMIRROR"
[ -n "$ARCHROOT" ] && DIR="$ARCHROOT"
[ -n "$ARCHLOCALE" ] && LOCALE="$ARCHLOCALE"

DIRPATH="/usr/local/chroots/$DIR"
mkdir -p "$DIRPATH"
cd "$DIRPATH"

# Packages for a base system
PACKAGES="
  acl
  attr
  bash
  bzip2
  coreutils
  curl
  expat
  filesystem
  gcc-libs
  glibc
  gpgme
  grep
  gzip
  iana-etc
  libarchive
  libassuan
  libcap
  libgpg-error
  libssh2
  lzo2
  ncurses
  openssl
  pacman
  pacman-mirrorlist
  pcre
  readline
  sed
  tar
  util-linux
  xz
  zlib
"

# Grab index of packages, reversing so we'll get latest version with first match
INDEX=`curl -sS $MIRROR | tac`

PACMAN_CACHE=var/cache/pacman/pkg/
mkdir -p $PACMAN_CACHE

echo "Unpacking packages into $DIRPATH..."
for PACKAGE in $PACKAGES; do
  echo -n "$PACKAGE "
  # Grab the first occurrence for each package
  local PACKAGE_NAME=`echo "$INDEX" | sed -n "/href=\"$PACKAGE-[0-9]/{p;q;}" | sed -n "s/.*href=\"\([^\"]*\).*/\1/p"`
  [ -z "$PACKAGE_NAME" ] && echo "Error: package not found: $PACKAGE" && return 1
  local URL="$MIRROR$PACKAGE_NAME"
  local CACHED="$PACMAN_CACHE$PACKAGE_NAME"
  # Move the cache into place before running install to reuse downloaded packages
  [ ! -f "$CACHED" ] && curl -s "$URL" > "$CACHED"
  case "$PACKAGE_NAME" in
    *.xz) cat "$CACHED" | xz -dc | tar --warning=no-unknown-keyword -x;;
    *.gz) cat "$CACHED" | tar --warning=no-unknown-keyword -xz;;
    *) echo "Error: unknown package format: $PACKAGE_NAME"
       return 1;;
  esac
done

# Switch from /proc/mounts to boring mtab
[ -e etc/mtab ] && rm etc/mtab
echo "rootfs / rootfs rw 0 0" > etc/mtab

# Use host resolv.conf
ln -sf /var/host/shill/resolv.conf etc/resolv.conf

# Create directories to share with host
mkdir -p var/host/Downloads
mkdir -p var/host/media
mkdir -p var/host/shill

# Write chroot wrapper script
echo "Writing /usr/local/bin/archrome..."
cat <<'EOF' > /usr/local/bin/archrome
#!/bin/sh

DIR="arch"
[ -n "$ARCHROOT" ] && DIR="$ARCHROOT"
cd "/usr/local/chroots/$DIR"

# Create mount points if they don't exist already
mountpoint -q proc || mount -t proc proc proc
mountpoint -q sys || mount -t sysfs sys sys
mountpoint -q dev || mount -B /dev dev
mountpoint -q dev/pts || mount -t devpts pts dev/pts
mountpoint -q var/host/Downloads || mount -B /home/chronos/user/Downloads var/host/Downloads
mount --make-shared /media
mountpoint -q var/host/media || mount -R /media var/host/media
mountpoint -q var/host/shill || mount -B /var/run/shill var/host/shill

chroot . "$@"
EOF
chmod 755 /usr/local/bin/archrome

# A bit of preparation
echo "\nUpdating pacman db with unpacked packages..."
/usr/local/bin/archrome pacman -Sy $PACKAGES -dd --dbonly --noconfirm --needed

echo "Setting default ($LOCALE) locale..."
sed -i "s/#\($LOCALE.*\)/\1/" etc/locale.gen
/usr/local/bin/archrome locale-gen
