#!/usr/bin/env python3
"""Verify Task-030c-a Core Location diagnostics package extension."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "Shared/Models/MotionSample.swift",
    "Shared/Models/SessionData.swift",
    "Shared/Models/SkateTrackPackageManifest.swift",
    "Shared/Models/SkateTrackPackagePayload.swift",
    "iOS/Core/SensorEngine/SensorFusionEngine.swift",
    "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift",
    "iOS/Core/Export/SkateTrackPackageExportProvider.swift",
    "scripts/verify_task030c_gps_diagnostics_package.py",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/adr/ADR-INDEX.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
]

MOTION_SAMPLE_TOKENS = [
    "enum LocationSpeedSource",
    "case coreLocation",
    "case coordinateDerived",
    "case debugSimulated",
    "case stale",
    "enum LocationFreshnessState",
    "struct LocationFixDiagnostics",
    "horizontalAccuracyMeters",
    "verticalAccuracyMeters",
    "speedAccuracyMetersPerSecond",
    "courseAccuracyDegrees",
    "rawLocationTimestamp",
    "rawLocationTimestampMillisecondsSince1970",
    "receivedAtTimestamp",
    "receivedAtTimestampMillisecondsSince1970",
    "gpsUpdateIntervalSeconds",
    "gpsSegmentDistanceMeters",
    "coordinateDerivedSpeedKmh",
    "routeSegmentConfidence",
    "struct RouteQualitySummary",
    "uniqueCoordinateCount",
    "lowConfidenceSegmentCount",
    "staleLocationSampleCount",
    "averageGPSUpdateIntervalSeconds",
    "maxMotionSampleIntervalSeconds",
    "longLocationUpdateGapCount",
    "longMotionSampleGapCount",
    "timestampMillisecondsSince1970",
    "locationDiagnostics",
]

SESSION_DATA_TOKENS = [
    "let routeQualitySummary: RouteQualitySummary?",
    "routeQualitySummary: RouteQualitySummary? = nil",
    "decodeIfPresent(RouteQualitySummary.self, forKey: .routeQualitySummary)",
]

PACKAGE_TOKENS = [
    "formatCapabilities",
    "location-diagnostics-v1",
    "route-quality-summary-v1",
    "navigation-continuity-diagnostics-v1",
    "let routeQualitySummary: RouteQualitySummary?",
    "RouteQualitySummary.make(from: motionSamples)",
]

FUSION_TOKENS = [
    "latestLocationDiagnostics",
    "latestRawLocation",
    "makeLocationDiagnostics",
    "horizontalAccuracyMeters",
    "speedAccuracyMetersPerSecond",
    "courseAccuracyDegrees(for: location)",
    "rawLocationTimestampMillisecondsSince1970",
    "receivedAtTimestamp: receivedAt",
    "receivedAtTimestampMillisecondsSince1970: receivedAt.millisecondsSince1970",
    "locationFreshnessState",
    "routeSegmentConfidence",
    "locationDiagnostics: snapshot.locationDiagnostics",
]

DOC_TOKENS = [
    "Task-030c-a",
    "Core Location diagnostics",
    "20260613-110119",
    "20260612-180037",
    "simulator / compatibility reference",
    "road snapping",
    "route-quality-summary-v1",
    "navigation-continuity-diagnostics-v1",
]

FORBIDDEN_SOURCE_TOKENS = [
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
    print(f"Task-030c-a GPS diagnostics check failed: {message}", file=sys.stderr)
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


def ensure_diagnostics_schema() -> None:
    require_tokens(read("Shared/Models/MotionSample.swift"), MOTION_SAMPLE_TOKENS, "MotionSample diagnostics")
    require_tokens(read("Shared/Models/SessionData.swift"), SESSION_DATA_TOKENS, "SessionData route quality")
    package_text = "\n".join(
        read(path)
        for path in [
            "Shared/Models/SkateTrackPackageManifest.swift",
            "Shared/Models/SkateTrackPackagePayload.swift",
            "iOS/Core/Export/SkateTrackPackageExportProvider.swift",
        ]
    )
    require_tokens(package_text, PACKAGE_TOKENS, "package diagnostics")


def ensure_runtime_bridge() -> None:
    fusion = read("iOS/Core/SensorEngine/SensorFusionEngine.swift")
    require_tokens(fusion, FUSION_TOKENS, "SensorFusionEngine diagnostics bridge")
    if len(fusion.splitlines()) > 920:
        fail("SensorFusionEngine.swift exceeds 920 lines after Task-030c b13-B heading diagnostics foundation")
    coordinator = read("iOS/Core/SessionRecording/SessionRecordingCoordinator.swift")
    if "RouteQualitySummary.make(from: session.motionSamples)" not in coordinator:
        fail("SessionRecordingCoordinator must enrich completed sessions with route quality summary")


def ensure_scope_boundaries() -> None:
    source_paths = [
        "Shared/Models/MotionSample.swift",
        "Shared/Models/SessionData.swift",
        "Shared/Models/SkateTrackPackageManifest.swift",
        "Shared/Models/SkateTrackPackagePayload.swift",
        "iOS/Core/SensorEngine/SensorFusionEngine.swift",
        "iOS/Core/SensorEngine/GPSProvider.swift",
        "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift",
        "iOS/Core/Export/SkateTrackPackageExportProvider.swift",
        "SkateTrack.xcodeproj/project.pbxproj",
    ]
    for path in source_paths:
        text = read(path)
        for token in FORBIDDEN_SOURCE_TOKENS:
            if token in text:
                fail(f"Task-030c-a must not add production service, map matching, signing, or high-accuracy policy token {token!r} in {path}")


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
    require_tokens(docs, DOC_TOKENS, "Task-030c docs")


def main() -> int:
    ensure_required_files()
    ensure_diagnostics_schema()
    ensure_runtime_bridge()
    ensure_scope_boundaries()
    ensure_docs()
    print("Task-030c-a GPS diagnostics package check passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
