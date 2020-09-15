#!/bin/bash
set -Eeuo pipefail
set -x

cd "$( dirname "${BASH_SOURCE[0]}" )"
export DEBIAN_FRONTEND="noninteractive"

DEFAULT_TARGET_LIST="aarch64-softmmu,alpha-softmmu,arm-softmmu,cris-softmmu,hppa-softmmu,i386-softmmu,lm32-softmmu,m68k-softmmu,microblaze-softmmu,microblazeel-softmmu,mips-softmmu,mips64-softmmu,mips64el-softmmu,mipsel-softmmu,moxie-softmmu,nios2-softmmu,or1k-softmmu,ppc-softmmu,ppc64-softmmu,riscv32-softmmu,riscv64-softmmu,rx-softmmu,s390x-softmmu,sh4-softmmu,sh4eb-softmmu,sparc-softmmu,sparc64-softmmu,tricore-softmmu,unicore32-softmmu,x86_64-softmmu,xtensa-softmmu,xtensaeb-softmmu"

SOURCE_BASE_DIR="${SOURCE_BASE_DIR:-${HOME}}"
SOURCE_GIT_URL="${SOURCE_GIT_URL:-https://github.com/qemu/qemu}"
SOURCE_GIT_REF="${SOURCE_GIT_REF:-master}"
BUILD_ARTIFACTS_DIR="${BUILD_ARTIFACTS_DIR:-/tmp/qemu-build}"
CROSS_PREFIX="${CROSS_PREFIX:-x86_64-w64-mingw32-}"
CROSS_SUFFIX="${CROSS_SUFFIX:-w64}" # w32 or w64 for Windows builds
DATE=$(date +%Y%m%d)
TARGET_LIST="${TARGET_LIST:-${DEFAULT_TARGET_LIST}}"

# prepare sources
mkdir -p "${SOURCE_BASE_DIR}"
pushd "${SOURCE_BASE_DIR}"
rm -rf ./qemu

git clone "${SOURCE_GIT_URL}" qemu
pushd qemu
git checkout "${SOURCE_GIT_REF}"

# put Win32 and Win64 dlls
DLL_DOWNLOAD_URL=""

if [ "$CROSS_SUFFIX" = "w32" ]; then
    DLL_DOWNLOAD_DIR="./dll/w32"
    DLL_DOWNLOAD_URL="https://qemu.weilnetz.de/w32/old/dll/"
    DLL_DOWNLOAD_CUT_DIRS="3"
elif [ "$CROSS_SUFFIX" = "w64" ]; then
    DLL_DOWNLOAD_DIR="./dll/w64"
    DLL_DOWNLOAD_URL="https://qemu.weilnetz.de/w64/old/dll/"
    DLL_DOWNLOAD_CUT_DIRS="3"
fi

if [ ! -z "${DLL_DOWNLOAD_URL}" ]; then
    mkdir -p "${DLL_DOWNLOAD_DIR}"
    pushd "${DLL_DOWNLOAD_DIR}"
    wget --recursive --no-parent --no-host-directories --continue --cut-dirs ${DLL_DOWNLOAD_CUT_DIRS} --accept "*.dll" --reject "index.html*" --level 1 "${DLL_DOWNLOAD_URL}"
    popd
fi

popd

# end get sources
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

make all -j V=1 CFLAGS="-Wno-redundant-decls"
make installer INSTALLER="qemu-setup-${CROSS_SUFFIX}-${DATE}.exe" # SIGNCODE=signcode

# end build
popd
