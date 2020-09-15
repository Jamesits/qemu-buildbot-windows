#!/bin/bash
set -Eeuo pipefail

cd "$( dirname "${BASH_SOURCE[0]}" )"
export DEBIAN_FRONTEND="noninteractive"

SOURCE_BASE_DIR="${SOURCE_BASE_DIR:-${HOME}}"
SOURCE_GIT_URL="${SOURCE_GIT_URL:-https://github.com/qemu/qemu}"
SOURCE_GIT_REF="${SOURCE_GIT_REF:-master}"
BUILD_ARTIFACTS_DIR="${BUILD_ARTIFACTS_DIR:-/tmp/qemu-build}"
CROSS_PREFIX="${CROSS_PREFIX:-}"
CROSS_SUFFIX="${CROSS_SUFFIX:-}"
DATE=$(date +%Y%m%d)

mkdir -p "${SOURCE_BASE_DIR}"
pushd "${SOURCE_BASE_DIR}"

git clone "${SOURCE_GIT_URL}" qemu
cd qemu
git checkout "${SOURCE_GIT_REF}"

mkdir -p "${BUILD_ARTIFACTS_DIR}"
pushd "${BUILD_ARTIFACTS_DIR}"

${SOURCE_BASE_DIR}/configure --cross-prefix="${CROSS_PREFIX}" \
    --disable-werror --enable-trace-backends=simple --enable-debug \
    --enable-gnutls --enable-nettle --enable-curl --enable-vnc \
    --enable-bzip2 --enable-guest-agent --enable-docs \
    --enable-gtk --enable-sdl --enable-hax

make all -j V=1 CFLAGS="-Wno-redundant-decls"
make installer INSTALLER="qemu-${CROSS_SUFFIX}-setup-${DATE}.exe" # SIGNCODE=signcode
