#!/bin/sh
# Push the Winlator driver zip to the phone, or install it directly with root.
#
# usage:
#   ./scripts/install-adb.sh [zip]
#   ./scripts/install-adb.sh --root --yes [zip]
set -eu
. "$(dirname -- "$0")/lib.sh"

root=0
yes=0
zip=""
while [ $# -gt 0 ]; do
    case "$1" in
        --root) root=1 ;;
        --yes) yes=1 ;;
        --*) die "unknown option: $1" ;;
        *) zip=$1 ;;
    esac
    shift
done

zip=${zip:-$DIST_DIR/$PACKAGE_NAME.zip}
[ -f "$zip" ] || die "zip not found: $zip (run scripts/package.sh first)"
need adb
adb get-state >/dev/null 2>&1 || die "no adb device; check 'adb devices'"

pkg=$(adb shell pm list packages | grep -F "$WINLATOR_PACKAGE" | head -1 | cut -d: -f2 | tr -d '\r')
[ "$pkg" = "$WINLATOR_PACKAGE" ] || die "$WINLATOR_PACKAGE is not installed"

remote="/sdcard/Download/$(basename "$zip")"
log "pushing $(basename "$zip") to $remote"
adb push "$zip" "$remote" >/dev/null

if [ "$root" = 0 ]; then
    echo
    echo "zip is on the phone: $remote"
    echo "In Winlator: Contents > AdrenoTools > Install/Import, then choose the zip."
    exit 0
fi

[ "$yes" = 1 ] || die "root install copies files into the app's private data; pass --yes to confirm"
adb shell su -c true >/dev/null 2>&1 || die "adb shell su is not available; grant root to Shell or use the in-app import"

dest="/data/data/$WINLATOR_PACKAGE/files/contents/adrenotools/PanVK-Exynos9611-v$VERSION"
tmp="/sdcard/Download/.panvk-install-$$"
local_tmp=$(mktemp -d)
trap 'rm -rf "$local_tmp"' EXIT INT TERM

unzip -q "$zip" -d "$local_tmp"
adb push "$local_tmp" "$tmp" >/dev/null
adb shell su -c "rm -rf '$dest' && mkdir -p '$dest' && cp -r '$tmp/.' '$dest/' && rm -rf '$tmp'"
uid=$(adb shell su -c "stat -c %u /data/data/$WINLATOR_PACKAGE" | tr -d '\r')
adb shell su -c "chown -R $uid:$uid '$dest'"

echo "installed to $dest"
echo "force-stop Winlator, reopen it, then select PanVK Exynos 9611 in the container settings"
