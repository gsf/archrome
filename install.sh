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
  grep
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
  tar
  util-linux
  xz
  zlib
"

# Grab index of packages, reversing so we'll get latest version with first match
INDEX=`curl -s $MIRROR | tac`

PACMAN_CACHE=var/cache/pacman/pkg/
mkdir -p $PACMAN_CACHE

echo "Downloading and bootstrapping packages for bash and pacman..."
for PACKAGE in $PACKAGES; do
  echo -n "$PACKAGE "
  # Grab the first occurrence for each package
  local PACKAGE_NAME=`echo "$INDEX" | sed -n "/href=\"$PACKAGE-[0-9]/{p;q;}" | sed -n "s/.*href=\"\([^\"]*\).*/\1/p"`
  [ -z "$PACKAGE_NAME" ] && echo "Error: package not found: $PACKAGE" && return 1
  local URL="$MIRROR$PACKAGE_NAME"
  local CACHED="$PACMAN_CACHE$PACKAGE_NAME"
  # Move the cache into place before running install to reuse downloaded packages
  [ ! -f "$CACHED" ] && curl "$URL" > "$CACHED"
  case "$PACKAGE_NAME" in
    *.xz) cat "$CACHED" | xz -dc | tar --warning=no-unknown-keyword -x;;
    *.gz) cat "$CACHED" | tar --warning=no-unknown-keyword -xz;;
    *) echo "Error: unknown package format: $PACKAGE_NAME"
       return 1;;
  esac
done

# Use host resolv.conf
[ -f /etc/resolv.conf ] && cp /etc/resolv.conf etc/

# Create Downloads directory for sharing with host
mkdir -p root/Downloads

# Mounts for pacman preparations
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

# Create mount points if they don't exist already
mountpoint -q proc || mount -t proc proc proc
mountpoint -q sys || mount -t sysfs sys sys
mountpoint -q dev || mount -o bind /dev dev
mountpoint -q dev/pts || mount -t devpts pts dev/pts
mountpoint -q root/Downloads || mount -o bind /home/chronos/user/Downloads root/Downloads

chroot .
EOF
chmod 755 /usr/local/bin/archrome
