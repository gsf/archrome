#!/bin/sh

set -e

# Default mirror and chroot directory
MIRROR="http://us.mirror.archlinuxarm.org/armv7h/core/"
DIR="arch"

# Environment variable overrides
[ -n "$ARCHMIRROR" ] && MIRROR="$ARCHMIRROR"
[ -n "$ARCHROOT" ] && DIR="$ARCHROOT"

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
  tar
  xz
  zlib
"

# Grab index of packages, reversing so we'll get latest version with first match
INDEX=`curl -s $MIRROR | tac`

PACMAN_CACHE=var/cache/pacman/pkg/
mkdir -p $PACMAN_CACHE

unpack() {
  echo -n "$1 "
  # Grab the first occurrence for each package
  local PACKAGE_NAME=`echo "$INDEX" | sed -n "/href=\"$1-[0-9]/{p;q;}" | sed -n "s/.*href=\"\([^\"]*\).*/\1/p"`
  [ -z "$PACKAGE_NAME" ] && echo "Error: package not found: $PACKAGE" && return 1
  local URL="$MIRROR$PACKAGE_NAME"
  local OUTFILE="$PACMAN_CACHE$PACKAGE_NAME"
  wget -q -O $OUTFILE "$URL"
  case "$PACKAGE_NAME" in
    *.xz) cat "$OUTFILE" | xz -dc | tar --warning=no-unknown-keyword -x;;
    *.gz) cat "$OUTFILE" | tar --warning=no-unknown-keyword -xz;;
    *) echo "Error: unknown package format: $PACKAGE_NAME"
       return 1;;
  esac
}

echo "Downloading and bootstrapping packages for bash and pacman..."
for PACKAGE in $PACKAGES; do
  unpack $PACKAGE
done

# Create links for /lib and /bin if they don't exist
[ ! -e lib ] && ln -s usr/lib lib
[ ! -e bin ] && ln -s usr/bin bin

# Hash for empty password  Created by doing: openssl passwd -1 -salt ihlrowCo and entering an empty password (just press enter)
echo 'root:$1$ihlrowCo$sF0HjA9E8up9DYs258uDQ0:10063:0:99999:7:::' > "etc/shadow"
echo "root:x:0:0:root:/root:/bin/bash" > "etc/passwd" 
touch "etc/group"
[ ! -e etc/mtab ] && echo "rootfs / rootfs rw 0 0" > etc/mtab
[ -f /etc/resolv.conf ] && cp /etc/resolv.conf etc/

# Set up for first chrooting
mkdir -p dev proc sys mnt
mount -t proc proc proc
mount -t sysfs sys sys
mount -o bind /dev dev
mount -t devpts pts dev/pts

echo "\nUpdating pacman db with bootstrapped packages..."
chroot . pacman -Sy $PACKAGES -dd --dbonly --noconfirm


# Write chroot wrapper script
echo "Writing /usr/local/bin/archrome..."
cat <<'EOF' > /usr/local/bin/archrome
#!/bin/sh

DIR="arch"
[ -n "$1" ] && DIR="$1"
cd "/usr/local/chroots/$DIR"

# Create mount points if they don't exist
mountpoint -q proc || mount -t proc proc proc
mountpoint -q sys || mount -t sysfs sys sys
mountpoint -q dev || mount -o bind /dev dev
mountpoint -q dev/pts || mount -t devpts pts dev/pts

chroot .
EOF
chmod 755 /usr/local/bin/archrome
