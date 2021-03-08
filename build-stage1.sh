#!/bin/bash
set -Eeuo pipefail
set -x

if [ "$EUID" -ne 0 ]
  then echo "This script must be run as root"
  exit
fi

cd "$( dirname "${BASH_SOURCE[0]}" )"
export DEBIAN_FRONTEND="noninteractive"

apt-get update -y
apt-get install -y gnupg2 curl ca-certificates apt-transport-https

# add Debian buster repo for nsis v3
echo "deb http://deb.debian.org/debian buster main" > /etc/apt/sources.list.d/buster.list
cat > /etc/apt/preferences.d/buster <<EOF
Package: nsis nsis-common
Pin: release n=buster
Pin-Priority: 1000

Package: *
Pin: release n=buster
Pin-Priority: 50
EOF

# add apt repository for mingw-* packages
# mingw-* packages are converted using https://github.com/stweil/cyg2deb/
curl -s https://qemu.weilnetz.de/debian/gpg.key | apt-key add -
curl -s https://qemu.weilnetz.de/debian/weilnetz.gpg | apt-key add -
echo "deb https://qemu.weilnetz.de/debian/ testing contrib" > /etc/apt/sources.list.d/cygwin.list

apt-get update -y
apt-get install -y git build-essential bison flex nsis texinfo gettext wget \
    python3 python3-pip \
    mingw64-i686-adwaita-icon-theme mingw64-x86-64-adwaita-icon-theme mingw64-i686-hicolor-icon-theme mingw64-x86-64-hicolor-icon-theme \
    g++-mingw-w64 mingw-w64 mingw-w64-tools \
    mingw-w64-i686-dev mingw64-i686-glib2.0 mingw64-i686-pixman mingw64-i686-curl mingw64-i686-gtk3 mingw64-i686-libssh2 mingw64-i686-libtasn1 mingw64-i686-nettle mingw64-i686-ncurses mingw64-i686-gnutls mingw64-i686-sdl2 mingw64-i686-libgcrypt mingw64-i686-libusb1.0 mingw64-i686-usbredir \
    mingw-w64-x86-64-dev mingw64-x86-64-glib2.0 mingw64-x86-64-pixman mingw64-x86-64-curl mingw64-x86-64-gtk3 mingw64-x86-64-libssh2 mingw64-x86-64-libtasn1 mingw64-x86-64-nettle mingw64-x86-64-ncurses mingw64-x86-64-gnutls mingw64-x86-64-sdl2 mingw64-x86-64-libgcrypt mingw64-x86-64-libusb1.0 mingw64-x86-64-usbredir

# python3-sphinx packaged by Debian 9 is too old
pip3 install git+https://github.com/sphinx-doc/sphinx
