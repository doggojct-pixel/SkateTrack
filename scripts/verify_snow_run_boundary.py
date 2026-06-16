#!/usr/bin/env python3
"""Verify Snow-Task-004 RunBoundaryDetector foundation."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "Shared/Models/RunBoundaryState.swift",
    "Shared/Models/RunBoundaryConfig.swift",
    "Shared/Models/RunBoundarySnapshot.swift",
    "Shared/Models/RunBoundaryEvent.swift",
    "Shared/Models/RunBoundaryDetector.swift",
    "Tests/iOSTests/RunBoundaryDetectorTests.swift",
]

REQUIRED_SNIPPETS = {
    "Shared/Models/RunBoundaryState.swift": [
        "enum RunBoundaryState",
        "case idle",
        "case active",
        "case pendingEnd",
        "case between",
    ],
    "Shared/Models/RunBoundaryConfig.swift": [
        "struct RunBoundaryConfig",
        "startConfirmationSeconds: 3",
        "pendingEndConfirmationSeconds: 8",
        "pendingEndTimeoutSeconds: 30",
        "hardTransportEndConfidenceThreshold: 0.78",
        "hardTransportConfirmationSeconds: 5",
    ],
    "Shared/Models/RunBoundarySnapshot.swift": [
        "struct RunBoundarySnapshot",
        "currentRunNumber",
        "currentSegmentType",
        "currentRunVerticalDropMeters",
        "pendingEndElapsedSeconds",
        "lastCompletedRun",
    ],
    "Shared/Models/RunBoundaryEvent.swift": [
        "enum RunBoundaryEndReason",
        "case highConfidenceTransport",
        "case pendingEndTimeout",
        "enum RunBoundaryEvent",
        "case runEnded",
    ],
    "Shared/Models/RunBoundaryDetector.swift": [
        "struct RunBoundaryDetector",
        "func ingest(_ classification: SnowSegmentClassification)",
        "finishAndTransitionToBetween(reason: .highConfidenceTransport",
        "hardTransportConfirmationSeconds",
        "RunBoundaryDetector",
    ],
    "Tests/iOSTests/RunBoundaryDetectorTests.swift": [
        "final class RunBoundaryDetectorTests",
        "RunBoundaryFixtureResult",
        "highConfidenceLiftTriggersFastPathRunEnd",
        "longStopEndsRun",
        "pendingEndCancelsWhenDownhillReturns",
        "segmentsKeepAltitudeEndpointsNil",
    ],
    "SkateTrack.xcodeproj/project.pbxproj": [
        "RunBoundaryState.swift in Sources",
        "RunBoundaryConfig.swift in Sources",
        "RunBoundarySnapshot.swift in Sources",
        "RunBoundaryEvent.swift in Sources",
        "RunBoundaryDetector.swift in Sources",
        "RunBoundaryDetectorTests.swift in Sources",
    ],
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
        "Snow-Task-004 v0 RunBoundaryDetector",
        "SnowSegment.startAltitudeMeters / endAltitudeMeters",
        "altitudeDeltaMeters accumulated estimate",
    ],
}

FORBIDDEN_PATH_PARTS = [
    "Shared/WatchBridge/",
]

FORBIDDEN_REPO_TOKENS = [
    "SnowPrototype",
]

UNMODIFIED_FILES = [
    "Shared/Models/MotionSample.swift",
    "Shared/Models/SnowSegmentClassifier.swift",
    "Shared/Models/SnowSegment.swift",
    "Shared/Models/SnowRun.swift",
    "Shared/Models/SnowDistanceBreakdown.swift",
    "Shared/Models/SnowVerticalMetrics.swift",
    "Shared/Models/SnowSessionState.swift",
]


def fail(message: str) -> None:
    print(f"[snow-task-004] FAIL: {message}", file=sys.stderr)
    sys.exit(1)


def read(rel_path: str) -> str:
    path = ROOT / rel_path
    if not path.exists():
        fail(f"missing required file: {rel_path}")
    return path.read_text(encoding="utf-8")


def verify_files_and_snippets() -> None:
    for rel_path in REQUIRED_FILES:
        read(rel_path)
    for rel_path, snippets in REQUIRED_SNIPPETS.items():
        text = read(rel_path)
        for snippet in snippets:
            if snippet not in text:
                fail(f"missing token in {rel_path}: {snippet}")


def verify_detector_boundaries() -> None:
    detector = read("Shared/Models/RunBoundaryDetector.swift")
    if "SnowSessionRepository" in detector:
        fail("RunBoundaryDetector must not call SnowSessionRepository directly")
    if "startAltitudeMeters: nil" not in detector or "endAltitudeMeters: nil" not in detector:
        fail("RunBoundaryDetector must leave SnowSegment altitude endpoints nil in v0")
    if "manualOverride: nil" not in detector:
        fail("RunBoundaryDetector must not set manualOverride in v0")
    if "classification.type.defaultCountsTowardSkiDistance" not in detector:
        fail("RunBoundaryDetector must use SnowSegmentType default distance counting")


def verify_no_scope_creep() -> None:
    for rel_path in REQUIRED_FILES:
        path = ROOT / rel_path
        if any(part in rel_path for part in FORBIDDEN_PATH_PARTS):
            fail(f"Snow-Task-004 must not touch WatchBridge path: {rel_path}")
        text = path.read_text(encoding="utf-8")
        if any(token in text for token in FORBIDDEN_REPO_TOKENS):
            fail(f"Snow-Task-004 must not introduce SnowPrototype namespace: {rel_path}")
    if list(ROOT.glob("**/*.skatetrack")):
        fail(".skatetrack sample package must not be included in Snow-Task-004")


def verify_existing_types_present() -> None:
    for rel_path in UNMODIFIED_FILES:
        text = read(rel_path)
        expected = Path(rel_path).stem
        if expected not in text:
            fail(f"expected existing type token missing in {rel_path}: {expected}")


def main() -> None:
    verify_files_and_snippets()
    verify_detector_boundaries()
    verify_no_scope_creep()
    verify_existing_types_present()
    print("[snow-task-004] PASS: RunBoundaryDetector state machine, fast-path transport ending, fixture tests, and v0 limitations are present without classifier/schema/WatchBridge scope creep.")


if __name__ == "__main__":
    main()
