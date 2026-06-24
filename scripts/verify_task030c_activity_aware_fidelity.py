#!/usr/bin/env python3
"""Verify Task-030c-b5 activity-aware speed, route, and altitude fidelity safeguards."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "Shared/Models/MotionSample.swift",
    "Shared/Models/SessionData.swift",
    "iOS/Core/SensorEngine/GPSProvider.swift",
    "iOS/Core/SensorEngine/SensorFusionEngine.swift",
    "iOS/Core/SessionRecording/SessionMetricsAccumulator.swift",
    "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift",
    "iOS/Core/SessionRecording/SessionRecordingCoordinator+DebugMock.swift",
    "iOS/Core/Export/SkateTrackPackageExportProvider.swift",
    "iOS/Features/SessionSummary/SessionAdvancedChartsView.swift",
    "scripts/verify_task030c_activity_aware_fidelity.py",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/adr/ADR-INDEX.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
]

MODEL_TOKENS = [
    "enum ActivityFidelityProfile",
    "case technicalSkateboard",
    "case electricSkateboard",
    "case inlineSpeed",
    "case snowReserved",
    "case vehicleValidation",
    "struct ActivityFidelityPolicy",
    "maximumGlobalPlausibleSpeedKmh = 180.0",
    "enum AltitudeSampleSource",
    "case coreLocationAbsolute",
    "case barometerRelative",
    "let altitudeSource: AltitudeSampleSource?",
]

SESSION_TOKENS = [
    "let fidelityProfile: ActivityFidelityProfile?",
    "fidelityProfile = try container.decodeIfPresent(ActivityFidelityProfile.self",
    "ActivityFidelityProfile.defaultProfile(for: decodedSportMode, powerType: decodedPowerType)",
]

SENSOR_TOKENS = [
    "ActivityFidelityPolicy.maximumGlobalPlausibleSpeedKmh",
    "altitudeSource: snapshot.altitude == nil ? nil : .barometerRelative",
    "altitudeSource: altitudeSource",
    "currentActivityFidelityProfile()",
    "policy.maximumTrustedSegmentDistanceMeters",
]

COORDINATOR_TOKENS = [
    "currentFidelityProfile(observedSamples:",
    "fallDetectionMaximumSpeedKmh",
    "trustedRouteDistanceKilometers(from: samples, policy:",
    "trustedElevationGainMeters(",
    "policy.maximumTrustedImpliedSpeedKmh",
    "fidelityProfile: currentFidelityProfile()",
]

ACCUMULATOR_TOKENS = [
    "ActivityFidelityPolicy.maximumGlobalPlausibleSpeedKmh",
    "case .coreLocationAbsolute:",
    "policy.maximumElevationStepMeters",
]

CHART_TOKENS = [
    "fidelityPolicy",
    "SessionSummaryDisplayMetrics.displaySpeedKilometersPerHour",
    "sample.altitudeSource == .coreLocationAbsolute",
    "fidelityPolicy.maximumVerticalAccuracyMeters",
]

PACKAGE_TOKENS = [
    "activity-aware-fidelity-v1",
    "altitude-source-stabilization-v1",
]

DOC_TOKENS = [
    "Task-030c-b5",
    "Activity-Aware Location, Speed & Altitude Fidelity",
    "activity-aware-fidelity-v1",
    "altitude-source-stabilization-v1",
    "Core ML optional",
    "road snapping deferred",
]

FORBIDDEN_TOKENS = [
    "MKDirections",
    "MKRoute",
    "GoogleMaps",
    "CloudKit",
    "NSUbiquitousContainers",
    "StoreKit",
]


def fail(message: str) -> None:
    print(f"Task-030c-b5 activity-aware fidelity check failed: {message}", file=sys.stderr)
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
    require_tokens("Shared/Models/MotionSample.swift", MODEL_TOKENS, "shared fidelity model")
    require_tokens("Shared/Models/SessionData.swift", SESSION_TOKENS, "session fidelity profile")
    require_tokens("iOS/Core/SensorEngine/SensorFusionEngine.swift", SENSOR_TOKENS, "sensor fusion fidelity policy")
    require_tokens("iOS/Core/SensorEngine/GPSProvider.swift", ["ActivityFidelityPolicy.maximumGlobalPlausibleSpeedKmh"], "gps provider broad speed range")
    require_tokens("iOS/Core/SessionRecording/SessionMetricsAccumulator.swift", ACCUMULATOR_TOKENS, "metrics altitude policy")
    require_tokens("iOS/Core/SessionRecording/SessionRecordingCoordinator.swift", COORDINATOR_TOKENS, "coordinator profile policy")
    require_tokens("iOS/Core/SessionRecording/SessionRecordingCoordinator+DebugMock.swift", ["altitudeSource: .debugSimulated"], "debug altitude source")
    require_tokens("iOS/Core/Export/SkateTrackPackageExportProvider.swift", PACKAGE_TOKENS, "package capabilities")
    require_tokens("iOS/Features/SessionSummary/SessionAdvancedChartsView.swift", CHART_TOKENS, "chart profile policy")


def ensure_no_scope_creep() -> None:
    for path in REQUIRED_FILES:
        if not path.endswith(".swift"):
            continue
        text = read(path)
        for token in FORBIDDEN_TOKENS:
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
    print("Task-030c-b5 activity-aware location, speed, and altitude fidelity check passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
