#!/usr/bin/env python3
"""Verify Task-030c-b11-r3-3 strict low-speed metrics gate and UI responsiveness guards."""

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
    "iOS/Core/Export/SkateTrackPackageExportProvider.swift",
    "iOS/Hooks/useSkateTrackPackageExport.swift",
    "iOS/Hooks/useSessionSummary.swift",
    "iOS/Features/Debug/DebugToolsPanelView.swift",
    "scripts/verify_task030c_low_speed_metrics_ui.py",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/adr/ADR-INDEX.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
]

REQUIRED_TOKENS = {
    "Shared/Models/SessionData.swift": [
        'static let currentDebugBuildTaskID = "Task-030c-b13-B-1"',
    ],
    "Shared/Models/MotionSample.swift": [
        "acceptsLowSpeedMetricSample(",
        "strictLowSpeedSuspicionThresholdKmh",
        "lowSpeedSuspicionThresholdKmh",
        "localJumpImpliedSpeedThresholdKmh",
        "speedAccuracyMetersPerSecond > 1.2",
        "segmentDistanceMeters > localJumpSegmentThresholdMeters",
        "ActivityFidelityPolicy(profile: .standardSkateboard)",
    ],
    "iOS/Core/SensorEngine/SensorFusionEngine.swift": [
        "lowSpeedLocalJumpKmh",
        "lowSpeedSuspiciousCoreLocationSpeedKmh",
        "isLowSpeedLocalMetricOutlier(",
        "let isLowSpeedLocalJump = isLowSpeedLocalMetricOutlier(",
        "let confidence = (isStartupSpeedSpike || isLowSpeedLocalJump)",
        "latestLocationDiagnostics?.routeSegmentConfidence == .low",
    ],
    "iOS/Core/SessionRecording/SessionMetricsAccumulator.swift": [
        "lastBarometerAltitudeMeters",
        "lastCoreLocationAltitudeMeters",
        "acceptsLowSpeedMetricSample(",
        "diagnostics.routeSegmentConfidence != .low",
        "case .barometerRelative:",
        "strictVerticalAccuracy",
        "lastBarometerAltitudeMeters == nil",
        "sample.timestamp.timeIntervalSince(sessionStartDate ?? sample.timestamp) > 30",
    ],
    "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift": [
        "await Task.yield()",
        "isTrustedSummarySpeedSample(",
        "acceptsLowSpeedMetricSample(",
        "let distanceKilometers = routeDistanceKilometers > 0 ? routeDistanceKilometers : liveSummaryMetrics.distanceKilometers",
        "let hasBarometerSamples",
        "trustedBarometerElevationGainMeters(",
        "if hasBarometerSamples { return barometerGain }",
        "trustedCoreLocationElevationGainMeters(",
        "return hasAltitudeSamples ? 0",
    ],
    "iOS/Core/Export/SkateTrackPackageExportProvider.swift": [
        "SkateTrackPackageExportResult: Identifiable, Equatable, Sendable",
    ],
    "iOS/Hooks/useSkateTrackPackageExport.swift": [
        "Task.detached(priority: .userInitiated)",
        "SkateTrackPackageExportProvider().createExport(content: content)",
    ],
    "iOS/Hooks/useSessionSummary.swift": [
        "SessionSummaryContent: Equatable, Sendable",
    ],
    "iOS/Features/Debug/DebugToolsPanelView.swift": [
        "Task-030c-b13-B-1",
    ],
    "docs/history/DEV_LOG.md": [
        "Task-030c-b11-r3-3",
        "Low-Speed Metrics Gate + UI Responsiveness",
    ],
    "docs/reference/FILE_STRUCTURE.md": [
        "verify_task030c_low_speed_metrics_ui.py",
        "Task-030c-b11-r3-3",
    ],
    "docs/adr/ADR-INDEX.md": [
        "Task-030c-b11-r3-3",
        "low-speed metrics gate",
    ],
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
        "Task-030c-b11-r3-3",
        "low-speed metrics",
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
    print(f"Task-030c-b11-r3-3 low-speed metrics/UI check failed: {message}", file=sys.stderr)
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

    fusion = read("iOS/Core/SensorEngine/SensorFusionEngine.swift")
    if fusion.find("isLowSpeedLocalMetricOutlier(") > fusion.find("let confidence = (isStartupSpeedSpike || isLowSpeedLocalJump)"):
        fail("low-speed outlier check must run before route confidence is finalized")

    accumulator = read("iOS/Core/SessionRecording/SessionMetricsAccumulator.swift")
    if accumulator.find("diagnostics.routeSegmentConfidence != .low") > accumulator.find("acceptsLowSpeedMetricSample("):
        fail("summary metrics must reject low-confidence diagnostics before accepting low-speed samples")
    if accumulator.find("case .barometerRelative:") > accumulator.find("case .coreLocationAbsolute:"):
        fail("barometer-relative altitude should be preferred before Core Location absolute altitude")

    export_hook = read("iOS/Hooks/useSkateTrackPackageExport.swift")
    if export_hook.find("isExporting = true") > export_hook.find("Task.detached(priority: .userInitiated)"):
        fail("export UI must set loading state before detached package creation")

    checked_source = "\n".join(
        read(path)
        for path in REQUIRED_FILES
        if path.startswith(("Shared/", "iOS/"))
    )
    for token in FORBIDDEN_TOKENS:
        if token in checked_source:
            fail(f"unexpected out-of-scope token found in source: {token}")

    print("Task-030c-b11-r3-3 low-speed metrics/UI checks passed.")


if __name__ == "__main__":
    main()
