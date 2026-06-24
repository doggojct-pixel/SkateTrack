#!/usr/bin/env python3
"""Verify Task-030c-b11-r3-3 background runtime enablement and gap-recovery quality gates."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "iOS/App/Info.plist",
    "SkateTrack.xcodeproj/project.pbxproj",
    "Shared/Models/SessionData.swift",
    "Shared/Models/MotionSample.swift",
    "iOS/Core/SensorEngine/GPSProvider.swift",
    "iOS/Core/SensorEngine/SensorFusionEngine.swift",
    "iOS/Core/SessionRecording/SessionMetricsAccumulator.swift",
    "iOS/Features/Debug/DebugToolsPanelView.swift",
    "scripts/verify_task030c_background_runtime_quality_gate.py",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/adr/ADR-INDEX.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
]

REQUIRED_TOKENS = {
    "iOS/App/Info.plist": [
        "<key>UIBackgroundModes</key>",
        "<array>",
        "<string>location</string>",
        "NSLocationAlwaysAndWhenInUseUsageDescription",
        "NSLocationWhenInUseUsageDescription",
    ],
    "SkateTrack.xcodeproj/project.pbxproj": [
        "GENERATE_INFOPLIST_FILE = NO;",
        "INFOPLIST_FILE = iOS/App/Info.plist;",
        "INFOPLIST_KEY_UIBackgroundModes = location;",
    ],
    "Shared/Models/SessionData.swift": [
        "static let currentDebugBuildTaskID = \"Task-030c-b13-A-4\"",
        "RecordingDebugBundleInfoSnapshot",
        "let bundleInfo: RecordingDebugBundleInfoSnapshot?",
        "resolvedUIBackgroundModes",
        "hasLocationBackgroundMode",
    ],
    "Shared/Models/MotionSample.swift": [
        "func trustsRouteSegment(",
        "isTrustedRouteDistanceSegment",
        "totalGPSDistanceMeters += distance",
        "previousCoordinate = nil",
    ],
    "iOS/Core/SensorEngine/GPSProvider.swift": [
        "backgroundLocationModeDeclaration()",
        "backgroundModesRawValue()",
        "normalizedBackgroundModes(from rawValue:",
        "Bundle.main.object(forInfoDictionaryKey: \"UIBackgroundModes\")",
        "bundleInfo: Self.backgroundLocationModeDeclaration()",
        "backgroundLocationDeclarationMissingAtRuntime",
        "locationManager.allowsBackgroundLocationUpdates = shouldAllowBackgroundUpdates",
    ],
    "iOS/Core/SensorEngine/SensorFusionEngine.swift": [
        "trustsLocationForLiveRoute",
        "latestRawLocation = location",
        "if Self.trustsLocationForLiveRoute(diagnostics, policy: liveRoutePolicy)",
        "let trustedForLiveRoute = Self.trustsLocationForLiveRoute(",
        ": 0",
    ],
    "iOS/Core/SessionRecording/SessionMetricsAccumulator.swift": [
        "trustsSampleForSummaryMetrics",
        "trustsSampleForRouteDistance",
        "currentSpeedKilometersPerHour = trustedForSummary ? max(sample.speedKmh, 0) : 0",
        "lastCoordinate = nil",
    ],
    "iOS/Features/Debug/DebugToolsPanelView.swift": [
        "Task-030c-b13-A-4",
    ],
    "docs/history/DEV_LOG.md": [
        "Task-030c-b11-r3-3",
        "Effective Background Location Runtime + Gap Recovery Quality Gate",
        "UIBackgroundModes",
        "gap recovery",
    ],
    "docs/reference/FILE_STRUCTURE.md": [
        "Task-030c-b11-r3-3",
        "iOS/App/Info.plist",
        "background runtime",
    ],
    "docs/adr/ADR-INDEX.md": [
        "Task-030c-b11-r3-3",
        "UIBackgroundModes",
        "gap-recovery",
    ],
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
        "Task-030c-b11-r3-3",
        "background location runtime",
        "stale / low-accuracy",
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
    print(f"Task-030c-b11-r3-3 background runtime quality gate check failed: {message}", file=sys.stderr)
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

    project = read("SkateTrack.xcodeproj/project.pbxproj")
    if project.count("INFOPLIST_FILE = iOS/App/Info.plist;") != 2:
        fail("iOS Info.plist must be wired only to the two SkateTrack-iOS build configurations")

    provider = read("iOS/Core/SensorEngine/GPSProvider.swift")
    if provider.find("backgroundLocationModeDeclaration()") > provider.find("locationManager.allowsBackgroundLocationUpdates"):
        fail("GPSProvider must resolve the background declaration before enabling background updates")

    motion = read("Shared/Models/MotionSample.swift")
    if motion.find("isTrustedRouteDistanceSegment") > motion.find("totalGPSDistanceMeters += distance"):
        fail("RouteQualitySummary must check trusted distance before accumulating diagnostics distance")

    combined = "\n".join(
        read(path)
        for path in [
            "iOS/App/Info.plist",
            "Shared/Models/SessionData.swift",
            "Shared/Models/MotionSample.swift",
            "iOS/Core/SensorEngine/GPSProvider.swift",
            "iOS/Core/SensorEngine/SensorFusionEngine.swift",
            "iOS/Core/SessionRecording/SessionMetricsAccumulator.swift",
        ]
    )
    for token in FORBIDDEN_TOKENS:
        if token in combined:
            fail(f"unexpected production integration token found: {token}")

    print("Task-030c-b11-r3-3 background runtime quality gate checks passed.")


if __name__ == "__main__":
    main()
