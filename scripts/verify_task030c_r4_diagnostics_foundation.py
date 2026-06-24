#!/usr/bin/env python3
"""Verify Task-030c-b11-r4-1 heading / GPS gap / dead-reckoning diagnostics foundation."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIRED = {
    "Shared/Models/SessionData.swift": [
        'static let currentDebugBuildTaskID = "Task-030c-b13-A-4"',
    ],
    "iOS/Features/Debug/DebugToolsPanelView.swift": [
        "Task-030c-b13-A-4",
        "debugBuildSignatureCard",
    ],
    "Shared/Models/MotionSample.swift": [
        "struct HeadingDiagnostics",
        "enum HeadingDiagnosticsSource",
        "case coreLocationCourse",
        "struct GPSGapDiagnostics",
        "enum GPSGapClassification",
        "case normalCadence",
        "case shortGap",
        "case backgroundLocationGap",
        "case extendedSignalLoss",
        "struct DeadReckoningDiagnostics",
        "enum DeadReckoningReadinessReason",
        "case r4RouteReconstructionDeferred",
        "let headingDiagnostics: HeadingDiagnostics?",
        "let gpsGapDiagnostics: GPSGapDiagnostics?",
        "let deadReckoningDiagnostics: DeadReckoningDiagnostics?",
        "func replacingR4Diagnostics",
        "static func classification(for gapSeconds: TimeInterval?)",
    ],
    "iOS/Core/SensorEngine/SensorFusionEngine.swift": [
        "timerFusionDiagnostics(from: diagnostics, latestRawLocation: latestRawLocation, now: now)",
        "headingDiagnostics(for: location, coreLocationSpeedKmh: coreLocationSpeedKmh)",
        "gpsGapDiagnostics(gapSeconds: updateInterval, isTimerFusionRepeat: false)",
        "deadReckoningDiagnostics(",
        "courseReliableForRouteContinuity",
        "deviceHeadingDeferred: true",
        "estimatedRouteActive: false",
        "r4RouteReconstructionDeferred",
    ],
    "Tests/iOSTests/SessionRepositoryTests.swift": [
        "testR4GPSGapClassificationThresholds",
        "testLegacyLocationFixDiagnosticsDecodesWithoutR4Fields",
        "XCTAssertNil(decoded.headingDiagnostics)",
        "XCTAssertNil(decoded.gpsGapDiagnostics)",
        "XCTAssertNil(decoded.deadReckoningDiagnostics)",
    ],
    "docs/history/DEV_LOG.md": [
        "Task-030c-b11-r4-1 — Heading Availability + GPS Gap Diagnostics + Dead Reckoning Readiness",
        "does not reconstruct route geometry",
        "legacy plaintext `.skatetrack` compatibility",
    ],
    "docs/adr/ADR-INDEX.md": [
        "Task-030c-b11-r4-1",
        "diagnostics-only foundation",
        "GPS gap diagnostics",
    ],
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
        "Task-030c-b11-r4-1",
        "does not make GPS 1m-accurate",
        "IMU-aided route interpolation remains deferred",
    ],
    "docs/reference/FILE_STRUCTURE.md": [
        "verify_task030c_r4_diagnostics_foundation.py",
        "HeadingDiagnostics",
        "GPSGapDiagnostics",
        "DeadReckoningDiagnostics",
    ],
}

FORBIDDEN = {
    "Shared/Models/MotionSample.swift": [
        "case none",
        "estimatedVelocityMps",
        "estimatedHeadingDegrees",
        "DeadReckoningScaffolding",
    ],
    "iOS/Core/SensorEngine/SensorFusionEngine.swift": [
        "startUpdatingHeading",
        "CLLocationManagerDelegate",
        "estimatedVelocityMps",
        "estimatedHeadingDegrees",
    ],
}


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
    if failures:
        print("Task-030c-b11-r4-1 diagnostics foundation check failed:", file=sys.stderr)
        for failure in failures:
            print(f"  {failure}", file=sys.stderr)
        return 1
    print("Task-030c-b11-r4-1 diagnostics foundation checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
