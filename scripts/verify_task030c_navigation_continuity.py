#!/usr/bin/env python3
"""Verify Task-030c-b2 navigation-grade location continuity safeguards."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "SkateTrack.xcodeproj/project.pbxproj",
    "iOS/Core/SensorEngine/GPSProvider.swift",
    "iOS/Core/SensorEngine/SensorFusionEngine.swift",
    "iOS/Core/SessionRecording/SessionRecordingCoordinator+DebugMock.swift",
    "iOS/Core/Export/SkateTrackPackageExportProvider.swift",
    "Shared/Models/MotionSample.swift",
    "scripts/verify_task030c_navigation_continuity.py",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/adr/ADR-INDEX.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
]

PROJECT_TOKENS = [
    "INFOPLIST_KEY_UIBackgroundModes = location;",
    "INFOPLIST_KEY_NSLocationAlwaysAndWhenInUseUsageDescription",
    "INFOPLIST_KEY_NSLocationWhenInUseUsageDescription",
]

GPS_PROVIDER_TOKENS = [
    "kCLLocationAccuracyBestForNavigation",
    "wantsBackgroundLocationUpdates = accuracyMode == .activeRide",
    "wantsSignificantLocationChangeBackup = accuracyMode == .activeRide",
    "allowsBackgroundLocationUpdates = shouldAllowBackgroundUpdates",
    "showsBackgroundLocationIndicator = shouldAllowBackgroundUpdates",
    "requestAlwaysAuthorizationUpgradeIfNeeded()",
    "startMonitoringSignificantLocationChanges()",
    "stopMonitoringSignificantLocationChanges()",
    "maximumAcceptedHorizontalAccuracy: CLLocationAccuracy = 250",
    "Keep lower-confidence-but-valid fixes during screen-off pocket sessions.",
]

SENSOR_FUSION_TOKENS = [
    "publishRawLocationFixMotionSample(for: location, diagnostics: diagnostics)",
    "receivedAtTimestamp: receivedAt",
    "receivedAtTimestampMillisecondsSince1970: receivedAt.millisecondsSince1970",
]

MODEL_TOKENS = [
    "receivedAtTimestamp",
    "receivedAtTimestampMillisecondsSince1970",
    "maxMotionSampleIntervalSeconds",
    "longLocationUpdateGapCount",
    "longMotionSampleGapCount",
    "updateIntervals.filter { $0 > 10 }.count",
    "motionSampleIntervals.filter { $0 > 5 }.count",
]

PACKAGE_TOKENS = [
    "navigation-continuity-diagnostics-v1",
]

DOC_TOKENS = [
    "Task-030c-b2",
    "Navigation-grade Location Continuity",
    "screen-off pocket",
    "background location mode",
    "navigation-continuity-diagnostics-v1",
    "road snapping deferred",
]

FORBIDDEN_TOKENS = [
    "MKDirections",
    "MKRoute",
    "GoogleMaps",
    "GIDSignIn",
    "GoogleSignIn",
    "CloudKit",
    "NSUbiquitousContainers",
    "StoreKit",
    "UTExportedTypeDeclarations",
    "com.apple.developer",
]


def fail(message: str) -> None:
    print(f"Task-030c-b2 navigation continuity check failed: {message}", file=sys.stderr)
    sys.exit(1)


def read(path: str) -> str:
    file_path = ROOT / path
    if not file_path.exists():
        fail(f"missing required file: {path}")
    return file_path.read_text(encoding="utf-8")


def require_tokens(text: str, tokens: list[str], label: str) -> None:
    for token in tokens:
        if token not in text:
            fail(f"{label} missing token: {token}")


def ensure_required_files() -> None:
    for path in REQUIRED_FILES:
        if not (ROOT / path).exists():
            fail(f"missing required file: {path}")


def ensure_navigation_continuity() -> None:
    require_tokens(read("SkateTrack.xcodeproj/project.pbxproj"), PROJECT_TOKENS, "iOS generated Info.plist background location")
    require_tokens(read("iOS/Core/SensorEngine/GPSProvider.swift"), GPS_PROVIDER_TOKENS, "GPSProvider navigation continuity")
    require_tokens(read("iOS/Core/SensorEngine/SensorFusionEngine.swift"), SENSOR_FUSION_TOKENS, "SensorFusion location-driven samples")
    require_tokens(read("Shared/Models/MotionSample.swift"), MODEL_TOKENS, "route quality continuity diagnostics")
    require_tokens(read("iOS/Core/Export/SkateTrackPackageExportProvider.swift"), PACKAGE_TOKENS, "package continuity capability")


def ensure_docs() -> None:
    docs = "\n".join(
        read(path)
        for path in [
            "docs/history/DEV_LOG.md",
            "docs/reference/FILE_STRUCTURE.md",
            "docs/adr/ADR-INDEX.md",
            "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
        ]
    )
    require_tokens(docs, DOC_TOKENS, "Task-030c-b2 docs")


def ensure_scope_boundaries() -> None:
    source_paths = [
        "SkateTrack.xcodeproj/project.pbxproj",
        "iOS/Core/SensorEngine/GPSProvider.swift",
        "iOS/Core/SensorEngine/SensorFusionEngine.swift",
        "iOS/Core/Export/SkateTrackPackageExportProvider.swift",
        "Shared/Models/MotionSample.swift",
    ]
    for path in source_paths:
        text = read(path)
        for token in FORBIDDEN_TOKENS:
            if token in text:
                fail(f"Task-030c-b2 must not add production service, map matching, signing, or restricted capability token {token!r} in {path}")


def main() -> int:
    ensure_required_files()
    ensure_navigation_continuity()
    ensure_docs()
    ensure_scope_boundaries()
    print("Task-030c-b2 navigation-grade location continuity check passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
