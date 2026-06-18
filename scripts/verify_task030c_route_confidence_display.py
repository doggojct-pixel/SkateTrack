#!/usr/bin/env python3
"""Verify Task-030c-b11-r3-3 route confidence display continuity."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIREMENTS = {
    "Shared/Models/SessionData.swift": [
        'static let currentDebugBuildTaskID = "Task-030c-b11-r3-3"',
    ],
    "iOS/Features/Debug/DebugToolsPanelView.swift": [
        "Task-030c-b11-r3-3",
    ],
    "iOS/Features/SessionSummary/SessionRouteMapView.swift": [
        "RouteMapSegmentStyle",
        "case uncertain",
        "var segmentStyle: RouteMapSegmentStyle",
        "segment.style.opacity",
        "segment.style.dash",
        "dash: [CGFloat] { self == .trusted ? [] : [3, 3] }",
        "SkateTrackSessionStartColors.accent2",
        "low-confidence fixes remain visible as uncertain route segments",
        "existingStyle != pointStyle",
        "pointStyle == .trusted ? [] : [previousPoint.displayCoordinate]",
        "isolate red warm-up/uncertain geometry from",
        "shouldStartNewRouteSegment(after previousPoint:",
    ],
    "scripts/verify_session_summary.py": [
        "RouteMapSegmentStyle",
        "segment.style.opacity",
    ],
    "docs/history/DEV_LOG.md": [
        "Task-030c-b11-r3-3",
        "Route Confidence Display Continuity",
        "low-confidence",
    ],
    "docs/adr/ADR-INDEX.md": [
        "Task-030c-b11-r3-3",
        "Route Confidence Display Continuity",
        "uncertain",
    ],
    "docs/reference/FILE_STRUCTURE.md": [
        "verify_task030c_route_confidence_display.py",
        "Task-030c-b11-r3-3",
    ],
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
        "Task-030c-b11-r3-3",
        "low-confidence",
        "not claim small-area loops are accurate",
    ],
}

FORBIDDEN_ROUTE_TOKENS = [
    "if point.confidence == .low || point.confidence == .unavailable { return true }",
    "if diagnostics.routeSegmentConfidence == .low || diagnostics.routeSegmentConfidence == .unavailable { return false }",
]


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

    route_map = read("iOS/Features/SessionSummary/SessionRouteMapView.swift")
    forbidden = [token for token in FORBIDDEN_ROUTE_TOKENS if token in route_map]

    if missing or forbidden:
        print("Task-030c-b11-r3-3 route confidence display check failed:", file=sys.stderr)
        for path, token in missing:
            print(f"  {path}: missing {token!r}", file=sys.stderr)
        for token in forbidden:
            print(f"  SessionRouteMapView.swift: forbidden direct-break token {token!r}", file=sys.stderr)
        return 1

    print("Task-030c-b11-r3-3 route confidence display checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
