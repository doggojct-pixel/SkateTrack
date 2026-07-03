#!/usr/bin/env python3
"""Verify Task-003 shared model and protocol scaffolding."""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
REQUIRED_FILES = [
    ROOT / "Shared/Models/SessionData.swift",
    ROOT / "Shared/Models/SportMode.swift",
    ROOT / "Shared/Models/PowerType.swift",
    ROOT / "Shared/Models/MotionSample.swift",
    ROOT / "Shared/Models/TrickEvent.swift",
    ROOT / "Shared/Models/FallEvent.swift",
    ROOT / "Shared/Models/EquipmentProfile.swift",
    ROOT / "Shared/Models/SpotProfile.swift",
    ROOT / "Shared/Protocols/SensorProvider.swift",
    ROOT / "Shared/Protocols/SyncProvider.swift",
]
UI_IMPORT_PATTERN = re.compile(r"^\s*import\s+(SwiftUI|UIKit|AppKit|WatchKit)\b", re.MULTILINE)
ZONE_HEADER_PREFIX = "// [協作區]"
MAX_LINES = 650


def fail(message: str) -> None:
    print(f"Shared model check failed: {message}", file=sys.stderr)
    sys.exit(1)


def main() -> None:
    for file_path in REQUIRED_FILES:
        if not file_path.exists():
            fail(f"missing required file: {file_path.relative_to(ROOT)}")

        text = file_path.read_text(encoding="utf-8")
        lines = text.splitlines()

        if not lines or not lines[0].startswith(ZONE_HEADER_PREFIX):
            fail(f"missing collaboration zone header on line 1: {file_path.relative_to(ROOT)}")

        if len(lines) > MAX_LINES:
            fail(f"file exceeds {MAX_LINES} lines: {file_path.relative_to(ROOT)}")

        if UI_IMPORT_PATTERN.search(text):
            fail(f"UI framework import found: {file_path.relative_to(ROOT)}")

    model_text = "\n".join(path.read_text(encoding="utf-8") for path in REQUIRED_FILES)
    for token in ["Codable", "Sendable", "Identifiable", "UUID", "isValid(for sportMode: SportMode)"]:
        if token not in model_text:
            fail(f"expected token not found: {token}")

    print(f"Shared model check passed: {len(REQUIRED_FILES)} files")


if __name__ == "__main__":
    main()
