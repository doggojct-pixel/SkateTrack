#!/usr/bin/env python3
"""Verify Task-030c-b15-B-3 startup route visual suppression remains display-only."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIRED = {
    "Shared/Models/SessionData.swift": [
        'static let currentDebugBuildTaskID = "Task-030c-b16-B"',
    ],
    "iOS/Features/Debug/DebugToolsPanelView.swift": [
        'Text("Task-030c-b16-B")',
        "debugBuildSignatureCard",
    ],
    "iOS/Features/SessionSummary/SessionRouteMapView.swift": [
        "Task-030c-b15-B-3: startup warm-up geometry remains available as",
        "solid fluorescent-pink context with full route-line weight",
        "var lineWidth: CGFloat { 4 }",
        "var opacity: Double { 1 }",
        "var dash: [CGFloat] { [] }",
        "startupRouteVisualSuppressionMaximumSeconds",
        "does not delete raw GPS samples or rewrite",
        "currentCoordinates = pointStyle == .trusted ? [] : [previousPoint.displayCoordinate]",
        "summary.route.accuracy.startup",
    ],
    "scripts/verify_task030c_b14a2_startup_route_visual_suppression.py": [
        "Task-030c-b15-B-3 startup route visual suppression remains display-only",
    ],
    "docs/history/DEV_LOG.md": [
        "Task-030c-b15-B-3 — Startup Route Visual Suppression",
        "solid fluorescent-pink route context",
        "does not delete raw GPS samples",
    ],
    "docs/adr/ADR-INDEX.md": [
        "Task-030c-b15-B-3 — Startup Route Visual Suppression",
        "visual-only suppression",
        "route geometry remains unchanged",
    ],
    "docs/reference/FILE_STRUCTURE.md": [
        "Task-030c-b15-B-3 startup route visual suppression",
        "verify_task030c_b14a2_startup_route_visual_suppression.py",
    ],
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
        "Task-030c-b15-B-3 — Startup Route Visual Suppression",
        "does not change distance, speed, altitude, or route geometry",
        "does not enable dead reckoning",
    ],
}

FORBIDDEN = {
    "iOS/Features/SessionSummary/SessionRouteMapView.swift": [
        "estimatedRouteActive: true",
        "estimatedRouteGeometry",
        "estimatedCoordinate",
        "DeadReckoningEngine()",
        "emitDeadReckonedSample",
        "roadSnapping",
        "mapMatching",
        "samples.remove",
        "motionSamples.remove",
    ],
    "Shared/Models/MotionSample.swift": [
        "estimatedRouteActive: true",
        "estimatedRouteGeometry",
        "estimatedCoordinate",
        "DeadReckoningEngine()",
        "emitDeadReckonedSample",
        "roadSnapping",
        "mapMatching",
    ],
    "iOS/Core/SensorEngine/SensorFusionEngine.swift": [
        "estimatedRouteActive: true",
        "estimatedRouteGeometry",
        "estimatedCoordinate",
        "DeadReckoningEngine()",
        "emitDeadReckonedSample",
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
        "Shared/Models/SessionData.swift",
        "iOS/Core/SensorEngine/SensorFusionEngine.swift",
        "iOS/Features/SessionSummary/SessionRouteMapView.swift",
        "iOS/Features/SessionSummary/SessionAdvancedChartsView.swift",
        "iOS/Features/Debug/DebugToolsPanelView.swift",
        "docs/history/DEV_LOG.md",
        "docs/adr/ADR-INDEX.md",
        "docs/reference/FILE_STRUCTURE.md",
        "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    ]:
        text = read(rel)
        for token in FORBIDDEN_REPO_REFERENCES:
            if token in text:
                failures.append(f"{rel}: forbidden SnowPrototype reference {token!r}")
    if failures:
        print("Task-030c-b15-B-3 startup route visual suppression check failed:", file=sys.stderr)
        for failure in failures:
            print(f"  {failure}", file=sys.stderr)
        return 1
    print("Task-030c-b15-B-3 startup route visual suppression checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
