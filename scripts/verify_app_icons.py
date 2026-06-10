#!/usr/bin/env python3
"""Verify SkateTrack app icon assets for iOS, watchOS, and macOS."""
from pathlib import Path
import json
import sys

ROOT = Path(__file__).resolve().parents[1]

ICON_SETS = [
    ("iOS", ROOT / "iOS/App/Assets.xcassets/AppIcon.appiconset", 18),
    ("watchOS", ROOT / "watchOS/App/Assets.xcassets/AppIcon.appiconset", 24),
    ("macOS", ROOT / "macOS/App/Assets.xcassets/AppIcon.appiconset", 10),
]


def fail(message: str) -> None:
    print(f"App icon check failed: {message}")
    sys.exit(1)


for platform, path, expected_count in ICON_SETS:
    contents = path / "Contents.json"
    if not contents.exists():
        fail(f"missing {platform} Contents.json")
    data = json.loads(contents.read_text(encoding="utf-8"))
    images = data.get("images", [])
    if len(images) < expected_count:
        fail(f"{platform} AppIcon has only {len(images)} images")
    for image in images:
        filename = image.get("filename")
        if not filename:
            fail(f"{platform} AppIcon entry missing filename")
        file_path = path / filename
        if not file_path.exists():
            fail(f"missing {platform} icon file {filename}")
        if file_path.stat().st_size <= 0:
            fail(f"empty {platform} icon file {filename}")

if not (ROOT / "macOS/App/SkateTrack.icns").exists():
    fail("missing macOS SkateTrack.icns fallback")

pbx = (ROOT / "SkateTrack.xcodeproj/project.pbxproj").read_text(encoding="utf-8")
for required in [
    "ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;",
    "INFOPLIST_KEY_CFBundleIconName = AppIcon;",
    "ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = YES;",
    "INFOPLIST_KEY_CFBundleIconFile = SkateTrack;",
    "SkateTrack.icns in Resources",
]:
    if required not in pbx:
        fail(f"project missing {required}")

print("App icon check passed: iOS, watchOS, macOS AppIcon assets and macOS icns fallback")
