#!/bin/sh
#
# Copyright 2023 The MathWorks, Inc.

filename=$0

BINDIR=$(CDPATH= cd -- $(dirname -- "$0") && pwd)

# Preload glibc_shim in case of RHEL7 variants
test -e /usr/bin/ldd && ldd --version | grep -q "(GNU libc) 2\.17" &&
    LD_PRELOAD="${LD_PRELOAD:+${LD_PRELOAD}:}$BINDIR/glibc-2.17_shim.so" &&
    export LD_PRELOAD="${LD_PRELOAD:+${LD_PRELOAD}:}$BINDIR/glibc-2.17_shim.so"

$BINDIR/$ARCH/MathWorksLicenseDeactivation $@

