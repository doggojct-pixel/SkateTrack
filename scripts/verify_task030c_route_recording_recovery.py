#!/usr/bin/env python3
"""Verify Task-030c-b3 route recording recovery safeguards."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift",
    "iOS/Core/SensorEngine/FallDetectionEngine.swift",
    "iOS/Core/SensorEngine/SensorFusionEngine.swift",
    "iOS/Core/SensorEngine/GPSProvider.swift",
    "iOS/Core/Export/SkateTrackPackageExportProvider.swift",
    "iOS/Features/SessionSummary/SessionAdvancedChartsView.swift",
    "iOS/Features/SessionSummary/SpeedTimelineChartView.swift",
    "iOS/Features/SessionSummary/ElevationProfileChartView.swift",
    "iOS/Features/SessionSummary/SessionRouteMapView.swift",
    "iOS/Features/SessionSummary/SessionSummaryView.swift",
    "scripts/verify_task030c_route_recording_recovery.py",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/adr/ADR-INDEX.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
]

COORDINATOR_TOKENS = [
    "sessionScopedFallEvents(",
    "reconciledSummaryMetrics(",
    "trustedRouteDistanceKilometers(from: samples, policy:",
    "ActivityFidelityPolicy(profile:",
    "fallDetectionMaximumSpeedKmh",
]

FALL_TOKENS = [
    "detectedFallEvents = []",
    "pendingFallEvent = nil",
    "latestCoordinate = nil",
]

SENSOR_TOKENS = [
    "ActivityFidelityPolicy.maximumGlobalPlausibleSpeedKmh",
    "if location.speed >= 0",
]

GPS_TOKENS = [
    "ActivityFidelityPolicy.maximumGlobalPlausibleSpeedKmh",
]

CHART_TOKENS = [
    "SessionSummaryChartSegment",
    "segmentID",
    "shouldStartNewChartSegment",
]

ROUTE_MAP_TOKENS = [
    "RouteMapSegment",
    "makeRouteSegments",
    "shouldStartNewRouteSegment",
]

SUMMARY_VIEW_TOKENS = [
    "safeAreaInset(edge: .bottom",
    "floatingCloseButton",
    "session-summary-floating-close",
]

PACKAGE_TOKENS = [
    "route-recording-recovery-v1",
    "activity-aware-fidelity-v1",
]

DOC_TOKENS = [
    "Task-030c-b3",
    "Navigation-grade Route Recording Recovery",
    "route-recording-recovery-v1",
    "gap-aware charts",
    "floating bottom return",
    "road snapping deferred",
]

FORBIDDEN_SOURCE_TOKENS = [
    "MKDirections",
    "MKRoute",
    "GoogleMaps",
    "AreaMark",
    "StoreKit",
    "CloudKit",
    "NSUbiquitousContainers",
]


def fail(message: str) -> None:
    print(f"Task-030c-b3 route recording recovery check failed: {message}", file=sys.stderr)
    sys.exit(1)


def read(path: str) -> str:
    file_path = ROOT / path
    if not file_path.exists():
        fail(f"missing required file: {path}")
    return file_path.read_text(encoding="utf-8")


def require_tokens(path: str, tokens: list[str], label: str) -> None:
    text = read(path)
    for token in tokens:
        if token not in text:
            fail(f"{label} missing token {token!r} in {path}")


def ensure_required_files() -> None:
    for path in REQUIRED_FILES:
        if not (ROOT / path).exists():
            fail(f"missing required file: {path}")


def ensure_source_contracts() -> None:
    require_tokens("iOS/Core/SessionRecording/SessionRecordingCoordinator.swift", COORDINATOR_TOKENS, "coordinator recovery")
    require_tokens("iOS/Core/SensorEngine/FallDetectionEngine.swift", FALL_TOKENS, "fall reset")
    require_tokens("iOS/Core/SensorEngine/SensorFusionEngine.swift", SENSOR_TOKENS, "sensor speed outlier gate")
    require_tokens("iOS/Core/SensorEngine/GPSProvider.swift", GPS_TOKENS, "gps speed outlier gate")
    require_tokens("iOS/Features/SessionSummary/SessionAdvancedChartsView.swift", CHART_TOKENS, "advanced chart segmentation")
    require_tokens("iOS/Features/SessionSummary/SpeedTimelineChartView.swift", ["SessionSummaryChartSegment", "series: .value"], "speed chart segmentation")
    require_tokens("iOS/Features/SessionSummary/ElevationProfileChartView.swift", ["SessionSummaryChartSegment", "series: .value"], "elevation chart segmentation")
    require_tokens("iOS/Features/SessionSummary/SessionRouteMapView.swift", ROUTE_MAP_TOKENS, "route map segmentation")
    require_tokens("iOS/Features/SessionSummary/SessionSummaryView.swift", SUMMARY_VIEW_TOKENS, "summary floating return")
    require_tokens("iOS/Core/Export/SkateTrackPackageExportProvider.swift", PACKAGE_TOKENS, "package capability")


def ensure_no_scope_creep() -> None:
    for path in REQUIRED_FILES:
        if not path.endswith(".swift"):
            continue
        text = read(path)
        for token in FORBIDDEN_SOURCE_TOKENS:
            if token in text:
                fail(f"unexpected scope token {token!r} in {path}")


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
    for token in DOC_TOKENS:
        if token not in docs:
            fail(f"docs missing token {token!r}")


def main() -> int:
    ensure_required_files()
    ensure_source_contracts()
    ensure_no_scope_creep()
    ensure_docs()
    print("Task-030c-b3 route recording recovery check passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
