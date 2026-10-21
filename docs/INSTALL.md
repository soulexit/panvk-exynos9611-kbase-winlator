# Install in Winlator

Tested with **Winlator 4.1 (`com.winlator.cmod`)** on Android 16.

## 1. Download

Take `panvk-exynos9611-winlator-v0.01.zip` from this repository's **Releases** page. Do not rename
the `.zip`; the importer uses the file but the driver name comes from `meta.json`.

Verify the download if a `.sha256` file is published:

```sh
sha256sum -c panvk-exynos9611-winlator-v0.01.zip.sha256
```

## 2. Import

1. Open Winlator.
2. Open **Contents** (the component/driver screen).
3. Open **AdrenoTools**.
4. Tap **Install** / **Import** and select the zip.
5. Wait until **PanVK Exynos 9611 (Mali-G72 MP3)** appears in **Available Drivers**.
6. If the importer keeps a progress indicator, do not leave the screen until it finishes.

Winlator unpacks the zip under:

```text
/data/data/com.winlator.cmod/files/contents/adrenotools/<driver name>/
├── meta.json
└── libvulkan_panfrost.so
```

If the driver does not appear, use the adb path below and check the folder layout.

## 3. Select the driver per container

1. Open the container you want to test.
2. Open **Graphics** / **Vulkan** settings.
3. Set **Graphics driver** (or **Vulkan driver**) to
   **PanVK Exynos 9611 (Mali-G72 MP3)**.
4. Keep **DXVK** enabled for Direct3D games. DXVK translates D3D9/10/11 to Vulkan; the driver does
   not implement Direct3D itself.
5. Start with a low resolution (800×600 or 1280×720), not 1080p.

The system Vulkan driver remains the default for every other container.

## 4. First run

Start with a small workload:

1. `vkcube.exe` from the Winlator tools, or any Vulkan sample.
2. A D3D9 game with simple shaders.
3. Only then a D3D11 game.

Expect a slow first launch: PanVK compiles shaders and DXVK creates its pipeline cache. A black
window for several seconds is normal; a crash or a device-lost error is not.

## Install with adb

```sh
./scripts/install-adb.sh                     # push the zip to /sdcard/Download
./scripts/install-adb.sh --root --yes        # direct install, needs working su
```

The direct install copies the unpacked driver to:

```text
/data/data/com.winlator.cmod/files/contents/adrenotools/PanVK-Exynos9611-v0.01/
```

Force-stop Winlator afterwards so it rescans the driver list. Direct install is an advanced path:
the in-app importer is preferred because it registers the driver with Winlator's own manager.

## Revert

In the container, select **System Vulkan driver**. Then remove the imported entry from the
AdrenoTools list (or delete the folder if installed directly). Nothing under `/vendor` or `/system`
was modified.

## Troubleshooting

| Problem | Check |
|---|---|
| Zip rejected | `meta.json` and `libvulkan_panfrost.so` must be at the zip root |
| Driver listed but container crashes | `adb logcat -d -s panvk:* Mesa:* AndroidRuntime:E` |
| Driver listed but not used | The container may still point at System Vulkan; re-open Graphics settings |
| Black screen, no crash | Swapchain/gralloc issue; try a different resolution and check `dmesg` for faults |
| `DEVICE_LOST` | GPU fault; force-stop Winlator, reboot if kbase is wedged, then reproduce with vkcube |
| Very low FPS | Expected on a 3-core G72; GS/tessellation are compute-emulated |

See [`DEBUGGING.md`](DEBUGGING.md) for the full failure list.
