#!/bin/sh
# Build the driver from the sister Termux repository at the tag in VERSION, then package it.
#
# usage:
#   ./scripts/build-from-source.sh /path/to/android-ndk
#   ./scripts/build-from-source.sh /path/to/android-ndk --source-dir ../panvk-exynos9611-kbase-termux
set -eu
. "$(dirname -- "$0")/lib.sh"

ndk=""
src=""
while [ $# -gt 0 ]; do
    case "$1" in
        --source-dir) shift; [ $# -gt 0 ] || die "--source-dir needs a value"; src=$1 ;;
        --*) die "unknown option: $1" ;;
        *) ndk=$1 ;;
    esac
    shift
done

[ -n "$ndk" ] || ndk=${ANDROID_NDK_HOME:-${ANDROID_NDK_ROOT:-}}
[ -n "$ndk" ] || die "pass the Android NDK path or set ANDROID_NDK_HOME"

if [ -z "$src" ]; then
    src="$BUILD_ROOT/source-repo"
    rm -rf "$src"
    need git
    log "cloning $SOURCE_REPO at $SOURCE_TAG"
    git clone --depth 1 --branch "$SOURCE_TAG" "$SOURCE_REPO" "$src"
fi

[ -x "$src/scripts/build.sh" ] || die "$src is not a panvk-exynos9611-kbase-termux checkout"

log "building driver in $src"
"$src/scripts/fetch-source.sh"
"$src/scripts/build.sh" "$ndk" --no-fetch

so="$src/dist/libvulkan_panfrost.so"
[ -f "$so" ] || die "build produced no $so"

"$ROOT/scripts/package.sh" --so "$so"
