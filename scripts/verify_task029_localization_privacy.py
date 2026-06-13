#!/usr/bin/env python3
"""Task-029a localization / privacy copy gate.

This check keeps Japanese localization, InfoPlist permission copy, and the
pre-ADP deferred localization roadmap aligned without changing production
credentials, signing, document types, or cloud capabilities.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LOCALIZATION_ROOT = ROOT / "Shared" / "Localization"
PROJECT_FILE = ROOT / "SkateTrack.xcodeproj" / "project.pbxproj"
DEV_LOG = ROOT / "docs" / "history" / "DEV_LOG.md"
FILE_STRUCTURE = ROOT / "docs" / "reference" / "FILE_STRUCTURE.md"
DEVELOPMENT_RULES = ROOT / "docs" / "process" / "DEVELOPMENT_RULES.md"
KNOWN_LIMITATIONS = ROOT / "docs" / "release" / "KNOWN_LIMITATIONS_PRE_ADP.md"
RELEASE_READINESS = ROOT / "docs" / "release" / "RELEASE_READINESS_PRE_ADP.md"
ADR_INDEX = ROOT / "docs" / "adr" / "ADR-INDEX.md"
LANGUAGES = ("en", "zh-Hant", "ja")
STRING_ENTRY = re.compile(r'^\s*(?:"(?P<qkey>[^"]+)"|(?P<bkey>[A-Za-z0-9_]+))\s*=\s*"(?P<value>(?:\\.|[^"])*)"\s*;\s*$')

CRITICAL_KEYS = [
    "permission.location.whenInUse",
    "permission.location.always",
    "session.start.backgroundRecording.detail",
    "account.google.drive_deferred",
    "account.provider_boundary.note",
    "backup.drive.deferred_note",
    "backup.restore.deferred.note",
    "backup.restore.policy.note",
    "skatetrack.package.export.subtitle",
    "mac.import.hero.boundary",
    "mac.package.preview.privacy.boundary",
    "mac.viewer.privacy.readonly",
]
INFO_PLIST_KEYS = [
    "NSLocationWhenInUseUsageDescription",
    "NSLocationAlwaysAndWhenInUseUsageDescription",
    "NSMotionUsageDescription",
    "NSPhotoLibraryAddUsageDescription",
]
DEFERRED_ROADMAP_TERMS = ["ja", "pt-BR", "es", "native review"]
FORBIDDEN_PROJECT_TOKENS = [
    "UTExportedTypeDeclarations",
    "CFBundleDocumentTypes",
    "com.apple.developer.icloud",
    "com.apple.developer.associated-domains",
]


def parse(path: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for index, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        stripped = line.strip()
        if not stripped or stripped.startswith("//") or stripped.startswith("/*"):
            continue
        match = STRING_ENTRY.match(line)
        if not match:
            raise ValueError(f"Invalid strings syntax in {path.relative_to(ROOT)}:{index}: {line}")
        result[match.group("qkey") or match.group("bkey")] = match.group("value")
    return result


def fail(message: str) -> bool:
    print(message)
    return False


def check_japanese_files() -> bool:
    ja_localizable = LOCALIZATION_ROOT / "ja.lproj" / "Localizable.strings"
    ja_info = LOCALIZATION_ROOT / "ja.lproj" / "InfoPlist.strings"
    if not ja_localizable.exists() or not ja_info.exists():
        return fail("Japanese localization files are missing.")

    entries = parse(ja_localizable)
    missing_critical = [key for key in CRITICAL_KEYS if key not in entries or not entries[key].strip()]
    if missing_critical:
        print("Critical Japanese privacy/deferred keys are missing:")
        for key in missing_critical:
            print(f"- {key}")
        return False

    info = parse(ja_info)
    missing_info = [key for key in INFO_PLIST_KEYS if key not in info or not info[key].strip()]
    if missing_info:
        print("Critical Japanese InfoPlist permission keys are missing:")
        for key in missing_info:
            print(f"- {key}")
        return False

    return True


def check_docs() -> bool:
    docs = [DEV_LOG, FILE_STRUCTURE, DEVELOPMENT_RULES, KNOWN_LIMITATIONS, RELEASE_READINESS, ADR_INDEX]
    missing = [str(path.relative_to(ROOT)) for path in docs if not path.exists()]
    if missing:
        print("Missing consolidated localization documentation:")
        for path in missing:
            print(f"- {path}")
        return False

    combined = "\n".join(path.read_text(encoding="utf-8") for path in docs)
    missing_terms = [term for term in DEFERRED_ROADMAP_TERMS if term not in combined]
    if missing_terms:
        print("Deferred localization roadmap documentation is incomplete:")
        for term in missing_terms:
            print(f"- missing term: {term}")
        return False

    if "500" not in combined or "Localizable.strings" not in combined:
        return fail("Docs must state that localization resource files are not governed by the Swift 500-line guideline.")
    return True


def check_project() -> bool:
    project = PROJECT_FILE.read_text(encoding="utf-8")
    required = ["ja,", "ja.lproj/Localizable.strings", "ja.lproj/InfoPlist.strings"]
    missing = [token for token in required if token not in project]
    if missing:
        print("Project file does not include Japanese localization membership:")
        for token in missing:
            print(f"- {token}")
        return False

    forbidden = [token for token in FORBIDDEN_PROJECT_TOKENS if token in project]
    if forbidden:
        print("Unexpected production / document capability token found:")
        for token in forbidden:
            print(f"- {token}")
        return False
    return True


def main() -> int:
    checks = [check_japanese_files(), check_docs(), check_project()]
    if not all(checks):
        return 1
    print("Task-029a localization/privacy copy check passed: ja added, pt-BR/es deferred, privacy boundaries documented")
    return 0


if __name__ == "__main__":
    sys.exit(main())
