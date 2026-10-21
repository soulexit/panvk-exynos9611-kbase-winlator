#!/bin/sh
# Build the Winlator AdrenoTools zip.
#
# usage: ./scripts/package.sh [--so PATH] [--out DIR]
set -eu
. "$(dirname -- "$0")/lib.sh"

so="$BUILD_ROOT/prebuilt/driver/libvulkan_panfrost.so"
out="$DIST_DIR"
while [ $# -gt 0 ]; do
    case "$1" in
        --so) shift; [ $# -gt 0 ] || die "--so needs a value"; so=$1 ;;
        --out) shift; [ $# -gt 0 ] || die "--out needs a value"; out=$1 ;;
        *) die "unknown option: $1" ;;
    esac
    shift
done

[ -f "$so" ] || die "driver not found: $so (run fetch-prebuilt.sh or build-from-source.sh)"
need python3

python3 "$ROOT/scripts/package.py" "$so" "$out"
log "output:"
ls -l "$out"
