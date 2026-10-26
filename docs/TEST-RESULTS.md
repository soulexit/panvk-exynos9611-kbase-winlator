# Winlator test results

## Environment

| | |
|---|---|
| Device | Samsung Galaxy A51 4G (SM-A515F) |
| SoC / GPU | Exynos 9611 / Mali-G72 MP3 r0p1 (`0x6221`) |
| Android / kernel | 16 (API 36) / 4.14.364-openela |
| Kbase | DDK r38p1-01bet0 |
| Winlator | 4.1 (`com.winlator.cmod`) |
| RAM | 6 GB |

## Results

| Package | Date | Driver listed | Container starts | vkcube | D3D9 game | D3D11 game | Notes |
|---|---|---|---|---|---|---|---|
| v0.02 | 2026-10-26 | **PASS** (direct install) | **PASS** | **PASS** (compositor swapchain) | **PASS** — NFS MW intro, title, attract video at 50–60 FPS, no GPU fault | untested (DmC exits in Wine before DXVK) | driver v0.02; in-race gameplay not verified |
| v0.01 | 2026-10-21 | **PASS** (direct install) | **PASS** | **PASS** (compositor swapchain) | inconclusive | pending | driver loaded; NFS exited after ~13 s |

## v0.02 details

```text
Date:              2026-10-26
Package:           panvk-exynos9611-winlator-v0.02.zip
Winlator version:  4.1 (com.winlator.cmod)
Container:         container 1, FEXCore, DXVK-Sarek 1.11.0 (D3D9), 1280x720
Driver selected:   PanVK-Exynos9611-v0.02 (Wrapper(Mali-G72 MC3), Vulkan 1.3.363)
Result:            NFS Most Wanted Black Edition: intro video, logos, title screen and
                   attract video render correctly
FPS:               50-60 (Winlator HUD)
Corruption:        none seen
Logs:              DXVK log written to D:\dxvk-logs; dmesg: no GPU fault
```

The game was started with `XServerDisplayActivity` and a `.desktop` shortcut. Taps sent with adb
did not register as mouse clicks, so the title's "CLICK to continue" was not passed and in-race
rendering is not verified.

## v0.01 details

**Driver load:** Winlator's AdrenoTools hook logged

```text
hook_android_dlopen_ext: loading custom driver:
  /data/data/com.winlator.cmod/files/contents/adrenotools/PanVK-Exynos9611-v0.01/libvulkan_panfrost.so
```

**Compositor:** `Winlator_Renderer` created a Vulkan device and a 1080×2400 swapchain on
`Mali-G72 MC3` (`vendorID=0x13b5`, `driverVersion=0x6802063`, `apiVersion=1.3.358`). This proves the
Android WSI/gralloc path works in the Winlator process.

**Game:** Need for Speed: Most Wanted Black Edition (`speed.exe`, DXVK 2.6.2-arm64ec-gplasync)
started from container 1 and its process exited about 13 seconds later. The app returned to the
library. No DXVK/Vulkan error reached logcat before exit, so the cause is not yet known. This is
**not** a working-game result.

## Run details

Add one subsection per run:

```text
Date:
Package / SHA-256:
Winlator version:
Container: Windows version, Box64/FEX, DXVK version
Resolution:
Driver selected:
Result:
FPS:
Corruption:
Logs:
```

## Known-good reference

The **System Vulkan driver** (vendor `vulkan.universal9611.so`) is the control. If a game fails on
both, the problem is not this package.
