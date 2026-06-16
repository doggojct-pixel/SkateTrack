#!/usr/bin/env python3
"""Verify Snow-Task-003 v0 SnowSegmentClassifier foundation."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "Shared/Models/SnowClassifierConfig.swift",
    "Shared/Models/SnowSegmentClassification.swift",
    "Shared/Models/SnowSegmentClassifier.swift",
    "Tests/iOSTests/SnowSegmentClassifierTests.swift",
]

REQUIRED_SNIPPETS = {
    "Shared/Models/SnowClassifierConfig.swift": [
        "struct SnowClassifierConfig",
        "altitudeMovingAverageSampleCount: 30",
        "trendWindowSeconds: 5",
        "hysteresisSeconds: 5",
        "ascentWindowSeconds: 10",
        "stoppedWindowSeconds: 15",
        "downhillMinSpeedKmh: 10",
        "downhillVerticalRateThresholdMetersPerSecond: -0.25",
        "strongDownhillVerticalRateThresholdMetersPerSecond: -0.45",
        "ascentVerticalRateThresholdMetersPerSecond: 0.15",
        "flatVerticalRateAbsThresholdMetersPerSecond: 0.10",
        "gondolaMinSpeedKmh: 8",
        "gondolaMaxSpeedKmh: 30",
        "downhillMotionEnergyThresholdG: 0.08",
        "lowMotionEnergyThresholdG: 0.03",
        "downhillHeadingStandardDeviationThresholdDegrees: 12",
        "stableHeadingStandardDeviationThresholdDegrees: 5",
    ],
    "Shared/Models/SnowSegmentClassification.swift": [
        "struct SnowSegmentClassification",
        "let type: SnowSegmentType",
        "let confidence: Double",
        "let verticalRateMetersPerSecond: Double?",
        "let motionEnergyG: Double",
        "let headingStandardDeviationDegrees: Double?",
        "let reasonCodes: [String]",
    ],
    "Shared/Models/SnowSegmentClassifier.swift": [
        "struct SnowSegmentClassifier",
        "func classify(",
        "smoothedAltitudeSeries",
        "headingStandardDeviationDegrees",
        "ambiguousGondolaLikeDescent",
        "hysteresisHold",
        "missingAltitude",
        "type: .unknown",
    ],
    "Tests/iOSTests/SnowSegmentClassifierTests.swift": [
        "final class SnowSegmentClassifierTests",
        "SnowClassifierFixtureResult",
        "cleanDownhill",
        "liftAscent",
        "gondolaAscent",
        "surfaceLiftAscent",
        "stopped",
        "walking",
        "noisyAltitudeDownhill",
        "ambiguousGondolaLikeDescent",
        "missingAltitudeMoving",
    ],
    "SkateTrack.xcodeproj/project.pbxproj": [
        "SnowClassifierConfig.swift in Sources",
        "SnowSegmentClassification.swift in Sources",
        "SnowSegmentClassifier.swift in Sources",
        "SnowSegmentClassifierTests.swift in Sources",
    ],
}

UNMODIFIED_MODEL_FILES = [
    "Shared/Models/SnowSegment.swift",
    "Shared/Models/SnowRun.swift",
    "Shared/Models/SnowDistanceBreakdown.swift",
    "Shared/Models/SnowVerticalMetrics.swift",
    "Shared/Models/SnowSessionState.swift",
    "Shared/Models/MotionSample.swift",
]

FORBIDDEN_MODEL_TOKENS = {
    "Shared/Models/MotionSample.swift": [
        "horizontalAccuracy",
        "verticalAccuracy",
        "headingDegrees",
        "courseDegrees",
        "gpsAltitudeMeters",
    ],
}


def fail(message: str) -> None:
    print(f"[snow-task-003] FAIL: {message}", file=sys.stderr)
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


def verify_no_scope_creep() -> None:
    task_files = [
        ROOT / "Shared/Models/SnowClassifierConfig.swift",
        ROOT / "Shared/Models/SnowSegmentClassification.swift",
        ROOT / "Shared/Models/SnowSegmentClassifier.swift",
        ROOT / "Tests/iOSTests/SnowSegmentClassifierTests.swift",
    ]
    for path in ROOT.glob("**/*.swift"):
        rel = str(path.relative_to(ROOT))
        if "Shared/WatchBridge/" in rel:
            fail(f"Snow-Task-003 must not touch WatchBridge path: {rel}")
        text = path.read_text(encoding="utf-8")
        if "SnowPrototype" in text:
            fail(f"Snow-Task-003 must not introduce SnowPrototype namespace: {rel}")
    for path in task_files:
        text = path.read_text(encoding="utf-8")
        if "RunBoundaryDetector" in text:
            fail(f"Snow-Task-003 must not implement RunBoundaryDetector: {path.relative_to(ROOT)}")
    if list(ROOT.glob("**/*.skatetrack")):
        fail(".skatetrack sample package must not be included in Snow-Task-003")


def verify_existing_value_types_not_expanded() -> None:
    for rel_path in UNMODIFIED_MODEL_FILES:
        text = read(rel_path)
        if rel_path == "Shared/Models/SnowSegment.swift" and "struct SnowSegment" not in text:
            fail("SnowSegment value type missing")
        if rel_path == "Shared/Models/SnowRun.swift" and "struct SnowRun" not in text:
            fail("SnowRun value type missing")
        for token in FORBIDDEN_MODEL_TOKENS.get(rel_path, []):
            if token in text:
                fail(f"003b must not extend {rel_path}; found token: {token}")


def verify_missing_altitude_priority() -> None:
    text = read("Shared/Models/SnowSegmentClassifier.swift")
    missing_altitude_index = text.find("metrics.altitudeDeltaMeters == nil")
    flat_traverse_index = text.find("type: .flatTraverse")
    if missing_altitude_index == -1 or flat_traverse_index == -1:
        fail("unable to verify missing-altitude classifier priority")
    if missing_altitude_index > flat_traverse_index:
        fail("missing-altitude moving samples must be classified before flatTraverse fallback")


def verify_known_limitations() -> None:
    text = read("docs/release/KNOWN_LIMITATIONS_PRE_ADP.md")
    required = [
        "Snow-Task-003 v0 classifier",
        "horizontalAccuracy, verticalAccuracy, heading/course, GPS altitude, or barometer source metadata",
        "GPS altitude vs barometer cross-validation",
        "bearing is derived from consecutive GPS coordinates",
    ]
    for token in required:
        if token not in text:
            fail(f"missing Snow-Task-003 limitation note: {token}")


def main() -> None:
    verify_files_and_snippets()
    verify_no_scope_creep()
    verify_existing_value_types_not_expanded()
    verify_missing_altitude_priority()
    verify_known_limitations()
    print("[snow-task-003] PASS: v0 SnowSegmentClassifier, config, fixture tests, and known limitations are present without MotionSample/schema/WatchBridge scope creep.")


if __name__ == "__main__":
    main()
