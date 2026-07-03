#!/usr/bin/env python3
"""Verify Task-030c-b15-B-3 replay-only candidate gap interpolation stays debug-only."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIRED = {
    "Shared/Models/SessionData.swift": [
        'static let currentDebugBuildTaskID = "Task-030c-b18-C"',
    ],
    "iOS/Features/Debug/DebugToolsPanelView.swift": [
        'Text("debug.build.currentTaskID")',
        "debugBuildSignatureCard",
    ],
    "Shared/Models/MotionSample.swift": [
        "struct DeadReckoningCandidateInterpolationConfig",
        "static let debugReplayOnly = DeadReckoningCandidateInterpolationConfig()",
        "struct DeadReckoningInterpolatedRoutePoint",
        "struct DeadReckoningCandidateInterpolationResult",
        "struct DeadReckoningCandidateInterpolationSummary",
        "enum DeadReckoningCandidateInterpolationAnalyzer",
        "case debugCandidateOnly",
        "case anchorClosureTooLarge",
        "readinessSummary: DeadReckoningReadinessSummary? = nil",
        "DeadReckoningReadinessAnalyzer.analyze(",
        "Task-030c-b15-B-3: candidate interpolation works over persisted sample cadence",
        "estimatedRouteActive: Bool = false",
    ],
    "Tests/iOSTests/SessionRepositoryTests.swift": [
        "testB14BCandidateInterpolationProducesDebugOnlyPoints",
        "testB14BCandidateInterpolationBlocksMissingHeading",
        "testB14BCandidateInterpolationBlocksLargeAnchorClosure",
        "DeadReckoningCandidateInterpolationAnalyzer.analyze(samples: samples)",
        "maximumAnchorClosureDistanceMeters: 1",
        "Task-030c-b15-B-3 must remain replay-only",
    ],
    "iOS/Features/SessionSummary/SessionRouteMapView.swift": [
        "Task-030c-b15-B-3: startup warm-up geometry remains available as",
        "solid fluorescent-pink context with full route-line weight",
        "var lineWidth: CGFloat { 4 }",
        "var opacity: Double { 1 }",
        "var dash: [CGFloat] { [] }",
        "currentCoordinates = pointStyle == .trusted ? [] : [previousPoint.displayCoordinate]",
    ],
    "scripts/verify_task030c_b14b_candidate_gap_interpolation.py": [
        "Task-030c-b15-B-3 replay-only candidate gap interpolation stays debug-only",
    ],
    "docs/history/DEV_LOG.md": [
        "Task-030c-b15-B-3 — Replay-Only Candidate Gap Interpolation Prototype",
        "DeadReckoningCandidateInterpolationAnalyzer",
        "solid fluorescent-pink startup/warm-up route context",
    ],
    "docs/adr/ADR-INDEX.md": [
        "Task-030c-b15-B-3 — Replay-Only Candidate Gap Interpolation Prototype",
        "debug-only candidate points",
        "estimatedRouteActive remains false",
    ],
    "docs/reference/FILE_STRUCTURE.md": [
        "Task-030c-b15-B-3 replay-only candidate gap interpolation prototype",
        "verify_task030c_b14b_candidate_gap_interpolation.py",
    ],
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
        "Task-030c-b15-B-3 — Replay-Only Candidate Gap Interpolation Prototype",
        "Production route estimation",
        "estimatedRouteActive == true",
    ],
}

FORBIDDEN = {
    "Shared/Models/MotionSample.swift": [
        "estimatedRouteActive: true",
        "productionEstimatedRoute",
        "EstimatedRouteEngine",
        "DeadReckoningEngine()",
        "emitDeadReckonedSample",
        "roadSnapping",
        "mapMatching",
        "motionSamples.append(DeadReckoning",
    ],
    "iOS/Core/SensorEngine/SensorFusionEngine.swift": [
        "estimatedRouteActive: true",
        "DeadReckoningCandidateInterpolationAnalyzer.analyze",
        "DeadReckoningEngine()",
        "emitDeadReckonedSample",
        "roadSnapping",
        "mapMatching",
    ],
    "iOS/Features/SessionSummary/SessionRouteMapView.swift": [
        "estimatedRouteGeometry",
        "DeadReckoningCandidateInterpolationAnalyzer.analyze",
        "estimatedRouteActive: true",
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
        "Tests/iOSTests/SessionRepositoryTests.swift",
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
        print("Task-030c-b15-B-3 candidate gap interpolation check failed:", file=sys.stderr)
        for failure in failures:
            print(f"  {failure}", file=sys.stderr)
        return 1
    print("Task-030c-b15-B-3 candidate gap interpolation checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
