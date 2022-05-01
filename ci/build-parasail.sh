#!/bin/bash
#
# Download a fixed version of Parasail, compile it, and install to /usr/local.
# Mainly used to build Linux wheels, inside an appropriate manylinux container.

set -euxo pipefail

PARASAIL_VERSION="2.5"
PARASAIL_URL="https://github.com/jeffdaily/parasail/archive/refs/tags/v${PARASAIL_VERSION}.tar.gz"

TARGET="${1:-x86_64}"
PREFIX="${2:-/usr/local}"

# Download
curl -L "${PARASAIL_URL}" -o - | tar xzf -

# Build
cd "parasail-${PARASAIL_VERSION}"
autoreconf -fi

if [[ "$TARGET" == "arm64" && $(uname) == "Darwin" ]]; then
    softwareupdate --agree-to-license --install-rosetta
    ./configure \
        CFLAGS="-target aarch64-apple-darwin" \
        CXXFLAGS="-target aarch64-apple-darwin" \
        --prefix="$PREFIX" \
        --host aarch64-apple-darwin \
        --build aarch64-apple-darwin || true
    cat config.log
else
    ./configure
fi
make -j4 && make install

if [[ $(uname) == "Darwin" ]]; then
    lipo -info "$PREFIX"/lib/libparasail.*
fi
