#!/usr/bin/env python3
"""Verify Task-030c-b high-accuracy outdoor recording and DEBUG simulated route mode."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "iOS/Core/SensorEngine/GPSProvider.swift",
    "iOS/Core/SensorEngine/SensorFusionEngine.swift",
    "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift",
    "iOS/Core/SessionRecording/SessionRecordingCoordinator+DebugMock.swift",
    "iOS/Core/Export/SkateTrackPackageExportProvider.swift",
    "Shared/Models/MotionSample.swift",
    "Shared/Localization/en.lproj/Localizable.strings",
    "Shared/Localization/zh-Hant.lproj/Localizable.strings",
    "Shared/Localization/ja.lproj/Localizable.strings",
    "scripts/verify_task030c_high_accuracy_debug_route.py",
    "scripts/verify_task030c_navigation_continuity.py",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/adr/ADR-INDEX.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
]

GPS_PROVIDER_TOKENS = [
    "kCLLocationAccuracyBestForNavigation",
    "return 1",
    "var activityType: CLActivityType",
    "return .fitness",
    "var pausesLocationUpdatesAutomatically: Bool",
    "case .activeRide:\n            return false",
]

SENSOR_FUSION_TOKENS = [
    "let routeTrackingChannels = plan.primary + plan.secondary + plan.supplemental",
    "routeTrackingChannels.contains(.gps) ? .activeRide : .stationaryPowerSaving",
]

DEBUG_ROUTE_TOKENS = [
    "#if DEBUG",
    "DebugOutdoorRouteSimulator",
    "sampleIntervalSeconds: TimeInterval = 0.5",
    "timer.schedule(deadline: .now(), repeating: .milliseconds",
    "simulatedSpeedKmh",
    "simulatedAltitudeMeters",
    "simulatedHorizontalAccuracyMeters",
    "speedSource: .debugSimulated",
    "routeSegmentConfidence: routeConfidence",
    "#else\nextension SessionRecordingCoordinator",
]

COORDINATOR_TOKENS = [
    "var mockSessionSamples: [MotionSample] = []",
    "var mockRouteSimulator = DebugOutdoorRouteSimulator()",
    "mockSessionSamples.append(sample)",
    "let samples = mockSessionSamples",
]

PACKAGE_TOKENS = [
    "debug-simulated-route-v1",
    "packageFormatCapabilities(for samples: [MotionSample])",
    "samples.contains(where: { $0.locationDiagnostics?.speedSource == .debugSimulated })",
]

LOCALIZATION_KEYS = [
    "debug.tools.demoSpeed.title",
    "debug.tools.demoSpeed.description",
    "debug.tools.demoSpeed.toggle",
    "debug.tools.demoSpeed.idleHint",
    "debug.tools.demoSpeed.activeHint",
]

DOC_TOKENS = [
    "Task-030c-b",
    "High-accuracy outdoor recording policy",
    "DEBUG simulated route",
    "debug-simulated-route-v1",
    "kCLLocationAccuracyBestForNavigation",
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
    print(f"Task-030c-b high-accuracy debug route check failed: {message}", file=sys.stderr)
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


def ensure_high_accuracy_policy() -> None:
    require_tokens(read("iOS/Core/SensorEngine/GPSProvider.swift"), GPS_PROVIDER_TOKENS, "GPSProvider high accuracy policy")
    require_tokens(read("iOS/Core/SensorEngine/SensorFusionEngine.swift"), SENSOR_FUSION_TOKENS, "SensorFusion route tracking policy")


def ensure_debug_route_mode() -> None:
    require_tokens(read("iOS/Core/SessionRecording/SessionRecordingCoordinator+DebugMock.swift"), DEBUG_ROUTE_TOKENS, "DEBUG simulated route")
    require_tokens(read("iOS/Core/SessionRecording/SessionRecordingCoordinator.swift"), COORDINATOR_TOKENS, "SessionRecordingCoordinator debug route storage")
    require_tokens(read("Shared/Models/MotionSample.swift"), ["case debugSimulated"], "MotionSample speed source")
    require_tokens(read("iOS/Core/Export/SkateTrackPackageExportProvider.swift"), PACKAGE_TOKENS, "package debug route capability")


def ensure_localization() -> None:
    for lang in ["en", "zh-Hant", "ja"]:
        text = read(f"Shared/Localization/{lang}.lproj/Localizable.strings")
        require_tokens(text, LOCALIZATION_KEYS, f"{lang} debug route localization")


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
    require_tokens(docs, DOC_TOKENS, "Task-030c-b docs")


def ensure_scope_boundaries() -> None:
    source_paths = [
        "iOS/Core/SensorEngine/GPSProvider.swift",
        "iOS/Core/SensorEngine/SensorFusionEngine.swift",
        "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift",
        "iOS/Core/SessionRecording/SessionRecordingCoordinator+DebugMock.swift",
        "iOS/Core/Export/SkateTrackPackageExportProvider.swift",
        "Shared/Models/MotionSample.swift",
        "SkateTrack.xcodeproj/project.pbxproj",
    ]
    for path in source_paths:
        text = read(path)
        for token in FORBIDDEN_TOKENS:
            if token in text:
                fail(f"Task-030c-b must not add production service, map matching, signing, or capability token {token!r} in {path}")


def main() -> int:
    ensure_required_files()
    ensure_high_accuracy_policy()
    ensure_debug_route_mode()
    ensure_localization()
    ensure_docs()
    ensure_scope_boundaries()
    print("Task-030c-b high-accuracy outdoor recording and DEBUG simulated route check passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
