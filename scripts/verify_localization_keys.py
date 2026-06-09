#!/usr/bin/env python3
"""Verify that SkateTrack localization files contain identical key sets."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LOCALIZATION_ROOT = ROOT / "Shared" / "Localization"
STRING_FILE_PATTERN = re.compile(r'^\s*"(?P<key>[^"]+)"\s*=')


def parse_keys(path: Path) -> set[str]:
    keys: set[str] = set()
    for line in path.read_text(encoding="utf-8").splitlines():
        match = STRING_FILE_PATTERN.match(line)
        if match:
            keys.add(match.group("key"))
    return keys


def main() -> int:
    files = {
        "en": LOCALIZATION_ROOT / "en.lproj" / "Localizable.strings",
        "zh-Hant": LOCALIZATION_ROOT / "zh-Hant.lproj" / "Localizable.strings",
    }

    missing_files = [str(path) for path in files.values() if not path.exists()]
    if missing_files:
        print("Missing localization files:")
        for path in missing_files:
            print(f"- {path}")
        return 1

    key_sets = {language: parse_keys(path) for language, path in files.items()}
    reference_language = "en"
    reference_keys = key_sets[reference_language]
    failed = False

    for language, keys in key_sets.items():
        missing = sorted(reference_keys - keys)
        extra = sorted(keys - reference_keys)
        if missing or extra:
            failed = True
            print(f"Localization key mismatch for {language}:")
            if missing:
                print("  Missing keys:")
                for key in missing:
                    print(f"  - {key}")
            if extra:
                print("  Extra keys:")
                for key in extra:
                    print(f"  - {key}")

    if failed:
        return 1

    print(f"Localization key check passed: {len(reference_keys)} keys")
    return 0


if __name__ == "__main__":
    sys.exit(main())
