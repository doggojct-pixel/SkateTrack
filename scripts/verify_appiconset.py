#!/usr/bin/env python3
"""Verify iOS AppIcon.appiconset has no unassigned PNG children and required icon slots are present."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
APPICON = ROOT / "iOS" / "App" / "Assets.xcassets" / "AppIcon.appiconset"
CONTENTS = APPICON / "Contents.json"

REQUIRED = [
    ("iphone", "20x20", "2x", (40, 40)),
    ("iphone", "20x20", "3x", (60, 60)),
    ("iphone", "29x29", "2x", (58, 58)),
    ("iphone", "29x29", "3x", (87, 87)),
    ("iphone", "40x40", "2x", (80, 80)),
    ("iphone", "40x40", "3x", (120, 120)),
    ("iphone", "60x60", "2x", (120, 120)),
    ("iphone", "60x60", "3x", (180, 180)),
    ("ipad", "20x20", "1x", (20, 20)),
    ("ipad", "20x20", "2x", (40, 40)),
    ("ipad", "29x29", "1x", (29, 29)),
    ("ipad", "29x29", "2x", (58, 58)),
    ("ipad", "40x40", "1x", (40, 40)),
    ("ipad", "40x40", "2x", (80, 80)),
    ("ipad", "76x76", "1x", (76, 76)),
    ("ipad", "76x76", "2x", (152, 152)),
    ("ipad", "83.5x83.5", "2x", (167, 167)),
    ("ios-marketing", "1024x1024", "1x", (1024, 1024)),
]

def fail(message: str) -> None:
    print(f"AppIcon check failed: {message}", file=sys.stderr)
    sys.exit(1)

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

    icon_path = APPICON / filename
    with Image.open(icon_path) as image:
        if image.size != expected_pixels:
            fail(f"{filename} has {image.size}, expected {expected_pixels}")

print("AppIcon check passed: all iOS AppIcon slots assigned, no unassigned PNG children remain.")
