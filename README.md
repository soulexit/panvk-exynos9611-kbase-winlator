# PanVK for Winlator — Exynos 9611 / Mali-G72 MP3

**AdrenoTools-style Vulkan driver packages** for running
[PanVK](https://docs.mesa3d.org/drivers/panfrost.html) inside **Winlator** on the
**Samsung Galaxy A51 (SM-A515F)** and other **Exynos 9611 + Mali-G72 MP3** phones.

The driver uses the phone's stock **Arm `mali_kbase`** kernel interface (`/dev/mali0`). No custom
kernel, no `/dev/dri`, no root required to use it.

| | |
|---|---|
| **Device** | Samsung Galaxy A51 4G (SM-A515F, `a51`) |
| **SoC / GPU** | Exynos 9611 / Mali-G72 MP3 r0p1 (`0x6221`, Mesa arch **v6**) |
| **Android** | 16 / API 36 |
| **Kernel / kbase** | Linux 4.14.364 / Arm DDK `r38p1-01bet0` |
| **Winlator tested** | `com.winlator.cmod` **4.1** |
| **Driver base** | [`JimVulkan/mali-panvk`](https://github.com/JimVulkan/mali-panvk) `fb3b49d`, Mesa 26.3.0-devel |
| **Current build** | **v0.02 — debug, expect crashes** |

> [!WARNING]
> Experimental driver. It can hang the GPU, crash the container, or produce corrupt output. Keep the
> system Vulkan driver and your previous driver installed so you can switch back.

## What this repository contains

This is a **packaging repository**, not a second driver fork. It takes the pinned driver built by
[`panvk-exynos9611-kbase-termux`](https://github.com/soulexit/panvk-exynos9611-kbase-termux) and
produces the zip layout Winlator's AdrenoTools importer expects:

```text
panvk-exynos9611-winlator-v0.02.zip
├── meta.json
├── libvulkan_panfrost.so
├── NOTICE.txt
└── BUILD-INFO.txt
```

The `meta.json` fields (`schemaVersion`, `name`, `libraryName`, `minApi`, …) are what Winlator reads
when it lists and selects a custom driver. `libraryName` is `libvulkan_panfrost.so` for Winlator.

## Goal

Make DXVK games run on the A51 through a **Mesa Vulkan driver that talks to kbase**, instead of the
vendor Vulkan blob:

- D3D9 / D3D10 / D3D11 through DXVK in Winlator;
- Vulkan 1.3 features that DXVK needs, including robustness2 and null descriptors;
- geometry shaders, tessellation and transform feedback, which Bifrost lacks in hardware and PanVK
  emulates with compute jobs;
- a package that can be imported by normal users without root or adb.

The realistic first target is a **D3D9 game at a playable frame rate** (for example Need for Speed:
Most Wanted), not modern D3D12 titles.

## Status

| Build | Date | Winlator | Driver selected | DXVK test | FPS / result | Notes |
|---|---|---|---|---|---|---|
| v0.02 | 2026-10-26 | 4.1 (`com.winlator.cmod`) | **PASS** | **D3D9 PASS** — NFS Most Wanted intro, title, attract video | 50–60 FPS, 0 GPU faults | driver v0.02 (Mesa 27.0-devel + fixes); in-race not verified |
| v0.01 | 2026-10-21 | 4.1 (`com.winlator.cmod`) | **PASS** | swapchain **PASS**, game pending | — | driver loaded; NFS exited after ~13 s |

### v0.02 validation

- Package unpacked to `.../contents/adrenotools/PanVK-Exynos9611-v0.02/` and selected in
  container 1 (FEXCore, DXVK-Sarek 1.11.0, 1280×720).
- **Need for Speed: Most Wanted Black Edition** (D3D9): the intro video, EA/NFS logos, title
  screen ("CLICK to continue") and attract video render correctly at **50–60 FPS** on
  `Wrapper(Mali-G72 MC3)`, with no GPU fault in `dmesg`. v0.01 exited after ~13 s on the same game.
- In-race gameplay is not verified: menu clicks sent from adb did not register.
- DmC: Devil May Cry (D3D11) exits inside Wine before DXVK starts (no DXVK log); D3D11 is untested.

### v0.01 validation

- The package was unpacked to
  `/data/data/com.winlator.cmod/files/contents/adrenotools/PanVK-Exynos9611-v0.01/`.
- Winlator's AdrenoTools hook loaded it:
  `hook_android_dlopen_ext: loading custom driver: .../libvulkan_panfrost.so`.
- Winlator's compositor created a **1080×2400** swapchain on `Mali-G72 MC3`
  (`vendorID=0x13b5`, `apiVersion=1.3.358`, selected present mode).
- The Need for Speed: Most Wanted process exited about 13 seconds after start. No DXVK error was
  captured, so this is recorded as **inconclusive**, not as a working game.

Results are maintained in [`docs/TEST-RESULTS.md`](docs/TEST-RESULTS.md). A package that has not
been selected in Winlator is not "working".

## Requirements

### Phone

- Samsung Galaxy A51 / Exynos 9611 / Mali-G72 MP3 (other G72 devices may work; report them).
- Android 12 or newer (the driver is built for API 31; tested on API 36).
- arm64-v8a.
- 4 GB RAM minimum; 6 GB recommended. GPU memory comes from the same RAM as Android and Wine.
- `/dev/mali0` accessible to the app (mode `0666` on the A51).
- Winlator `com.winlator.cmod` 4.1 or newer with the AdrenoTools driver UI.

### Build host

- Linux x86_64 or a proot Ubuntu container on the phone.
- Android NDK r29+ (r30 tested), Meson, Ninja, Python 3, `glslangValidator`, LLVM 20.
- The full dependency list and troubleshooting are in the
  [Termux repository build guide](https://github.com/soulexit/panvk-exynos9611-kbase-termux/blob/main/docs/BUILD.md).

## Install

### Option A — import the zip in Winlator (no root, recommended)

1. Download `panvk-exynos9611-winlator-v0.02.zip` from
   [Releases](https://github.com/soulexit/panvk-exynos9611-kbase-winlator/releases).
2. Copy it to the phone (Downloads is fine).
3. Open **Winlator → Contents → AdrenoTools** (the driver manager).
4. Tap **Install / Import**, choose the zip, wait for it to appear under **Available Drivers**.
5. Open the container → **Graphics / Vulkan** settings → select
   **PanVK Exynos 9611 (Mali-G72 MP3)**.
6. Start with `vkcube.exe` or a light D3D9 game. Do not start with a heavy D3D11 title.

If Winlator shows an import error, check that the zip has `meta.json` and
`libvulkan_panfrost.so` at the **root**, not inside a folder.

### Option B — push with adb, then import

```sh
./scripts/install-adb.sh
```

This copies the zip to `/sdcard/Download/` and prints the import path. It does not silently modify
Winlator's data directory.

### Option C — direct install (root, advanced)

```sh
./scripts/install-adb.sh --root --yes
```

Requires a working `su` for the shell. The script copies the unpacked driver to:

```text
/data/data/com.winlator.cmod/files/contents/adrenotools/PanVK-Exynos9611-v0.02/
```

Force-stop Winlator before and after. Use this only when the in-app importer is unavailable; the
normal import path is safer and survives app updates better.

## Uninstall / revert

- In Winlator, select **System Vulkan driver** in the container settings.
- Delete the imported driver entry from the AdrenoTools list.
- Root install: remove the folder under
  `/data/data/com.winlator.cmod/files/contents/adrenotools/` and restart Winlator.

The vendor Vulkan driver is never modified.

## Build the package

### From the released driver (fast, reproducible)

```sh
git clone https://github.com/soulexit/panvk-exynos9611-kbase-winlator.git
cd panvk-exynos9611-kbase-winlator
./scripts/fetch-prebuilt.sh
./scripts/package.sh
```

`fetch-prebuilt.sh` downloads the pinned Termux release, verifies the driver SHA-256 against the
release's `SHA256SUMS`, and extracts `libvulkan_panfrost.so`.

### From source

```sh
./scripts/build-from-source.sh /path/to/android-ndk
```

This clones the sister Termux repository at the tag in `VERSION`, builds the driver there, and then
packages it with this repository's `meta.json`. Use it when testing a patch that is not released yet.

### Package only

```sh
./scripts/package.sh --so /path/to/libvulkan_panfrost.so
```

Output: `dist/panvk-exynos9611-winlator-v0.02.zip` plus a SHA-256 file.

## Test procedure

1. Select the driver in the container.
2. Run `vkcube.exe` first (DXVK D3D11, tiny workload).
3. If that works, run a D3D9 game at 800×600 or 1280×720, not native 1080p.
4. Capture:
   - Winlator container settings (DXVK version, Box64/FEX, resolution, GPU driver);
   - `adb logcat -d -s panvk:* Mesa:* AndroidRuntime:E > logcat.txt`;
   - `adb shell dmesg | grep -iE 'mali|kbase|gpu|fault' > dmesg.txt`;
   - a screenshot of the DXVK HUD if it is enabled.
5. Fill in [`docs/TEST-RESULTS.md`](docs/TEST-RESULTS.md) or the report template.

```sh
./scripts/collect-logs.sh
```

## Known limitations

- **Mali-G72 is Mesa v6 Bifrost**, the least-tested Bifrost path. The base tree validated G72 on a
  Galaxy Tab S6 Lite (same SoC family); the A51's Android 16 + kbase r38 is a new combination.
- **BCn is emulated by the driver** (v0.02+). If textures look wrong, set the container's BCn
  emulation to the wrapper's, or put `PANVK_NO_BC_EMU=1` in `panvk.env` next to the driver.
- **No D3D12 / vkd3d-proton.** The required Vulkan features are not there yet.
- **GS/tessellation/XFB are compute-emulated.** On a 3-core G72 this is slow; expect D3D9 and light
  D3D11 only.
- **Shared memory.** On a 6 GB phone, Wine + DXVK + a game can exhaust RAM; close background apps.
- **First frame / shader compilation** can take seconds; a black screen for a few seconds is not
  necessarily a crash.
- **Android 16 gralloc** may break swapchain presentation; offscreen tests can pass while the
  window stays black.

## Debugging

| Switch | Effect |
|---|---|
| `PANVK_DEBUG=startup` | Device-creation diagnostics |
| `PANVK_DEBUG=trace` | Verbose tracing |
| `PANVK_FORCE_IDVS=1` | Re-enable index-driven vertex shading |
| `MESA_LOG=stderr` | Send Mesa logs to stderr |

Winlator does not give the driver a shell, so set these through the container's environment field if
it exposes one, or use a debug build with the switch compiled in. Logs land in logcat under `panvk`
and `Mesa`.

See [`docs/DEBUGGING.md`](docs/DEBUGGING.md) for the failure classes that matter on this device:
atom stride / `JOB_CONFIG_FAULT`, `VK_ERROR_DEVICE_LOST`, black swapchain, and app-side driver
loading.

## Versioning and releases

`v0.01`, `v0.02`, … follow the source driver version. Each release contains:

- `panvk-exynos9611-winlator-v0.0x.zip`
- `panvk-exynos9611-winlator-v0.0x.zip.sha256`
- `BUILD-INFO.txt` (source tag, driver SHA-256, package date)

Releases are immutable. Test results and the exact Winlator version go in the release notes.

## Repository layout

```text
README.md
VERSION
NOTICE.md
scripts/
  fetch-prebuilt.sh     download + verify the pinned Termux release
  build-from-source.sh  clone/build the sister repo, then package
  package.sh            wrapper around package.py
  package.py            create the AdrenoTools zip + meta.json
  install-adb.sh        push to Download, optional root install
  collect-logs.sh       adb logcat + dmesg bundle
docs/
  INSTALL.md
  TESTING.md
  DEBUGGING.md
  TEST-RESULTS.md
  REPORT-TEMPLATE.md
```

## Development assistance

Made with help from **DeepSeek** and **OpenCode**.

## Credits and license

Driver: Mesa PanVK + [`JimVulkan/mali-panvk`](https://github.com/JimVulkan/mali-panvk) (MIT).
Packaging and documentation: MIT. See [`NOTICE.md`](NOTICE.md).

Not affiliated with Winlator, Arm, Samsung, Mesa or the Panfrost project. Mali and Arm are
trademarks of Arm Limited; Samsung, Galaxy and Exynos are trademarks of Samsung Electronics.
