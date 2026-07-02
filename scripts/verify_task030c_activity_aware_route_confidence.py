#!/usr/bin/env python3
"""Verify Task-030c-b11-r3-3 activity-aware route confidence and display gates."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIRED = {
    "Shared/Models/SessionData.swift": [
        'static let currentDebugBuildTaskID = "Task-030c-b15-B-3"',
    ],
    "Shared/Models/MotionSample.swift": [
        "usesStrictSmallAreaLowSpeedGate",
        "displayRouteMaximumHorizontalAccuracyMeters",
        "speedDisplayCorroborationAccuracyMeters",
        "case .electricSkateboard, .inlineSpeed, .snowReserved, .vehicleValidation:",
        "guard usesStrictSmallAreaLowSpeedGate else { return true }",
    ],
    "iOS/Core/SensorEngine/SensorFusionEngine.swift": [
        "currentPowerType",
        "currentFidelityProfileOverride",
        "func startRecording(",
        "powerType: PowerType = .humanPowered",
        "fidelityProfile: ActivityFidelityProfile? = nil",
        "routeConfidenceProfile(",
        "candidateSpeed > basePolicy.chartMaximumSpeedKmh + 20",
        "ActivityFidelityPolicy(profile: currentActivityFidelityProfile())",
    ],
    "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift": [
        "sensorEngine.startRecording(mode: mode, powerType: powerType, fidelityProfile: currentFidelityProfile())",
        "case .vehicleScreenOff, .scooterLockedPocket:",
        "return .vehicleValidation",
        "case .electricLongboardLockedPocket:",
        "return .electricSkateboard",
        "metricsAccumulator.beginSession(at: sessionStartDate ?? Date(), policy: ActivityFidelityPolicy(profile: currentFidelityProfile()))",
    ],
    "iOS/Core/SessionRecording/SessionMetricsAccumulator.swift": [
        "private var activePolicy = ActivityFidelityPolicy(profile: .standardSkateboard)",
        "policy: ActivityFidelityPolicy = ActivityFidelityPolicy(profile: .standardSkateboard)",
        "let policy = activePolicy",
    ],
    "iOS/Features/SessionSummary/SessionRouteMapView.swift": [
        "Task-030c-b11-r3-3",
        "let session: SessionData",
        "private var fidelityPolicy: ActivityFidelityPolicy",
        "fidelityPolicy.displayRouteMaximumHorizontalAccuracyMeters",
        "fidelityPolicy.maximumTrustedImpliedSpeedKmh",
    ],
    "iOS/Features/SessionSummary/SessionAdvancedChartsView.swift": [
        "SessionSummaryDisplayMetrics.displaySpeedKilometersPerHour",
        "low-confidence means uncertain, not missing",
    ],
    "iOS/Features/SessionSummary/SessionSummaryView.swift": [
        "SessionRouteMapView(session: content.session, samples: content.motionSamples)",
    ],
    "iOS/Features/Debug/DebugToolsPanelView.swift": [
        "Task-030c-b15-B-3",
    ],
}

FORBIDDEN = {
    "iOS/Core/SensorEngine/SensorFusionEngine.swift": [
        "let policy = ActivityFidelityPolicy(profile: .standardSkateboard)\n        return policy.trustsRouteSegment",
        "try await startSession(mode: mode)"
    ],
    "iOS/Features/SessionAdvancedChartsView.swift": [
        "if diagnostics.routeSegmentConfidence == .low { return true }"
    ],
    "iOS/Features/SessionSummary/SessionRouteMapView.swift": [
        "coordinateDerivedSpeedKmh.map({ $0 > 70 })",
        "horizontalAccuracyMeters.map({ $0 > 45 })"
    ],
}

def read(path: str) -> str:
    return (ROOT / path).read_text()

def main() -> int:
    failures = []
    for path, tokens in REQUIRED.items():
        text = read(path)
        for token in tokens:
            if token not in text:
                failures.append(f"{path}: missing {token!r}")
    for path, tokens in FORBIDDEN.items():
        full_path = ROOT / path
        if not full_path.exists():
            continue
        text = full_path.read_text()
        for token in tokens:
            if token in text:
                failures.append(f"{path}: forbidden {token!r}")
    if failures:
        print("Task-030c-b11-r3-3 activity-aware route confidence check failed:", file=sys.stderr)
        for failure in failures:
            print(f"  {failure}", file=sys.stderr)
        return 1
    print("Task-030c-b11-r3-3 activity-aware route confidence checks passed.")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
