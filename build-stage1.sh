#!/bin/bash
set -Eeuo pipefail

if [ "$EUID" -ne 0 ]
  then echo "This script must be run as root"
  exit
fi

cd "$( dirname "${BASH_SOURCE[0]}" )"
export DEBIAN_FRONTEND="noninteractive"

apt-get update -y
apt-get install -y gnupg2 curl ca-certificates apt-transport-https
curl -s https://qemu.weilnetz.de/debian/gpg.key | apt-key add -
echo "deb https://qemu.weilnetz.de/debian/ testing contrib" > /etc/apt/sources.list.d/cygwin.list
apt-get update -y
apt-get install -y git python3 build-essential bison flex python3-pip g++-mingw-w64 mingw-w64 mingw-w64-tools mingw-w64-i686-dev mingw-w64-x86-64-dev nsis mingw64-i686-glib2.0 mingw64-i686-pixman mingw64-i686-curl mingw64-i686-gtk3 mingw64-i686-libssh2 mingw64-i686-libtasn1 mingw64-i686-nettle mingw64-i686-ncurses mingw64-i686-gnutls mingw64-i686-sdl2 mingw64-i686-libgcrypt mingw64-i686-libusb1.0 mingw64-i686-usbredir texinfo gettext
# python3-sphinx is too old
pip3 install git+https://github.com/sphinx-doc/sphinx
