#!/bin/bash
#
# Download a fixed version of Parasail, compile it, and install to /usr/local.
# Mainly used to build Linux wheels, inside an appropriate manylinux container.

set -euxo pipefail

PARASAIL_VERSION="2.4.3"
PARASAIL_URL="https://github.com/jeffdaily/parasail/releases/download/v${PARASAIL_VERSION}/parasail-${PARASAIL_VERSION}.tar.gz"

# Download
curl -L "${PARASAIL_URL}" -o - | tar xzf -

# Build
cd "parasail-${PARASAIL_VERSION}"
autoreconf -fi
./configure --prefix "/usr/local" && make -j4 && make install
