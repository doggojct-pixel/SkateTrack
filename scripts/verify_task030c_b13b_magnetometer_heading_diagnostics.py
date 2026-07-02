#!/usr/bin/env python3
"""Verify Task-030c-b13-B-1 magnetometer heading diagnostics foundation."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIRED = {
    "Shared/Models/SessionData.swift": [
        'static let currentDebugBuildTaskID = "Task-030c-b16-C"',
    ],
    "iOS/Features/Debug/DebugToolsPanelView.swift": [
        'Text("Task-030c-b16-C")',
        "debugBuildSignatureCard",
    ],
    "Shared/Models/MotionSample.swift": [
        "enum HeadingDiagnosticsSource",
        "case deviceMagnetometer",
        "case courseAndDeviceMagnetometer",
        "let deviceHeadingDegrees: Double?",
        "let deviceHeadingAccuracyDegrees: Double?",
        "let deviceHeadingTimestamp: Date?",
        "let deviceHeadingTimestampMillisecondsSince1970: Int64?",
        "let deviceHeadingAgeSeconds: TimeInterval?",
        "let deviceHeadingReliableForRouteContinuity: Bool",
        "let courseDeviceHeadingDeltaDegrees: Double?",
        "let courseDeviceHeadingAgreement: Bool?",
        "var hasReliableHeadingForRouteContinuity: Bool",
        "init(from decoder: Decoder) throws",
        "deviceHeadingReliableForRouteContinuity: try container.decodeIfPresent(Bool.self",
    ],
    "iOS/Core/SensorEngine/GPSProvider.swift": [
        "private let headingSubject = CurrentValueSubject<CLHeading?, Never>(nil)",
        "var headingPublisher: AnyPublisher<CLHeading?, Never>",
        "wantsHeadingUpdates",
        "locationManager.headingFilter = kCLHeadingFilterNone",
        "startHeadingUpdatesIfNeeded()",
        "CLLocationManager.headingAvailable()",
        "locationManager.startUpdatingHeading()",
        "locationManager.stopUpdatingHeading()",
        "func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading)",
        "Task-030c-b13-B-1 magnetometer diagnostics",
    ],
    "iOS/Core/SensorEngine/SensorFusionEngine.swift": [
        "private var latestDeviceHeading: CLHeading?",
        "gpsProvider.headingPublisher",
        "updateDeviceHeading",
        "latestDeviceHeading: deviceHeading",
        "headingDiagnostics(",
        "deviceHeadingDegrees(for:",
        "normalizedHeadingDegrees",
        "angularDifferenceDegrees",
        "deviceHeadingReliableForRouteContinuity",
        "courseDeviceHeadingAgreement",
        "hasReliableHeadingForRouteContinuity",
        "estimatedRouteActive: false",
    ],
    "Tests/iOSTests/SessionRepositoryTests.swift": [
        "testB13BHeadingDiagnosticsCodableRoundTrip",
        "courseAndDeviceMagnetometer",
        "deviceHeadingDegrees",
        "courseDeviceHeadingAgreement",
        "hasReliableHeadingForRouteContinuity",
        "testB13B1HeadingDiagnosticsDecodesLegacyB13BPayload",
        "deviceHeadingReliableForRouteContinuity, false",
    ],
    "scripts/verify_task030c_b13b_magnetometer_heading_diagnostics.py": [
        "Task-030c-b13-B-1 magnetometer heading diagnostics foundation",
    ],
    "docs/history/DEV_LOG.md": [
        "Task-030c-b13-B-1 — Magnetometer Heading Diagnostics Foundation",
        "deviceHeadingDegrees",
        "courseDeviceHeadingAgreement",
        "estimatedRouteActive false",
    ],
    "docs/adr/ADR-INDEX.md": [
        "Task-030c-b13-B-1 — Magnetometer Heading Diagnostics Foundation",
        "diagnostics-only heading readiness",
    ],
    "docs/reference/FILE_STRUCTURE.md": [
        "Task-030c-b13-B-1 magnetometer heading diagnostics foundation",
        "verify_task030c_b13b_magnetometer_heading_diagnostics.py",
    ],
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
        "Task-030c-b13-B-1 — Magnetometer Heading Diagnostics Foundation",
        "magnetometer heading can be disturbed",
        "no estimated route geometry",
    ],
}

FORBIDDEN = {
    "Shared/Models/MotionSample.swift": [
        "estimatedRouteGeometry",
        "estimatedLatitude",
        "estimatedLongitude",
    ],
    "iOS/Core/SensorEngine/SensorFusionEngine.swift": [
        "emitDeadReckonedSample",
        "DeadReckoningEngine()",
        "estimatedCoordinate",
        "roadSnapping",
        "mapMatching",
    ],
    "iOS/Core/SensorEngine/GPSProvider.swift": [
        "startDeviceMotionUpdates",
        "CMMotionManager",
        "DeadReckoningEngine",
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
    return path.read_text(encoding="utf-8")


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
        "iOS/Core/SensorEngine/GPSProvider.swift",
        "iOS/Core/SensorEngine/SensorFusionEngine.swift",
        "Tests/iOSTests/SessionRepositoryTests.swift",
    ]:
        text = read(rel)
        for token in FORBIDDEN_REPO_REFERENCES:
            if token in text:
                failures.append(f"{rel}: forbidden SnowPrototype reference {token!r}")
    if failures:
        print("Task-030c-b13-B-1 magnetometer heading diagnostics check failed:", file=sys.stderr)
        for failure in failures:
            print(f"  {failure}", file=sys.stderr)
        return 1
    print("Task-030c-b13-B-1 magnetometer heading diagnostics checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
