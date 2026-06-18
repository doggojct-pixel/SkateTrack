#!/usr/bin/env python3
"""Verify Task-030c-b8/b10 DEBUG recording context label polish."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "Shared/Models/SessionData.swift",
    "iOS/Features/Debug/DebugToolsPanelView.swift",
    "Shared/Localization/en.lproj/Localizable.strings",
    "Shared/Localization/zh-Hant.lproj/Localizable.strings",
    "Shared/Localization/ja.lproj/Localizable.strings",
    "scripts/verify_task030c_debug_recording_context_labels.py",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/adr/ADR-INDEX.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
]

REQUIRED_TOKENS = {
    "Shared/Models/SessionData.swift": [
        "case electricLongboardLockedPocket",
        "case scooterLockedPocket",
        "Task-030c-b11-r3-3",
    ],
    "iOS/Features/Debug/DebugToolsPanelView.swift": [
        "descriptionLocalizationKey",
        "debug-recording-context-description",
        "debug.recordingContext.electricLongboardLockedPocket",
        "debug.recordingContext.scooterLockedPocket",
        "Task-030c-b11-r3-3",
    ],
    "Shared/Localization/zh-Hant.lproj/Localizable.strings": [
        "電動長版・鎖螢幕口袋",
        "機車・鎖螢幕口袋",
        "車內・手動鎖螢幕",
        "debug.recordingContext.electricLongboardLockedPocket.description",
        "debug.recordingContext.scooterLockedPocket.description",
    ],
    "Shared/Localization/en.lproj/Localizable.strings": [
        "E-longboard · locked pocket",
        "Scooter · locked pocket",
        "Vehicle · manual lock",
    ],
    "Shared/Localization/ja.lproj/Localizable.strings": [
        "電動ロングボード・ロック中ポケット",
        "スクーター・ロック中ポケット",
        "車内・手動ロック",
    ],
    "docs/history/DEV_LOG.md": [
        "Task-030c-b11-r3-3",
        "Debug Recording Context Labels",
    ],
    "docs/reference/FILE_STRUCTURE.md": [
        "Task-030c-b11-r3-3",
        "debug recording context labels",
    ],
    "docs/adr/ADR-INDEX.md": [
        "Task-030c-b11-r3-3",
        "DEBUG recording context labels",
    ],
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
        "Task-030c-b11-r3-3",
        "DEBUG-only",
    ],
}

FORBIDDEN_TOKENS = [
    "MKDirections",
    "MKRoute",
    "GoogleMaps",
    "GIDSignIn",
    "CloudKit",
    "NSUbiquitousContainers",
    "StoreKit",
    "HealthKit",
]


def fail(message: str) -> None:
    print(f"Task-030c-b8/b10 debug recording context labels check failed: {message}", file=sys.stderr)
    sys.exit(1)


def read(path: str) -> str:
    file_path = ROOT / path
    if not file_path.exists():
        fail(f"missing required file: {path}")
    return file_path.read_text(encoding="utf-8")


def main() -> None:
    for path in REQUIRED_FILES:
        read(path)
    for path, tokens in REQUIRED_TOKENS.items():
        text = read(path)
        for token in tokens:
            if token not in text:
                fail(f"missing token {token!r} in {path}")
    combined = "\n".join(read(path) for path in ["Shared/Models/SessionData.swift", "iOS/Features/Debug/DebugToolsPanelView.swift"] )
    for token in FORBIDDEN_TOKENS:
        if token in combined:
            fail(f"forbidden production integration token found: {token}")
    print("Task-030c-b8/b10 debug recording context labels checks passed.")


if __name__ == "__main__":
    main()
