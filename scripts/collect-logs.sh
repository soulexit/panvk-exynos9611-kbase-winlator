#!/bin/sh
# Collect Winlator + PanVK logs over adb.
set -eu
. "$(dirname -- "$0")/lib.sh"

need adb
stamp=$(date -u +%Y%m%dT%H%M%SZ)
out="$DIST_DIR/logs-$stamp"
mkdir -p "$out"

adb shell 'getprop ro.product.model; getprop ro.build.display.id; uname -a' > "$out/device.txt" 2>&1 || true
adb shell 'cat /sys/class/misc/mali0/device/gpuinfo; cat /sys/class/misc/mali0/device/core_mask' > "$out/gpu.txt" 2>&1 || true
adb shell "dumpsys package $WINLATOR_PACKAGE | grep -E 'versionName|versionCode'" > "$out/winlator-version.txt" 2>&1 || true
adb shell 'dmesg | grep -iE "mali|kbase|gpu|fault|mmu"' > "$out/dmesg.txt" 2>&1 || true
adb logcat -d -s 'panvk:*' 'Mesa:*' 'AndroidRuntime:E' > "$out/logcat.txt" 2>&1 || true
adb shell "ls -la /data/data/$WINLATOR_PACKAGE/files/contents/adrenotools/ 2>/dev/null" > "$out/drivers.txt" 2>&1 || true

tar -czf "$out.tar.gz" -C "$DIST_DIR" "$(basename "$out")"
rm -rf "$out"
echo "wrote $out.tar.gz"
