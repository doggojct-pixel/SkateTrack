#!/usr/bin/env python3
"""Verify Task-030c-b11-r3-3 strict low-speed metrics and altitude source isolation."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "Shared/Models/SessionData.swift",
    "Shared/Models/MotionSample.swift",
    "iOS/Core/SensorEngine/SensorFusionEngine.swift",
    "iOS/Core/SessionRecording/SessionMetricsAccumulator.swift",
    "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift",
    "scripts/verify_task030c_strict_low_speed_altitude.py",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/adr/ADR-INDEX.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
]

REQUIRED_TOKENS = {
    "Shared/Models/SessionData.swift": [
        'static let currentDebugBuildTaskID = "Task-030c-b16-A"',
    ],
    "Shared/Models/MotionSample.swift": [
        "strictLowSpeedSuspicionThresholdKmh",
        "smallAreaSegmentThresholdMeters",
        "speedAccuracyMetersPerSecond > 1.2",
        "coordinateDerivedSpeedKmh >= strictLowSpeedSuspicionThresholdKmh",
        "segmentDistanceMeters > smallAreaSegmentThresholdMeters",
    ],
    "iOS/Core/SensorEngine/SensorFusionEngine.swift": [
        "lowSpeedSuspiciousCoreLocationSpeedKmh: Double = 6",
        "ActivityFidelityPolicy(profile: currentActivityFidelityProfile())",
        "ActivityFidelityProfile.defaultProfile(",
        "latestSpeedKmh = 0",
    ],
    "iOS/Core/SessionRecording/SessionMetricsAccumulator.swift": [
        "lastBarometerAltitudeMeters == nil",
        "delta > 0.03",
        "min(policy.maximumElevationStepMeters, 1.0)",
        "sample.timestamp.timeIntervalSince(sessionStartDate ?? sample.timestamp) > 30",
        "min(policy.maximumVerticalAccuracyMeters, 5)",
    ],
    "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift": [
        "let hasBarometerSamples",
        "if hasBarometerSamples { return barometerGain }",
        "trustedCoreLocationElevationGainMeters(",
        "delta > 0.03",
        "sample.timestamp.timeIntervalSince(firstTimestamp) > 30",
        "min(policy.maximumVerticalAccuracyMeters, 5)",
    ],
    "docs/history/DEV_LOG.md": [
        "Task-030c-b11-r3-3",
        "Strict Low-Speed Metrics + Altitude Source Isolation",
    ],
    "docs/reference/FILE_STRUCTURE.md": [
        "verify_task030c_strict_low_speed_altitude.py",
        "Task-030c-b11-r3-3",
    ],
    "docs/adr/ADR-INDEX.md": [
        "Task-030c-b11-r3-3",
        "altitude source isolation",
    ],
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
        "Task-030c-b11-r3-3",
        "strict low-speed metrics",
    ],
}

FORBIDDEN_TOKENS = [
    "MKDirections",
    "MKRoute",
    "road snapping",
    "map matching",
    "GoogleMaps",
    "GIDSignIn",
    "CloudKit",
    "StoreKit",
    "HealthKit",
]


def fail(message: str) -> None:
    print(f"Task-030c-b11-r3-3 strict low-speed/altitude check failed: {message}", file=sys.stderr)
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

    motion = read("Shared/Models/MotionSample.swift")
    if motion.find("strictLowSpeedSuspicionThresholdKmh") > motion.find("smallAreaSegmentThresholdMeters"):
        fail("strict low-speed thresholds must be declared before small-area checks")

    accumulator = read("iOS/Core/SessionRecording/SessionMetricsAccumulator.swift")
    if accumulator.find("lastBarometerAltitudeMeters == nil") < accumulator.find("case .coreLocationAbsolute:"):
        fail("Core Location altitude isolation must be implemented inside the Core Location altitude branch")

    coordinator = read("iOS/Core/SessionRecording/SessionRecordingCoordinator.swift")
    if coordinator.find("if hasBarometerSamples { return barometerGain }") > coordinator.find("trustedCoreLocationElevationGainMeters"):
        fail("barometer-relative elevation must be preferred before Core Location fallback")

    checked_source = "\n".join(
        read(path)
        for path in REQUIRED_FILES
        if path.startswith(("Shared/", "iOS/"))
    )
    for token in FORBIDDEN_TOKENS:
        if token in checked_source:
            fail(f"unexpected out-of-scope token found in source: {token}")

    print("Task-030c-b11-r3-3 strict low-speed/altitude checks passed.")


if __name__ == "__main__":
    main()
