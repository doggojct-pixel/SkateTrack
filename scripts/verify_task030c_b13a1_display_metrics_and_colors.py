#!/usr/bin/env python3
"""Verify Task-030c-b13-A-4 display-derived metrics, altitude anchoring, and route color semantics."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIRED = {
    "Shared/Models/SessionData.swift": [
        'static let currentDebugBuildTaskID = "Task-030c-b14-B-1"',
    ],
    "iOS/Features/Debug/DebugToolsPanelView.swift": [
        'Text("Task-030c-b14-B-1")',
    ],
    "iOS/Features/SessionSummary/SessionRouteMapView.swift": [
        "private static let fluorescentPink = Color(red: 1.0, green: 0.2, blue: 0.6)",
        "private static let brightOrange = Color(red: 1.0, green: 0.56, blue: 0.0)",
        "var lineWidth: CGFloat { 4 }",
        "var opacity: Double { 1 }",
        "var dash: [CGFloat] { [] }",
        "return Self.brightOrange",
        "return Self.fluorescentPink",
        "low-confidence fixes remain visible as bright-orange uncertain route segments; startup/warm-up fixes are restored to solid fluorescent-pink route context",
    ],
    "iOS/Hooks/useSessionSummary.swift": [
        "enum SessionSummaryDisplayMetrics",
        "displaySpeedKilometersPerHour(for sample: MotionSample, policy: ActivityFidelityPolicy)",
        "displayDistanceKilometers(from: sortedSamples, policy: policy)",
        "diagnostics.routeSegmentConfidence != .unavailable",
        "horizontalAccuracy <= policy.maximumUsableHorizontalAccuracyMeters",
        "coordinateDerivedSpeedKmh.map({ $0 > policy.maximumTrustedImpliedSpeedKmh })",
        "SessionSummaryDisplayMetrics.make(session: session, samples: motionSamples)",
        "conservativeSpeedDistanceKilometers(from: samples, policy: policy, speedTimeDistance: speedTimeDistance)",
        "conservativeMedianSpeedBlendWeight",
        "medianSpeedDistance",
    ],
    "iOS/Features/SessionSummary/SessionAdvancedChartsView.swift": [
        "SessionSummaryDisplayMetrics.displaySpeedKilometersPerHour(for: sample, policy: fidelityPolicy)",
        "absoluteElevationDisplayAnchor(for: content.motionSamples)",
        "displayElevationMeters(for: $0, source: source, anchor: anchor)",
        "display stable relative altitude against a robust absolute anchor when available",
        "anchor.map { $0.offsetMeters + relativeAltitude } ?? relativeAltitude",
    ],
    "iOS/Features/SessionHistory/SessionHistoryCardView.swift": [
        "SessionSummaryDisplayMetrics.make(session: session, samples: session.motionSamples)",
    ],
    "scripts/verify_task030c_b13a_route_confidence_visual_freebord.py": [
        "Task-030c-b13-A-4",
        "private static let brightOrange = Color(red: 1.0, green: 0.56, blue: 0.0)",
    ],
    "scripts/verify_session_summary.py": [
        '"iOS/Hooks/useSessionSummary.swift": 420',
    ],
    "docs/history/DEV_LOG.md": [
        "Task-030c-b13-A-4",
    ],
    "docs/reference/FILE_STRUCTURE.md": [
        "Task-030c-b13-A-4",
    ],
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
        "Task-030c-b13-A-4",
    ],
}

FORBIDDEN = {
    "iOS/Features/SessionSummary/SessionAdvancedChartsView.swift": [
        "normalizedElevationPoints(",
        "trustedDisplaySpeedKilometersPerHour(for:",
        "trustedDisplayElevationMeters(for:",
    ],
    "iOS/Features/SessionSummary/SessionRouteMapView.swift": [
        "var dash: [CGFloat] { self == .startupWarmup ? [3, 3] : [] }",
        "return SkateTrackSessionStartColors.accent2",
        "solid fluorescent-pink uncertain route segments",
    ],
}


def read(rel: str) -> str:
    path = ROOT / rel
    if not path.exists():
        print(f"Missing required file: {rel}", file=sys.stderr)
        sys.exit(1)
    return path.read_text(encoding="utf-8")


def require_token(path: Path, token: str) -> None:
    if not path.exists():
        print(f"Missing required file: {path}", file=sys.stderr)
        sys.exit(1)
    if token not in path.read_text(encoding="utf-8"):
        print(f"Missing required token in {path}: {token!r}", file=sys.stderr)
        sys.exit(1)


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
        print("Task-030c-b13-A-4 display metrics/color check failed:", file=sys.stderr)
        for failure in failures:
            print(f"  {failure}", file=sys.stderr)
        return 1
    require_token(ROOT / "iOS/Hooks/useSessionSummary.swift", "lowConfidenceDistanceActivationRatio")
    require_token(ROOT / "iOS/Hooks/useSessionSummary.swift", "speedIntegratedDistanceKilometers")
    require_token(ROOT / "iOS/Hooks/useSessionSummary.swift", "conservativeSpeedDistanceKilometers")
    require_token(ROOT / "iOS/Hooks/useSessionSummary.swift", "conservativeMedianSpeedBlendWeight")
    require_token(ROOT / "iOS/Hooks/useSessionSummary.swift", "lowConfidenceSampleRatio")
    require_token(ROOT / "iOS/Hooks/useSessionSummary.swift", "distanceIntegrationSpeedCapKmh")
    require_token(ROOT / "iOS/Features/SessionSummary/SessionAdvancedChartsView.swift", "robustAbsoluteElevationOffsetMeters")
    require_token(ROOT / "iOS/Features/SessionSummary/SessionAdvancedChartsView.swift", "pairedOffsets = absoluteSamples.compactMap")
    require_token(ROOT / "iOS/Features/SessionSummary/SessionAdvancedChartsView.swift", "smoothedElevationPoints")
    require_token(ROOT / "iOS/Features/SessionSummary/SessionAdvancedChartsView.swift", "display-only smoothing reduces short altitude spikes")
    require_token(ROOT / "iOS/Hooks/useSessionSummary.swift", "return min(gpsDistance, speedBoundDistance)")
    require_token(ROOT / "iOS/Features/SessionSummary/SessionAdvancedChartsView.swift", "lower stable quartile")
    require_token(ROOT / "iOS/Features/SessionSummary/SessionAdvancedChartsView.swift", "upperQuartile - lowerQuartile >= 7")
    require_token(ROOT / "iOS/Features/SessionSummary/SessionAdvancedChartsView.swift", "smooth(points, windowRadius: 5, maximumStepValue: 0.45)")
    print("Task-030c-b13-A-4 display metrics/color checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
