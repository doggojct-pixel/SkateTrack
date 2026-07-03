#!/usr/bin/env python3
"""Verify Task-030c-b11-r3-3 startup GPS warm-up and route accuracy disclosure."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIRED = {
    "Shared/Models/SessionData.swift": [
        'static let currentDebugBuildTaskID = "Task-030c-b16-D"',
    ],
    "iOS/Features/Debug/DebugToolsPanelView.swift": [
        "Task-030c-b16-D",
    ],
    "iOS/Features/SessionSummary/SessionRouteMapView.swift": [
        "Task-030c-b13-A-4 keeps post-record GPS lock guarding",
        "isStartupWarmup",
        "startupWarmup",
        "isReliableAnchor",
        "reliableDisplayRouteCoordinates",
        "routeStartMarkerState",
        "displayPoints.contains(where: { $0.isReliableAnchor })",
        "gpsLockAnchorTimestamp",
        "startupGPSLockSearchWindowSeconds",
        "startupConvergenceWarmupSeconds",
        "recordingStartCoordinate",
        "isStartApproximate",
        "primaryMapRegionCoordinates(reliableCoordinates: reliableCoordinates, gpsLockCoordinates: gpsLockCoordinates)",
        "isStartupWarmupSample",
        "elapsed < 0",
        "return elapsed >= -10",
        "isPreferredFreshAnchor",
        "firstStableStartupAnchorTimestamp",
        "startupStableAnchorHoldSeconds",
        "stableStartupAnchorTimestamp",
        "reset display smoothing at the first stable",
        "primaryMapRegionCoordinates",
        "return Self.fluorescentPink",
        "var dash: [CGFloat] { [] }",
        "routeAccuracyDisclosureText",
        "summary.route.accuracy.startup",
        "summary.route.accuracy.approxFormat",
        "session-route-accuracy-disclosure",
    ],
    "Shared/Localization/en.lproj/Localizable.strings": [
        "summary.route.accuracy.startup",
        "summary.route.accuracy.approxFormat",
    ],
    "Shared/Localization/zh-Hant.lproj/Localizable.strings": [
        "summary.route.accuracy.startup",
        "summary.route.accuracy.approxFormat",
    ],
    "Shared/Localization/ja.lproj/Localizable.strings": [
        "summary.route.accuracy.startup",
        "summary.route.accuracy.approxFormat",
    ],
    "docs/history/DEV_LOG.md": [
        "Task-030c-b11-r3-3 — Post-Record GPS Lock Guard + Approximate Start Semantics",
        "GPS lock route anchor",
        "approximate start semantics",
        ".skatetrack` export compression / thinning remains deferred",
    ],
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
        "Task-030c-b11-r3-3 — Post-record GPS lock guard and approximate start semantics",
        "Small-area route geometry remains approximate",
    ],
}

FORBIDDEN = {
    "iOS/Features/SessionSummary/SessionRouteMapView.swift": [
        "Map(initialPosition: .region(region(for: coordinates)))",
        "if let start = coordinates.first",
        "startCoordinate = reliableCoordinates.first ?? coordinates.first",
    ],
}


def read(rel):
    path = ROOT / rel
    if not path.exists():
        print(f"Missing required file: {rel}", file=sys.stderr)
        sys.exit(1)
    return path.read_text()


def main():
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
        print("Task-030c-b11-r3-3 startup GPS warm-up check failed:", file=sys.stderr)
        for failure in failures:
            print(f"  {failure}", file=sys.stderr)
        sys.exit(1)
    print("Task-030c-b11-r3-3 startup GPS warm-up checks passed.")


if __name__ == "__main__":
    main()
