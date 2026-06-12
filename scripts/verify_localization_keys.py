#!/usr/bin/env python3
"""Verify SkateTrack localization resources across supported languages.

Task-029a expands localization from English / Traditional Chinese to Japanese.
This verifier checks structure, key parity, placeholder parity, and basic
project membership so localization resource files can grow beyond normal Swift
file-length limits without losing safety.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LOCALIZATION_ROOT = ROOT / "Shared" / "Localization"
PROJECT_FILE = ROOT / "SkateTrack.xcodeproj" / "project.pbxproj"
LANGUAGES = ("en", "zh-Hant", "ja")
STRING_FILE_PATTERN = re.compile(r'^\s*(?:"(?P<qkey>[^"]+)"|(?P<bkey>[A-Za-z0-9_]+))\s*=\s*"(?P<value>(?:\\.|[^"])*)"\s*;\s*$')
PLACEHOLDER_PATTERN = re.compile(r'%(?!%)(?:\d+\$)?(?:[-+#0 ]*)?(?:\d+)?(?:\.\d+)?[a-zA-Z@]')


def parse_entries(path: Path) -> dict[str, str]:
    entries: dict[str, str] = {}
    for index, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        stripped = line.strip()
        if not stripped or stripped.startswith("/*") or stripped.startswith("//"):
            continue
        match = STRING_FILE_PATTERN.match(line)
        if not match:
            print(f"Invalid .strings line in {path.relative_to(ROOT)}:{index}: {line}")
            raise ValueError("invalid strings syntax")
        key = match.group("qkey") or match.group("bkey")
        if key in entries:
            print(f"Duplicate localization key in {path.relative_to(ROOT)}:{index}: {key}")
            raise ValueError("duplicate localization key")
        entries[key] = match.group("value")
    return entries


def placeholders(value: str) -> list[str]:
    return PLACEHOLDER_PATTERN.findall(value)


def check_file_group(filename: str) -> bool:
    files = {language: LOCALIZATION_ROOT / f"{language}.lproj" / filename for language in LANGUAGES}
    missing_files = [str(path.relative_to(ROOT)) for path in files.values() if not path.exists()]
    if missing_files:
        print(f"Missing {filename} files:")
        for path in missing_files:
            print(f"- {path}")
        return False

    try:
        entries = {language: parse_entries(path) for language, path in files.items()}
    except ValueError:
        return False

    reference_language = "en"
    reference_keys = set(entries[reference_language])
    failed = False

    for language, language_entries in entries.items():
        keys = set(language_entries)
        missing = sorted(reference_keys - keys)
        extra = sorted(keys - reference_keys)
        if missing or extra:
            failed = True
            print(f"Localization key mismatch for {filename} / {language}:")
            if missing:
                print("  Missing keys:")
                for key in missing:
                    print(f"  - {key}")
            if extra:
                print("  Extra keys:")
                for key in extra:
                    print(f"  - {key}")

    for key in sorted(reference_keys):
        reference_placeholders = placeholders(entries[reference_language][key])
        for language in LANGUAGES:
            language_placeholders = placeholders(entries[language][key])
            if language_placeholders != reference_placeholders:
                failed = True
                print(
                    f"Placeholder mismatch for {filename} / {language} / {key}: "
                    f"expected {reference_placeholders}, got {language_placeholders}"
                )

    if not failed:
        print(f"{filename} localization check passed: {len(reference_keys)} keys across {len(LANGUAGES)} languages")
    return not failed


def check_project_membership() -> bool:
    if not PROJECT_FILE.exists():
        print("Missing project file")
        return False

    project = PROJECT_FILE.read_text(encoding="utf-8")
    required_tokens = [
        "knownRegions = (",
        "ja,",
        "ja.lproj/Localizable.strings",
        "ja.lproj/InfoPlist.strings",
        "Localizable.strings in Resources",
        "InfoPlist.strings in Resources",
    ]
    missing = [token for token in required_tokens if token not in project]
    if missing:
        print("Project localization membership is incomplete:")
        for token in missing:
            print(f"- missing token: {token}")
        return False

    forbidden_tokens = ["UTExportedTypeDeclarations", "CFBundleDocumentTypes", "com.apple.developer.icloud"]
    forbidden = [token for token in forbidden_tokens if token in project]
    if forbidden:
        print("Unexpected document / cloud capability token found while checking localization:")
        for token in forbidden:
            print(f"- {token}")
        return False

    return True


def main() -> int:
    checks = [
        check_file_group("Localizable.strings"),
        check_file_group("InfoPlist.strings"),
        check_project_membership(),
    ]
    if not all(checks):
        return 1

    print("Localization key check passed for en, zh-Hant, and ja")
    return 0


if __name__ == "__main__":
    sys.exit(main())
