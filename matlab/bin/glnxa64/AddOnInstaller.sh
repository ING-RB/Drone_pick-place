#!/bin/sh

filename=$0

BINDIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

# Preload glibc_shim in case of RHLE7 variants
test -e /usr/bin/ldd &&  /usr/bin/ldd --version |  grep -q "(GNU libc) 2\.17"  \
          && export LD_PRELOAD="$BINDIR/glibc-2.17_shim.so"

$BINDIR/AddOnsInstaller "$@"

