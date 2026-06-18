#!/usr/bin/env python3
"""Verify Task-030c-b11-r3-3 small-area route geometry stabilization."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIREMENTS = {
    "Shared/Models/SessionData.swift": [
        'static let currentDebugBuildTaskID = "Task-030c-b12"',
    ],
    "iOS/Features/Debug/DebugToolsPanelView.swift": [
        "Task-030c-b12",
    ],
    "iOS/Features/SessionSummary/SessionRouteMapView.swift": [
        "RouteDisplayPoint",
        "rawRouteCoordinates",
        "displayRoutePoints",
        "displayRouteCoordinates",
        "displayRouteSegments",
        "makeDisplayRoutePoints(from samples:",
        "deduplicatedTrustedLocationFixes(from samples:",
        "isTrustedDisplayRouteSample",
        "shouldSuppressSmallAreaJitter",
        "smoothDisplayCoordinate",
        "interpolatedCoordinate",
        "primaryMapRegionCoordinates",
        "rawCoordinate",
        "displayCoordinate",
        "Task-030c-b11-r3-3: prefer raw location fixes over timer-fusion repeats",
    ],
    "scripts/verify_session_summary.py": [
        "rawRouteCoordinates",
        "displayRoutePoints",
        "displayRouteSegments",
        "makeDisplayRoutePoints",
        "deduplicatedTrustedLocationFixes",
        "shouldSuppressSmallAreaJitter",
        "smoothDisplayCoordinate",
    ],
    "docs/history/DEV_LOG.md": [
        "Task-030c-b11-r3-3",
        "Small-Area Route Geometry Stabilization",
        "rawRoute",
        "trustedRoute",
        "displayRoute",
    ],
    "docs/reference/FILE_STRUCTURE.md": [
        "verify_task030c_small_area_route_geometry.py",
        "Task-030c-b11-r3-3",
        "displayRoute",
    ],
    "docs/adr/ADR-INDEX.md": [
        "Task-030c-b11-r3-3",
        "rawRoute",
        "trustedRoute",
        "displayRoute",
    ],
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
        "Task-030c-b11-r3-3",
        "Small-area route geometry",
        "S-curve",
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
    missing = []
    for path, tokens in REQUIREMENTS.items():
        content = read(path)
        for token in tokens:
            if token not in content:
                missing.append((path, token))
    if missing:
        print("Task-030c-b11-r3-3 small-area route geometry check failed:", file=sys.stderr)
        for path, token in missing:
            print(f"  {path}: missing {token!r}", file=sys.stderr)
        return 1
    print("Task-030c-b11-r3-3 small-area route geometry checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
