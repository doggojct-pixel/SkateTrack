#!/usr/bin/env python3
"""Verify Task-030c-b15-B-3 replay-only dead-reckoning readiness diagnostics."""
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
        "enum DeadReckoningReplayReadinessBlockingReason",
        "struct DeadReckoningReadinessConfig",
        "static let conservativeReplayOnly = DeadReckoningReadinessConfig()",
        "struct DeadReckoningReadinessGapCandidate",
        "struct DeadReckoningReadinessSummary",
        "enum DeadReckoningReadinessAnalyzer",
        "static func analyze(",
        "minimumIMUSamplesPerSecond",
        "maximumHeadingAgeSeconds",
        "maximumHeadingAccuracyDegrees",
        "eligibleForReplay",
        "blockingReasonCounts",
        "estimatedRouteActive: Bool = false",
        "deviceHeadingReliableForRouteContinuity: try container.decodeIfPresent(Bool.self",
    ],
    "Tests/iOSTests/SessionRepositoryTests.swift": [
        "testB14ADeadReckoningReadinessAnalyzerClassifiesReplayEligibleGap",
        "testB14ADeadReckoningReadinessAnalyzerBlocksMissingHeading",
        "testB14ADeadReckoningReadinessAnalyzerDoesNotMutateSamplesOrEnableRouteEstimation",
        "makeB14AReadinessSamples",
        "testB13B1HeadingDiagnosticsDecodesLegacyB13BPayload",
        "estimatedRouteActive == true",
    ],
    "scripts/verify_task030c_b14a_dead_reckoning_readiness.py": [
        "Task-030c-b15-B-3 replay-only dead-reckoning readiness diagnostics",
    ],
    "docs/history/DEV_LOG.md": [
        "Task-030c-b15-B-3 — Replay-Only Dead-Reckoning Readiness Diagnostics",
        "does not write estimated route points",
        "preserves b13-A-4 distance/altitude behavior",
        "preserves b13-B-1 legacy heading diagnostics decoding",
    ],
    "docs/adr/ADR-INDEX.md": [
        "Task-030c-b15-B-3 — Replay-Only Dead-Reckoning Readiness Diagnostics",
        "replay-only readiness",
        "estimatedRouteActive remains false",
    ],
    "docs/reference/FILE_STRUCTURE.md": [
        "Task-030c-b15-B-3 replay-only dead-reckoning readiness diagnostics",
        "verify_task030c_b14a_dead_reckoning_readiness.py",
        "DeadReckoningReadinessAnalyzer",
    ],
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
        "Task-030c-b15-B-3 — Replay-Only Dead-Reckoning Readiness Diagnostics",
        "no estimated route geometry",
        "dead reckoning remains disabled",
    ],
}

FORBIDDEN = {
    "Shared/Models/MotionSample.swift": [
        "estimatedRouteGeometry",
        "estimatedLatitude",
        "estimatedLongitude",
        "DeadReckoningEngine()",
        "emitDeadReckonedSample",
        "estimatedCoordinate",
        "roadSnapping",
        "mapMatching",
        "estimatedRouteActive: true",
    ],
    "iOS/Core/SensorEngine/SensorFusionEngine.swift": [
        "emitDeadReckonedSample",
        "DeadReckoningEngine()",
        "estimatedCoordinate",
        "roadSnapping",
        "mapMatching",
        "estimatedRouteActive: true",
    ],
    "iOS/Core/SensorEngine/GPSProvider.swift": [
        "DeadReckoningEngine",
        "estimatedRouteActive: true",
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
        "iOS/Core/SensorEngine/GPSProvider.swift",
        "iOS/Features/Debug/DebugToolsPanelView.swift",
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
        print("Task-030c-b15-B-3 replay-only dead-reckoning readiness check failed:", file=sys.stderr)
        for failure in failures:
            print(f"  {failure}", file=sys.stderr)
        return 1
    print("Task-030c-b15-B-3 replay-only dead-reckoning readiness checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
