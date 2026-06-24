#!/usr/bin/env python3
"""Verify Task-030c-b11-r3-3 startup anchor semantics and approximate start marker."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIREMENTS = {
    "Shared/Models/SessionData.swift": [
        'static let currentDebugBuildTaskID = "Task-030c-b13-A-4"',
    ],
    "iOS/Features/Debug/DebugToolsPanelView.swift": [
        "Task-030c-b13-A-4",
    ],
    "iOS/Features/SessionSummary/SessionRouteMapView.swift": [
        "RouteStartMarkerState",
        "recordingStartDisplayPoint",
        "recordingStartCoordinate",
        "isStartApproximate",
        "routeStartMarkerState",
        "gpsLockCoordinate",
        "gpsLockElapsed",
        "gpsObservedMovementOnsetElapsed",
        "gpsLockRouteCoordinates",
        "firstGPSLockAnchorTimestamp",
        "startupGPSLockSearchWindowSeconds",
        "startupConvergenceWarmupSeconds",
        "approximateStartLockDelaySeconds",
        "startupAnchorGuardApplies",
        "startIsApproximate",
        "play.circle",
        "primaryMapRegionCoordinates(reliableCoordinates: reliableCoordinates, gpsLockCoordinates: gpsLockCoordinates)",
        "if gpsLockCoordinates.count >= 2 { return gpsLockCoordinates }",
        "startCoordinate = startMarkerState?.coordinate",
        "summary.route.accuracy.startup",
    ],
    "docs/history/DEV_LOG.md": [
        "Task-030c-b11-r3-3 — Post-Record GPS Lock Guard + Approximate Start Semantics",
        "GPS lock route anchor",
        "approximate start",
    ],
    "docs/adr/ADR-INDEX.md": [
        "Task-030c-b11-r3-3",
        "Post-Record GPS Lock Guard + Approximate Start Semantics",
        "approximate start",
    ],
    "docs/reference/FILE_STRUCTURE.md": [
        "verify_task030c_startup_anchor_semantics.py",
        "Task-030c-b11-r3-3",
    ],
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
        "Task-030c-b11-r3-3",
        "approximate start",
        "GPS lock",
    ],
}

FORBIDDEN = {
    "iOS/Features/SessionSummary/SessionRouteMapView.swift": [
        "startCoordinate = reliableCoordinates.first ?? coordinates.first",
        "Map(initialPosition: .region(region(for: coordinates)))",
    ],
}


def read(path: str) -> str:
    full = ROOT / path
    try:
        return full.read_text()
    except FileNotFoundError:
        print(f"Missing required file: {path}", file=sys.stderr)
        sys.exit(1)


def main() -> int:
    failures = []
    for path, tokens in REQUIREMENTS.items():
        content = read(path)
        for token in tokens:
            if token not in content:
                failures.append(f"{path}: missing {token!r}")
    for path, tokens in FORBIDDEN.items():
        content = read(path)
        for token in tokens:
            if token in content:
                failures.append(f"{path}: forbidden {token!r}")
    if failures:
        print("Task-030c-b11-r3-3 startup anchor semantics check failed:", file=sys.stderr)
        for failure in failures:
            print(f"  {failure}", file=sys.stderr)
        return 1
    print("Task-030c-b11-r3-3 startup anchor semantics checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
