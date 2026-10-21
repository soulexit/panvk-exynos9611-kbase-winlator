#!/bin/sh
# Download and verify the pinned driver from the sister Termux repository.
#
# usage: ./scripts/fetch-prebuilt.sh [--url URL] [--sha256 HASH]
set -eu
. "$(dirname -- "$0")/lib.sh"

url="$RELEASE_URL/panvk-exynos9611-termux-v$VERSION.zip"
expected=""
while [ $# -gt 0 ]; do
    case "$1" in
        --url) shift; [ $# -gt 0 ] || die "--url needs a value"; url=$1 ;;
        --sha256) shift; [ $# -gt 0 ] || die "--sha256 needs a value"; expected=$1 ;;
        *) die "unknown option: $1" ;;
    esac
    shift
done

need curl
need unzip
need sha256sum

work="$BUILD_ROOT/prebuilt"
rm -rf "$work"
mkdir -p "$work"
zip="$work/source-driver.zip"

log "downloading $url"
curl -fL --retry 3 -o "$zip" "$url"

if [ -n "$expected" ]; then
    actual=$(sha256sum "$zip" | cut -d' ' -f1)
    [ "$actual" = "$expected" ] || die "zip SHA-256 mismatch: $actual != $expected"
    log "zip SHA-256 verified"
fi

unzip -q "$zip" -d "$work/unpacked"
[ -f "$work/unpacked/libvulkan_panfrost.so" ] || die "release has no libvulkan_panfrost.so"

# The release ships SHA256SUMS over its own files.
if [ -f "$work/unpacked/SHA256SUMS" ]; then
    (cd "$work/unpacked" && sha256sum -c SHA256SUMS)
fi

mkdir -p "$work/driver"
cp "$work/unpacked/libvulkan_panfrost.so" "$work/driver/libvulkan_panfrost.so"
cp "$work/unpacked/SHA256SUMS" "$work/driver/SHA256SUMS" 2>/dev/null || true
cp "$work/unpacked/BUILD-INFO.txt" "$work/driver/BUILD-INFO.txt" 2>/dev/null || true

sha256sum "$work/driver/libvulkan_panfrost.so" | tee "$work/driver/driver.sha256"
log "driver ready: $work/driver/libvulkan_panfrost.so"
