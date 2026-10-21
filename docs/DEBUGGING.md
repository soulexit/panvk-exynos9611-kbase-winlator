# Debugging the Winlator package

## Is the driver actually loaded?

```sh
adb logcat -d -s 'panvk:*' 'Mesa:*' | tail -100
```

Look for the PanVK startup line and the GPU name. If there is no `panvk` output at all, Winlator
did not load the imported library; it is still using the system Vulkan driver or the container
setting points at another driver.

Check the driver directory:

```sh
adb shell "ls -la /data/data/com.winlator.cmod/files/contents/adrenotools/"
adb shell "cat /data/data/com.winlator.cmod/files/contents/adrenotools/*/meta.json"
```

## Import fails

- The zip must contain `meta.json` at the root.
- `libraryName` in `meta.json` must match the file name; this package uses
  `libvulkan_panfrost.so`.
- Re-download the zip; a truncated download fails unzip silently in some file pickers.
- Winlator's AdrenoTools importer is designed around Adreno/Turnip drivers. A Mali driver still
  needs a valid `meta.json`; that is why this repository exists instead of shipping the raw `.so`.

## Container crashes before the first frame

- Check `AndroidRuntime` for a Java crash in Winlator itself (not the driver).
- Check `panvk`/`Mesa` for `Unknown gpu_id`, `ENOMEM`, `JIT`, or `EINVAL`.
- Try a fresh container with default settings; a stale DXVK cache or Box64 preset can mask the
  driver result.
- Delete the container's `drive_c/windows/system32` DXVK DLLs only if you know they are stale.

## `VK_ERROR_DEVICE_LOST` / GPU fault

```sh
adb shell 'dmesg | grep -iE "mali|kbase|fault|mmu|job"' | tail -100
```

Common causes on a new kbase:

- **Atom stride mismatch** — the driver submits 64-byte `base_jd_atom`; a kernel that expects 56 or
  72 bytes returns `EINVAL` or raises `JOB_CONFIG_FAULT`. This needs a source patch, not an app
  setting.
- **Unsupported feature path** — geometry/tessellation emulation is new on Bifrost; a specific game
  can trigger a bad job. Reproduce with the smallest draw and report the pipeline.
- **Memory pressure** — a 6 GB phone with Wine + DXVK can run out; close background apps.

Force-stop Winlator. If `cat /sys/class/misc/mali0/device/core_mask` stays `0x0` or the GPU clock is
stuck, reboot.

## Black screen but no crash

- Confirm the frame is presented: the DXVK HUD should count frames.
- Try 800×600 and a different DXVK version.
- This may be the Android 16 gralloc/AFBC import path, not the 3D pipeline. Check `panvk` logs for
  gralloc/AHardwareBuffer messages.
- The vendor Vulkan driver should still present correctly; use it as the control.

## Very slow rendering

Expected: G72 has 3 cores and PanVK emulates GS/tessellation/XFB with compute jobs. Reduce
resolution, disable MSAA, use D3D9 instead of D3D11, and try a DXVK version known to work on the
device. Report FPS with resolution so the number means something.

## Collecting a useful report

```sh
./scripts/collect-logs.sh
```

Attach the tarball, the driver zip SHA-256, the container settings and the exact game/scene. Do not
publish a raw logcat without checking it for personal paths.
