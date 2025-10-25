#!/bin/sh

filename=$0
cpath=`/bin/pwd`

BINDIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# Preload glibc_shim in case of RHLE7 variants
test -e /usr/bin/ldd &&  /usr/bin/ldd --version |  grep -q "(GNU libc) 2\.17"  \
              && export LD_PRELOAD="$BINDIR/glibc-2.17_shim.so"

arglist=
while [ $# -gt 0 ]; do
    # Quote arguments to preserve arguments that contain whitespace
     arglist="$arglist $1"
      shift
  done

$BINDIR/registerWithML $arglist

