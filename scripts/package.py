#!/usr/bin/env python3
"""Package a stripped PanVK driver as a Winlator / AdrenoTools zip.

usage: package.py <libvulkan_panfrost.so> <output-dir>
"""
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    so, out_dir = os.path.abspath(sys.argv[1]), os.path.abspath(sys.argv[2])
    if not os.path.isfile(so):
        sys.exit("error: %s not found" % so)

    version = open(os.path.join(ROOT, "VERSION"), encoding="utf-8").read().strip()
    name = "panvk-exynos9611-winlator-v%s" % version
    stage = tempfile.mkdtemp(prefix="panvk-winlator-")
    try:
        shutil.copy2(so, os.path.join(stage, "libvulkan_panfrost.so"))
        meta = {
            "schemaVersion": 1,
            "name": "PanVK Exynos 9611 (Mali-G72 MP3)",
            "description": (
                "Mesa PanVK over the stock mali_kbase/JM kernel interface for the Samsung "
                "Galaxy A51 (Exynos 9611, Mali-G72 MP3). Debug build; D3D9/D3D10/D3D11 via "
                "DXVK only. Import in Winlator: Contents > AdrenoTools."
            ),
            "author": "panvk-exynos9611",
            "packageVersion": version,
            "vendor": "Mesa",
            "driverVersion": "Mesa 27.0.0-devel / PanVK kbase JM (driver v0.03)",
            "minApi": 31,
            "libraryName": "libvulkan_panfrost.so",
        }
        with open(os.path.join(stage, "meta.json"), "w", encoding="utf-8") as f:
            json.dump(meta, f, indent=2)
            f.write("\n")

        shutil.copy2(os.path.join(ROOT, "NOTICE.md"), os.path.join(stage, "NOTICE.txt"))
        shutil.copy2(os.path.join(ROOT, "LICENSE"), os.path.join(stage, "LICENSE"))

        info = [
            "package=%s" % name,
            "version=%s" % version,
            "built_utc=%s" % subprocess.run(
                ["date", "-u", "+%Y-%m-%dT%H:%M:%SZ"], capture_output=True, text=True
            ).stdout.strip(),
            "driver_sha256=%s" % sha256(so),
            "driver_bytes=%d" % os.path.getsize(so),
            "target=com.winlator.cmod 4.1+",
            "source_repo=https://github.com/soulexit/panvk-exynos9611-kbase-termux",
            "source_tag=v%s" % version,
        ]
        source_info = os.path.join(ROOT, "build", "prebuilt", "driver", "BUILD-INFO.txt")
        if os.path.isfile(source_info):
            info.append("")
            info.append("[source build]")
            info.append(open(source_info, encoding="utf-8").read().rstrip())
        with open(os.path.join(stage, "BUILD-INFO.txt"), "w", encoding="utf-8") as f:
            f.write("\n".join(info) + "\n")

        os.makedirs(out_dir, exist_ok=True)
        zip_path = os.path.join(out_dir, name + ".zip")
        with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
            for entry in sorted(os.listdir(stage)):
                z.write(os.path.join(stage, entry), entry)

        digest = sha256(zip_path)
        with open(zip_path + ".sha256", "w", encoding="utf-8") as f:
            f.write("%s  %s\n" % (digest, os.path.basename(zip_path)))
        print("packaged %s (%.1f MiB)" % (zip_path, os.path.getsize(zip_path) / (1 << 20)))
        print("sha256 %s" % digest)
    finally:
        shutil.rmtree(stage, ignore_errors=True)


if __name__ == "__main__":
    main()
