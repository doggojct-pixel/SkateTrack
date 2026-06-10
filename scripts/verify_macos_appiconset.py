#!/usr/bin/env python3
"""Verify macOS AppIcon.appiconset has no unassigned PNG children and required macOS slots are present.

No third-party Python packages are required.
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APPICON = ROOT / "macOS" / "App" / "Assets.xcassets" / "AppIcon.appiconset"
CONTENTS = APPICON / "Contents.json"

REQUIRED = [
    ("mac", "16x16", "1x", (16, 16)),
    ("mac", "16x16", "2x", (32, 32)),
    ("mac", "32x32", "1x", (32, 32)),
    ("mac", "32x32", "2x", (64, 64)),
    ("mac", "128x128", "1x", (128, 128)),
    ("mac", "128x128", "2x", (256, 256)),
    ("mac", "256x256", "1x", (256, 256)),
    ("mac", "256x256", "2x", (512, 512)),
    ("mac", "512x512", "1x", (512, 512)),
    ("mac", "512x512", "2x", (1024, 1024)),
]


def fail(message: str) -> None:
    print(f"macOS AppIcon check failed: {message}", file=sys.stderr)
    sys.exit(1)


def image_size(path: Path) -> tuple[int, int]:
    result = subprocess.run(
        ["sips", "-g", "pixelWidth", "-g", "pixelHeight", str(path)],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        fail(f"could not inspect {path.name}: {result.stderr.strip()}")

    width = None
    height = None
    for line in result.stdout.splitlines():
        line = line.strip()
        if line.startswith("pixelWidth:"):
            width = int(line.split(":", 1)[1].strip())
        elif line.startswith("pixelHeight:"):
            height = int(line.split(":", 1)[1].strip())

    if width is None or height is None:
        fail(f"could not parse image dimensions for {path.name}")

    return width, height


if not APPICON.exists():
    fail(f"missing {APPICON}")
if not CONTENTS.exists():
    fail(f"missing {CONTENTS}")

data = json.loads(CONTENTS.read_text(encoding="utf-8"))
images = data.get("images", [])
entries = {(item.get("idiom"), item.get("size"), item.get("scale")): item for item in images}
referenced = {item.get("filename") for item in images if item.get("filename")}
pngs = {path.name for path in APPICON.glob("*.png")}

extras = sorted(pngs - referenced)
missing_files = sorted(referenced - pngs)
if extras:
    fail("unassigned PNG children remain: " + ", ".join(extras))
if missing_files:
    fail("Contents.json references missing files: " + ", ".join(missing_files))

for idiom, size, scale, expected_pixels in REQUIRED:
    item = entries.get((idiom, size, scale))
    if not item:
        fail(f"missing required slot idiom={idiom} size={size} scale={scale}")

    filename = item.get("filename")
    if not filename:
        fail(f"required slot has no filename idiom={idiom} size={size} scale={scale}")

    actual = image_size(APPICON / filename)
    if actual != expected_pixels:
        fail(f"{filename} has {actual}, expected {expected_pixels}")

print("macOS AppIcon check passed: all macOS AppIcon slots assigned, no unassigned PNG children remain.")
