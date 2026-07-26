#!/usr/bin/env python3
"""Verify Task-003 shared model and protocol scaffolding."""
from __future__ import annotations

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
A005_BASE_COMMIT = "f48373c6610f35b865ea337953f68e544894f9a5"
REVIEWED_A011_COMMIT = "ea1f36514660191eb9f249cdb54b475c371066ed"
IMMUTABLE_BASELINE_SOURCE = "IMMUTABLE_GIT_OBJECTS"


def fail(message: str) -> None:
    print(f"Shared model check failed: {message}", file=sys.stderr)
    sys.exit(1)


def git_blob(commit: str, rel_path: str) -> bytes | None:
    result = subprocess.run(
        ["git", "-C", str(ROOT), "cat-file", "blob", f"{commit}:{rel_path}"],
        check=False,
        capture_output=True,
    )
    return result.stdout if result.returncode == 0 else None


def motion_sample_immutable_baseline_failures(
    evidence: dict[str, object],
) -> list[str]:
    issues: list[str] = []
    if evidence.get("source") != IMMUTABLE_BASELINE_SOURCE:
        issues.append("MotionSample A005 baseline source is not immutable")
    if evidence.get("base_commit") != A005_BASE_COMMIT:
        issues.append("MotionSample A005 baseline commit differs")
    if evidence.get("reviewed_commit") != REVIEWED_A011_COMMIT:
        issues.append("MotionSample reviewed-final commit differs")

    base_blob = evidence.get("base_blob")
    reviewed_blob = evidence.get("reviewed_blob")
    current_blob = evidence.get("current_blob")
    if not isinstance(base_blob, bytes):
        issues.append("MotionSample A005 baseline object is missing")
    if not isinstance(reviewed_blob, bytes):
        issues.append("MotionSample reviewed-final object is missing")
    if not isinstance(current_blob, bytes):
        issues.append("MotionSample current file is unreadable")
    if not all(isinstance(blob, bytes) for blob in (
        base_blob, reviewed_blob, current_blob
    )):
        return issues

    base_count = len(base_blob.splitlines())
    reviewed_count = len(reviewed_blob.splitlines())
    if current_blob != reviewed_blob:
        issues.append("current MotionSample differs from reviewed A011 final")
    if base_count <= MAX_LINES:
        issues.append("MotionSample A005 immutable baseline was not oversized")
    if reviewed_count - base_count != A005_OVERSIZED_BASELINES[
        "Shared/Models/MotionSample.swift"
    ]:
        issues.append("MotionSample A005-to-A011 growth is not two lines")
    return issues


def verify_a005_oversized_baseline(rel_path: str, current_blob: bytes) -> None:
    expected_growth = A005_OVERSIZED_BASELINES.get(rel_path)
    if not A005_INTEGRATION_MODE or expected_growth is None:
        fail(f"file exceeds {MAX_LINES} lines: {rel_path}")

    evidence: dict[str, object] = {
        "source": IMMUTABLE_BASELINE_SOURCE,
        "base_commit": A005_BASE_COMMIT,
        "reviewed_commit": REVIEWED_A011_COMMIT,
        "base_blob": git_blob(A005_BASE_COMMIT, rel_path),
        "reviewed_blob": git_blob(REVIEWED_A011_COMMIT, rel_path),
        "current_blob": current_blob,
    }
    issues = motion_sample_immutable_baseline_failures(evidence)
    if issues:
        fail("; ".join(issues))

    base_blob = evidence["base_blob"]
    reviewed_blob = evidence["reviewed_blob"]
    assert isinstance(base_blob, bytes)
    assert isinstance(reviewed_blob, bytes)
    print(f"MOTIONSAMPLE_A005_BASELINE_COMMIT={A005_BASE_COMMIT}")
    print(f"MOTIONSAMPLE_REVIEWED_FINAL_COMMIT={REVIEWED_A011_COMMIT}")
    print("MOTIONSAMPLE_CURRENT_EQUALS_REVIEWED_FINAL=YES")
    print(
        "MOTIONSAMPLE_A005_TO_REVIEWED_FINAL_GROWTH="
        f"{len(reviewed_blob.splitlines()) - len(base_blob.splitlines())}"
    )
    print("SYMBOLIC_CURRENT_HEAD_HISTORICAL_BASELINE_COUNT=0")


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
            verify_a005_oversized_baseline(rel_path, file_path.read_bytes())

        if UI_IMPORT_PATTERN.search(text):
            fail(f"UI framework import found: {file_path.relative_to(ROOT)}")

    model_text = "\n".join(path.read_text(encoding="utf-8") for path in REQUIRED_FILES)
    for token in ["Codable", "Sendable", "Identifiable", "UUID", "SnowDiscipline", "SnowSegmentType", "SnowRun", "SnowDistanceBreakdown", "SnowClassifierConfig", "SnowSegmentClassifier", "RunBoundaryDetector", "RunBoundaryState", "isValid(for sportMode: SportMode)"]:
        if token not in model_text:
            fail(f"expected token not found: {token}")

    print(f"Shared model check passed: {len(REQUIRED_FILES)} files")


if __name__ == "__main__":
    main()
