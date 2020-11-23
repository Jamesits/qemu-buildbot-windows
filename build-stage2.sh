#!/bin/bash
set -Eeuo pipefail
set -x

cd "$( dirname "${BASH_SOURCE[0]}" )"
export DEBIAN_FRONTEND="noninteractive"

DEFAULT_TARGET_LIST="aarch64-softmmu,alpha-softmmu,arm-softmmu,cris-softmmu,hppa-softmmu,i386-softmmu,lm32-softmmu,m68k-softmmu,microblaze-softmmu,microblazeel-softmmu,mips-softmmu,mips64-softmmu,mips64el-softmmu,mipsel-softmmu,moxie-softmmu,nios2-softmmu,or1k-softmmu,ppc-softmmu,ppc64-softmmu,riscv32-softmmu,riscv64-softmmu,rx-softmmu,s390x-softmmu,sh4-softmmu,sh4eb-softmmu,sparc-softmmu,sparc64-softmmu,tricore-softmmu,unicore32-softmmu,x86_64-softmmu,xtensa-softmmu,xtensaeb-softmmu"

# mingw DLLs to embed in the installer
# default DLLs list is extracted from the installer provided at https://qemu.weilnetz.de/w64/
DEFAULT_DLL_LIST="iconv,libatk-1.0-0,libbz2-1,libcairo-2,libcairo-gobject-2,libcurl-4,libeay32,libepoxy-0,libexpat-1,libffi-6,libfontconfig-1,libfreetype-6,libgdk-3-0,libgdk_pixbuf-2.0-0,libgio-2.0-0,libglib-2.0-0,libgmodule-2.0-0,libgmp-10,libgnutls-30,libgobject-2.0-0,libgtk-3-0,libharfbuzz-0,libhogweed-4,libidn2-0,libintl-8,libjpeg-8,liblzo2-2,libncursesw6,libnettle-6,libnghttp2-14,libp11-kit-0,libpango-1.0-0,libpangocairo-1.0-0,libpangoft2-1.0-0,libpangowin32-1.0-0,libpcre-1,libpixman-1-0,libpng16-16,libssh2-1,libtasn1-6,libunistring-2,libusb-1.0,libusbredirparser-1,SDL2,ssleay32,zlib1"
DEFAULT_DLL_LIST_GCC="libssp-0,libstdc++-6"
DEFAULT_DLL_LIST_GCC_W32ONLY="libgcc_s_sjlj-1"
DEFAULT_DLL_LIST_GCC_W64ONLY="libgcc_s_seh-1"
DEFAULT_DLL_LIST_LIB="libwinpthread-1"

# script config variables
SOURCE_BASE_DIR="${SOURCE_BASE_DIR:-${HOME}}"
SOURCE_GIT_URL="${SOURCE_GIT_URL:-https://github.com/qemu/qemu}"
SOURCE_GIT_REF="${SOURCE_GIT_REF:-master}"
SOURCE_GIT_AR7_URL="${SOURCE_GIT_AR7_URL:-https://repo.or.cz/qemu/ar7.git}"
BUILD_ARTIFACTS_DIR="${BUILD_ARTIFACTS_DIR:-/tmp/qemu-build}"
CROSS_PREFIX="${CROSS_PREFIX:-x86_64-w64-mingw32-}"
CROSS_SUFFIX="${CROSS_SUFFIX:-w64}" # w32 or w64 for Windows builds, only affects setup executable name
DATE=$(date +%Y%m%d)
TARGET_LIST="${TARGET_LIST:-${DEFAULT_TARGET_LIST}}"
DLL_LIST="${DLL_LIST:-${DEFAULT_DLL_LIST}}"
DLL_LIST_GCC="${DLL_LIST_GCC:-${DEFAULT_DLL_LIST_GCC}}"
DLL_LIST_GCC_W32ONLY="${DLL_LIST_GCC_W32ONLY:-${DEFAULT_DLL_LIST_GCC_W32ONLY}}"
DLL_LIST_GCC_W64ONLY="${DLL_LIST_GCC_W64ONLY:-${DEFAULT_DLL_LIST_GCC_W64ONLY}}"
DLL_LIST_LIB="${DLL_LIST_LIB:-${DEFAULT_DLL_LIST_LIB}}"
MAKE_FLAGS="${MAKE_FLAGS:--j}" # note that -j might cause OOM (on a 32-core 128G server!)

# ==========================================================================================

# prepare sources
mkdir -p "${SOURCE_BASE_DIR}"
pushd "${SOURCE_BASE_DIR}"

if [ -d "./qemu/.git" ]; then
    echo "INFO: qemu source exists, not cloning again"
    pushd qemu
    git pull
    popd
else
    rm -rf ./qemu
    git clone --reference-if-able "${SOURCE_GIT_AR7_URL}" "${SOURCE_GIT_URL}" qemu # the configure script will init the submodules, no need to do recursive here
fi

if [ -d "./ar7/.git" ]; then
    echo "INFO: qemu-ar7 source exists, not cloning again"
    pushd qemu
    git pull
    popd
else
    rm -rf ./ar7
    git clone --depth 1 --reference-if-able "${SOURCE_GIT_URL}" "${SOURCE_GIT_AR7_URL}" ar7
fi

pushd qemu
git reset --hard
git checkout "${SOURCE_GIT_REF}"

# changes to the qemu.nsi file:
# * added qemu-edid.exe and qemu-ga.exe
# * added some ROMs
# * added icon files and necessary GTK theme files
# * MUI and Unicode support
cp -rv ../ar7/qemu.nsi ../ar7/installer .

# save installer artifacts
sed -ie 's/rm -r $\{INSTDIR\}//g' Makefile

# collect Win32 and Win64 dlls
mkdir -p ./dll/w32 ./dll/w64

# dlls in mingw-{arch}-* packages
for name in ${DLL_LIST//,/ }; do
    cp -v "/usr/i686-w64-mingw32/sys-root/mingw/bin/${name}.dll" "./dll/w32/"
    cp -v "/usr/x86_64-w64-mingw32/sys-root/mingw/bin/${name}.dll" "./dll/w64/"
done

# dlls provided by gcc-mingw-w64-i686 and gcc-mingw-w64-x86-64
for name in ${DLL_LIST_GCC//,/ }; do
    cp -v "/usr/lib/gcc/i686-w64-mingw32/6.3-posix/${name}.dll" "./dll/w32/"
    cp -v "/usr/lib/gcc/x86_64-w64-mingw32/6.3-posix/${name}.dll" "./dll/w64/"
done

# dlls provided by gcc-mingw-w64-i686 only, these work for both x86 and amd64
for name in ${DLL_LIST_GCC_W32ONLY//,/ }; do
    cp -v "/usr/lib/gcc/i686-w64-mingw32/6.3-posix/${name}.dll" "./dll/w32/"
    cp -v "/usr/lib/gcc/i686-w64-mingw32/6.3-posix/${name}.dll" "./dll/w64/"
done

# dlls provided by gcc-mingw-w64-x86_64 only, these are only needed in the arm64 release
for name in ${DLL_LIST_GCC_W64ONLY//,/ }; do
    #　cp -v "/usr/lib/gcc/x86_64-w64-mingw32/6.3-posix/${name}.dll" "./dll/w32/"
    cp -v "/usr/lib/gcc/x86_64-w64-mingw32/6.3-posix/${name}.dll" "./dll/w64/"
done

# dlls in the lib directory
for name in ${DLL_LIST_LIB//,/ }; do
    cp -v "/usr/i686-w64-mingw32/lib/${name}.dll" "./dll/w32/"
    cp -v "/usr/x86_64-w64-mingw32/lib/${name}.dll" "./dll/w64/"
done

popd

# end prepare sources
popd

# build
rm -rf "${BUILD_ARTIFACTS_DIR}"
mkdir -p "${BUILD_ARTIFACTS_DIR}"
pushd "${BUILD_ARTIFACTS_DIR}"

${SOURCE_BASE_DIR}/qemu/configure --cross-prefix="${CROSS_PREFIX}" \
    --disable-werror --enable-trace-backends=log,simple --enable-debug \
    --enable-gnutls --enable-nettle --enable-curl --enable-vnc \
    --enable-bzip2 --enable-guest-agent --enable-docs \
    --enable-gtk --enable-sdl --enable-hax \
    --target-list="${TARGET_LIST}"

make all qemu-edid.exe qemu-ga.exe ${MAKE_FLAGS} V=1 CFLAGS="-Wno-redundant-decls"
# if SIGNCODE is defined, it will be used to sign all the executables and the installer
make installer INSTALLER="qemu-setup-${CROSS_SUFFIX}-${DATE}.exe" # SIGNCODE=signcode

# end build
popd
