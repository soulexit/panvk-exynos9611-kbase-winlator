# Testing the Winlator package

## Test order

| Step | Workload | What it proves |
|---|---|---|
| 1 | Driver appears in AdrenoTools | Package layout and `meta.json` are valid |
| 2 | Container starts | The driver loads in the app process |
| 3 | `vkcube.exe` | Vulkan device, swapchain and DXVK D3D11 presentation |
| 4 | D3D9 game at 800×600 | Real D3D9/DXVK workload |
| 5 | D3D11 game at 1280×720 | Heavier pipeline/feature coverage |

Do not skip to step 5. A driver that enumerates but faults on the first draw is not a working
driver.

## What to record

For every run:

- driver package version and SHA-256;
- Winlator version (`dumpsys package com.winlator.cmod | grep versionName`);
- container settings: Windows version, Box64/FEX, DXVK version, resolution, graphics driver;
- result: driver listed / container started / vkcube rendered / game rendered;
- FPS range (DXVK HUD or Winlator overlay) and resolution;
- visible corruption (missing textures, black screen, flicker);
- `logcat` and `dmesg` excerpts.

## Commands

```sh
# Driver import and version
adb shell "dumpsys package com.winlator.cmod | grep -E 'versionName|versionCode'"
adb shell "ls -la /data/data/com.winlator.cmod/files/contents/adrenotools/"

# Runtime logs
adb logcat -c
# ... run the test ...
adb logcat -d -s 'panvk:*' 'Mesa:*' 'AndroidRuntime:E' > logcat.txt
adb shell 'dmesg | grep -iE "mali|kbase|gpu|fault|mmu"' > dmesg.txt

# One-shot bundle
./scripts/collect-logs.sh
```

Root is needed only to list the app's private driver directory on some ROMs.

## Promotion rule

A build is promoted in [`TEST-RESULTS.md`](TEST-RESULTS.md) only when:

1. the driver is listed by Winlator;
2. `vkcube.exe` renders at least 60 frames without `VK_ERROR_DEVICE_LOST`;
3. a named D3D9 game reaches gameplay and renders correctly;
4. the logs are attached to the release notes.

A crash moves the build back to "experimental".

## Reporting

Copy [`REPORT-TEMPLATE.md`](REPORT-TEMPLATE.md) and include the bundle. Remove any personal paths
or account names from logs before publishing them.
