#!/usr/bin/env python3
"""Verify Task-030c-b13-A route confidence visual and freebord calibration scope."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIRED = {
    "Shared/Models/SessionData.swift": [
        'static let currentDebugBuildTaskID = "Task-030c-b13-A"',
    ],
    "iOS/Features/Debug/DebugToolsPanelView.swift": [
        'Text("Task-030c-b13-A")',
        "debugBuildSignatureCard",
    ],
    "iOS/Features/SessionSummary/SessionRouteMapView.swift": [
        "private static let fluorescentPink = Color(red: 1.0, green: 0.2, blue: 0.6)",
        "var lineWidth: CGFloat { self == .startupWarmup ? 3 : 4 }",
        "var opacity: Double { self == .startupWarmup ? 0.64 : 1 }",
        "var dash: [CGFloat] { self == .startupWarmup ? [3, 3] : [] }",
        "case .uncertain:",
        "return Self.fluorescentPink",
        "case .startupWarmup:",
        "return SkateTrackSessionStartColors.accent2",
        "solid fluorescent-pink uncertain route segments",
    ],
    "iOS/Core/SensorEngine/SensorFusionEngine.swift": [
        "Task-030c-b13-A: coreLocationSpeedKmh only fires when CLLocation actually reported a speed.",
        "if let coreSpeedKmh = coreLocationSpeedKmh, coreSpeedKmh > 0",
        "coreSpeedKmh >= Self.lowSpeedSuspiciousCoreLocationSpeedKmh",
        "speedKmh: coreSpeedKmh",
        "low-speed freebord carving under tree canopy",
        "if let coordinateDerivedSpeedKmh, coordinateDerivedSpeedKmh >= Self.lowSpeedLocalJumpKmh",
        "let metricSpeedKmh = coreLocationSpeedKmh ?? coordinateDerivedSpeedKmh",
    ],
    "scripts/verify_task030c_route_confidence_display.py": [
        "private static let fluorescentPink = Color(red: 1.0, green: 0.2, blue: 0.6)",
        "var dash: [CGFloat] { self == .startupWarmup ? [3, 3] : [] }",
    ],
    "docs/history/DEV_LOG.md": [
        "Task-030c-b13-A — Route Confidence Visual + Freebord Confidence Calibration",
        "solid fluorescent-pink route segments",
        "CoreLocation speed availability",
    ],
    "docs/adr/ADR-INDEX.md": [
        "Task-030c-b13-A — Route Confidence Visual + Freebord Confidence Calibration",
        "coordinate-derived speed must not substitute into the suspicious CoreLocation-speed gate",
    ],
    "docs/reference/FILE_STRUCTURE.md": [
        "Task-030c-b13-A route confidence visual and freebord calibration",
        "verify_task030c_b13a_route_confidence_visual_freebord.py",
    ],
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
        "Task-030c-b13-A — Route Confidence Visual + Freebord Confidence Calibration",
        "does not add IMU dead reckoning",
    ],
}

FORBIDDEN = {
    "iOS/Features/SessionSummary/SessionRouteMapView.swift": [
        "var dash: [CGFloat] { self == .trusted ? [] : [3, 3] }",
        "var opacity: Double { self == .trusted ? 1 : (self == .startupWarmup ? 0.64 : 0.56) }",
        "Task-030c-b11-r3-3 adds post-record GPS lock guarding, approximate start semantics, and red low-quality route styling",
    ],
    "iOS/Core/SensorEngine/SensorFusionEngine.swift": [
        "let speedKmh = coreLocationSpeedKmh ?? coordinateDerivedSpeedKmh ?? 0",
        "emitDeadReckonedSample",
        "DeadReckoningEngine()",
        "estimatedCoordinate",
        "roadSnapping",
        "mapMatching",
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
        "iOS/Features/SessionSummary/SessionRouteMapView.swift",
        "iOS/Core/SensorEngine/SensorFusionEngine.swift",
        "Shared/Models/SessionData.swift",
        "iOS/Features/Debug/DebugToolsPanelView.swift",
    ]:
        text = read(rel)
        for token in FORBIDDEN_REPO_REFERENCES:
            if token in text:
                failures.append(f"{rel}: forbidden SnowPrototype reference {token!r}")

    if failures:
        print("Task-030c-b13-A route confidence visual/freebord calibration check failed:", file=sys.stderr)
        for failure in failures:
            print(f"  {failure}", file=sys.stderr)
        return 1

    print("Task-030c-b13-A route confidence visual/freebord calibration checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
