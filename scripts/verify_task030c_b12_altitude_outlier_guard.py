#!/usr/bin/env python3
"""Verify Task-030c-b12-B pressure smoothing diagnostics and altitude guard scope."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIRED = {
    "Shared/Models/SessionData.swift": [
        'static let currentDebugBuildTaskID = "Task-030c-b13-B"',
    ],
    "iOS/Features/Debug/DebugToolsPanelView.swift": [
        'Text("Task-030c-b13-B")',
        "debugBuildSignatureCard",
    ],
    "Shared/Models/MotionSample.swift": [
        "enum AltitudeTrustClassification",
        "case rejectedOutlier",
        "enum AltitudeTrustReason",
        "case hardAltitudeJump",
        "case verticalAccuracyTooPoor",
        "struct AltitudeDiagnostics",
        "let rawAltitudeMeters: Double?",
        "let trustedAltitudeMeters: Double?",
        "let updatesTrustedAltitudeAnchor: Bool",
        "struct AltitudeOutlierGuardConfig",
        "struct AltitudeOutlierGuard",
        "mutating func evaluate(",
        "let altitudeDiagnostics: AltitudeDiagnostics?",
        "altitudeDiagnostics: AltitudeDiagnostics? = nil",
        "enum AltitudeSampleSource: String, Codable, Sendable, Equatable, Hashable",
        "struct AltitudePressureDiagnostics",
        "struct AltitudePressureFilterConfig",
        "struct AltitudePressureFilter",
        "let pressureDiagnostics: AltitudePressureDiagnostics?",
        "spikeSuppressed: Bool",
        "maxRawPressureStepKilopascals",
    ],
    "iOS/Core/SensorEngine/SensorFusionEngine.swift": [
        "private var altitudeOutlierGuard = AltitudeOutlierGuard()",
        "private var pressureFilter = AltitudePressureFilter()",
        "private var latestPressureDiagnostics: AltitudePressureDiagnostics?",
        "barometerProvider.pressureKilopascalsPublisher",
        "private func updatePressure(_ pressureKilopascals: Double?)",
        "AltitudeOutlierGuardConfig(",
        "altitudeOutlierGuard.evaluate(",
        "pressureDiagnostics: pressureDiagnostics",
        "altitudeDiagnostics: snapshot.altitudeDiagnostics",
        "altitudeDiagnostics: altitudeDiagnostics",
        "altitudeOutlierGuard.reset()",
        "pressureFilter.reset()",
    ],
    "iOS/Core/SessionRecording/SessionMetricsAccumulator.swift": [
        "if let diagnostics = sample.altitudeDiagnostics",
        "accumulateTrustedElevation(from: diagnostics)",
        "diagnostics.isTrustedForElevationGain",
    ],
    "iOS/Core/Export/SkateTrackPackageExportProvider.swift": [
        "altitude-diagnostics-v1",
        "samples.contains(where: { $0.altitudeDiagnostics != nil })",
    ],
    "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift": [
        "trustedDiagnosticElevationGainMeters",
        "sample.altitudeDiagnostics",
        "diagnostics.reason.rawValue",
        "diagnostics.trustClassification",
    ],
    "iOS/Features/SessionSummary/SessionAdvancedChartsView.swift": [
        "sample.altitudeDiagnostics",
        "trustedAltitudeMeters",
        "isTrustedForElevationGain",
    ],
    "Tests/iOSTests/SessionRecordingCoordinatorTests.swift": [
        "testAltitudeOutlierGuardRejectsImplausibleJumpAndKeepsTrustedAnchorStable",
        "testAltitudeOutlierGuardClassifiesPoorVerticalAccuracyWithoutDroppingHorizontalSample",
        "testMetricsAccumulatorIgnoresRejectedAltitudeOutlierButPreservesDistance",
        "hardAltitudeJump",
        "verticalAccuracyTooPoor",
        "testAltitudePressureFilterSuppressesPressureSpike",
        "testAltitudeOutlierGuardCarriesPressureDiagnosticsWithoutChangingAltitude",
    ],
    "Tests/iOSTests/SessionRepositoryTests.swift": [
        "testLegacyMotionSampleDecodesWithoutB12AltitudeDiagnostics",
        "altitudeDiagnostics.count",
        "Expected persisted samples to retain b12 altitude diagnostics",
        "exportedSamplesJSON.contains(\"altitudeDiagnostics\")",
        "testAltitudeDiagnosticsPressureDiagnosticsCodableRoundTrip",
        "smoothedPressureKilopascals",
    ],
    "docs/history/DEV_LOG.md": [
        "Task-030c-b12-B — Pressure smoothing diagnostics foundation",
        "component-level altitude isolation",
        "source-isolated altitude anchors",
    ],
    "docs/reference/FILE_STRUCTURE.md": [
        "Task-030c-b12-B pressure smoothing diagnostics and altitude guard",
        "verify_task030c_b12_altitude_outlier_guard.py",
    ],
    "docs/adr/ADR-INDEX.md": [
        "Task-030c-b12-B — Pressure smoothing diagnostics foundation",
        "horizontal coordinates, distance logic, and route rendering remain isolated",
    ],
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
        "Task-030c-b12-B — Pressure smoothing diagnostics foundation",
        "does not guarantee survey-grade elevation precision",
        "Pressure LPF",
    ],
}

FORBIDDEN = {
    "Shared/Models/MotionSample.swift": [
        "estimatedRouteGeometry",
        "estimatedLatitude",
        "estimatedLongitude",
        "BarometricVerticalDiagnostics",
    ],
    "iOS/Core/SensorEngine/SensorFusionEngine.swift": [
        "startUpdatingHeading",
        "CLLocationManagerDelegate",
        "emitDeadReckonedSample",
        "DeadReckoningEngine()",
        "estimatedCoordinate",
        "visualLocalization",
        "cameraLocalization",
    ],
    "iOS/Core/SessionRecording/SessionMetricsAccumulator.swift": [
        "DeadReckoningEngine",
        "estimatedRouteGeometry",
    ],
}

FORBIDDEN_REPO_REFERENCES = [
    "SkateTrack-SnowPrototype",
    "prototype/snow-mode-ui-mock",
]


def read(rel: str) -> str:
    path = ROOT / rel
    if not path.exists():
        print(f"Missing required file: {rel}", file=sys.stderr)
        sys.exit(1)
    return path.read_text()


def main() -> int:
    failures = []
    for rel, tokens in REQUIRED.items():
        text = read(rel)
        for token in tokens:
            if token not in text:
                failures.append(f"{rel}: missing {token!r}")

    for rel, tokens in FORBIDDEN.items():
        text = read(rel)
        for token in tokens:
            if token in text:
                failures.append(f"{rel}: forbidden {token!r}")

    for rel in [
        "Shared/Models/MotionSample.swift",
        "iOS/Core/SensorEngine/SensorFusionEngine.swift",
        "iOS/Core/SessionRecording/SessionMetricsAccumulator.swift",
        "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift",
        "Tests/iOSTests/SessionRecordingCoordinatorTests.swift",
        "Tests/iOSTests/SessionRepositoryTests.swift",
    ]:
        text = read(rel)
        for token in FORBIDDEN_REPO_REFERENCES:
            if token in text:
                failures.append(f"{rel}: forbidden SnowPrototype reference {token!r}")

    if failures:
        print("Task-030c-b12-B pressure smoothing diagnostics check failed:", file=sys.stderr)
        for failure in failures:
            print(f"  {failure}", file=sys.stderr)
        return 1

    print("Task-030c-b12-B pressure smoothing diagnostics checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
