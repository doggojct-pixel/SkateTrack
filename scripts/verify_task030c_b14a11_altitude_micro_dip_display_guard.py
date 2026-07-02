#!/usr/bin/env python3
"""Verify Task-030c-b15-B-3 altitude micro-dip display guard remains display-only."""
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
    "iOS/Features/SessionSummary/SessionAdvancedChartsView.swift": [
        "altitudeMicroDipDisplayGuardedPoints",
        "source == .barometerRelative ? altitudeMicroDipDisplayGuardedPoints(rawPoints) : rawPoints",
        "Task-030c-b15-B-3: display-only guard for very short barometer notches",
        "minimumDipMeters = 1.35",
        "maximumBaselineDisagreementMeters = 0.85",
        "maximumGuardSpanSeconds = 34.0",
        "does not rewrite MotionSample, elevation gain summaries, route geometry, or exported diagnostics",
        "trustedBarometerRelativeAltitude(for: $0) != nil",
    ],
    "scripts/verify_task030c_b14a11_altitude_micro_dip_display_guard.py": [
        "Task-030c-b15-B-3 altitude micro-dip display guard remains display-only",
    ],
    "docs/history/DEV_LOG.md": [
        "Task-030c-b15-B-3 — Altitude Chart Micro-Dip Display Guard",
        "display-only micro-dip guard",
        "does not rewrite stored samples",
    ],
    "docs/adr/ADR-INDEX.md": [
        "Task-030c-b15-B-3 — Altitude Chart Micro-Dip Display Guard",
        "display-only guard for very short barometer notches",
        "route geometry remains unchanged",
    ],
    "docs/reference/FILE_STRUCTURE.md": [
        "Task-030c-b15-B-3 altitude micro-dip display guard",
        "verify_task030c_b14a11_altitude_micro_dip_display_guard.py",
    ],
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
        "Task-030c-b15-B-3 — Altitude Chart Micro-Dip Display Guard",
        "does not change elevation gain summaries",
        "does not enable dead reckoning",
    ],
}

FORBIDDEN = {
    "iOS/Features/SessionSummary/SessionAdvancedChartsView.swift": [
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
    "Shared/Models/MotionSample.swift": [
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
        print("Task-030c-b15-B-3 altitude micro-dip display guard check failed:", file=sys.stderr)
        for failure in failures:
            print(f"  {failure}", file=sys.stderr)
        return 1
    print("Task-030c-b15-B-3 altitude micro-dip display guard checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
