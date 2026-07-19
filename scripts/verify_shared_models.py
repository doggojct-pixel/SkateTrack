#!/usr/bin/env python3
"""Verify Task-003 shared model and protocol scaffolding."""

from pathlib import Path
import os
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
REQUIRED_FILES = [
    ROOT / "Shared/Models/SessionData.swift",
    ROOT / "Shared/Models/SportMode.swift",
    ROOT / "Shared/Models/SnowDiscipline.swift",
    ROOT / "Shared/Models/SnowSegmentType.swift",
    ROOT / "Shared/Models/SnowSegment.swift",
    ROOT / "Shared/Models/SnowRun.swift",
    ROOT / "Shared/Models/SnowDistanceBreakdown.swift",
    ROOT / "Shared/Models/SnowVerticalMetrics.swift",
    ROOT / "Shared/Models/SnowSessionState.swift",
    ROOT / "Shared/Models/SnowClassifierConfig.swift",
    ROOT / "Shared/Models/SnowSegmentClassification.swift",
    ROOT / "Shared/Models/SnowSegmentClassifier.swift",
    ROOT / "Shared/Models/RunBoundaryState.swift",
    ROOT / "Shared/Models/RunBoundaryConfig.swift",
    ROOT / "Shared/Models/RunBoundarySnapshot.swift",
    ROOT / "Shared/Models/RunBoundaryEvent.swift",
    ROOT / "Shared/Models/RunBoundaryDetector.swift",
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
A005_INTEGRATION_MODE = os.environ.get("SNOW_INTEGRATION_A005") == "1"
A005_OVERSIZED_BASELINES = {
    "Shared/Models/MotionSample.swift": 2,
}


def fail(message: str) -> None:
    print(f"Shared model check failed: {message}", file=sys.stderr)
    sys.exit(1)


def verify_a005_oversized_baseline(rel_path: str, final_line_count: int) -> None:
    expected_growth = A005_OVERSIZED_BASELINES.get(rel_path)
    if not A005_INTEGRATION_MODE or expected_growth is None:
        fail(f"file exceeds {MAX_LINES} lines: {rel_path}")

    result = subprocess.run(
        ["git", "-C", str(ROOT), "show", f"HEAD:{rel_path}"],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        fail(f"unable to read HEAD baseline for oversized file: {rel_path}")
    head_line_count = len(result.stdout.splitlines())
    if head_line_count <= MAX_LINES:
        fail(f"A005 oversized baseline was not already oversized in HEAD: {rel_path}")
    if final_line_count - head_line_count != expected_growth:
        fail(
            f"unexpected A005 line growth for {rel_path}: "
            f"HEAD={head_line_count}, final={final_line_count}, expected_growth={expected_growth}"
        )


def main() -> None:
    for file_path in REQUIRED_FILES:
        if not file_path.exists():
            fail(f"missing required file: {file_path.relative_to(ROOT)}")

        text = file_path.read_text(encoding="utf-8")
        lines = text.splitlines()

        if not lines or not lines[0].startswith(ZONE_HEADER_PREFIX):
            fail(f"missing collaboration zone header on line 1: {file_path.relative_to(ROOT)}")

        rel_path = str(file_path.relative_to(ROOT))
        if len(lines) > MAX_LINES:
            verify_a005_oversized_baseline(rel_path, len(lines))

        if UI_IMPORT_PATTERN.search(text):
            fail(f"UI framework import found: {file_path.relative_to(ROOT)}")

    model_text = "\n".join(path.read_text(encoding="utf-8") for path in REQUIRED_FILES)
    for token in ["Codable", "Sendable", "Identifiable", "UUID", "SnowDiscipline", "SnowSegmentType", "SnowRun", "SnowDistanceBreakdown", "SnowClassifierConfig", "SnowSegmentClassifier", "RunBoundaryDetector", "RunBoundaryState", "isValid(for sportMode: SportMode)"]:
        if token not in model_text:
            fail(f"expected token not found: {token}")

    print(f"Shared model check passed: {len(REQUIRED_FILES)} files")


if __name__ == "__main__":
    main()
