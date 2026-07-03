#!/usr/bin/env python3
"""Verify Task-030c-b18-A product decision gate and in-memory display decision boundaries."""

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]


def read(relative_path: str) -> str:
    path = ROOT / relative_path
    if not path.exists():
        raise AssertionError(f"Missing required file: {relative_path}")
    return path.read_text(encoding="utf-8")


def require(relative_path: str, tokens: list[str]) -> None:
    text = read(relative_path)
    for token in tokens:
        if token not in text:
            raise AssertionError(f"Missing token in {relative_path}: {token}")


def require_absent(relative_path: str, tokens: list[str]) -> None:
    text = read(relative_path)
    for token in tokens:
        if token in text:
            raise AssertionError(f"Forbidden token in {relative_path}: {token}")


def require_first_line(relative_path: str, expected: str) -> None:
    first_line = read(relative_path).splitlines()[0]
    if first_line != expected:
        raise AssertionError(f"{relative_path} first line must be {expected!r}, got {first_line!r}")


def require_under_line_limit(relative_path: str, limit: int = 500) -> None:
    line_count = len(read(relative_path).splitlines())
    if line_count > limit:
        raise AssertionError(f"{relative_path} has {line_count} lines, limit is {limit}")


def main() -> int:
    require("Shared/Models/EstimatedRouteDisplayDecision.swift", [
        "enum EstimatedRouteDisplayDecisionState",
        "case blocked",
        "case reviewOnly",
        "case candidateButHidden",
        "case eligibleForFutureProductReview",
        "struct EstimatedRouteDisplayDecision",
        "taskIdentifier: String = \"Task-030c-b18-A\"",
        "sourceTaskIdentifier: String = \"Task-030c-b17-D\"",
        "let inMemoryOnly: Bool",
        "let persistedDecisionApplied: Bool",
        "let userVisibleDisplayAllowed: Bool",
        "self.inMemoryOnly = true",
        "self.productionRouteMutationApplied = false",
        "self.trustedMetricsMutationApplied = false",
        "self.estimatedRouteDisplayEnabled = false",
        "self.persistedDecisionApplied = false",
        "self.userVisibleDisplayAllowed = false",
    ])
    require("iOS/Core/SensorEngine/EstimatedRouteDisplayGate.swift", [
        "enum EstimatedRouteDisplayGatePolicy",
        "static let maximumCandidateGapDurationSeconds: TimeInterval = 6",
        "static let maximumReviewOnlyGapDurationSeconds: TimeInterval = 30",
        "static let maximumCandidateClosureErrorMeters: Double = 8",
        "static let maximumCandidateClosureErrorRatio: Double = 0.25",
        "static let minimumCandidateIMUSampleCoverageRatio: Double = 0.80",
        "acceptsCandidateHeadingReliability",
        "enum EstimatedRouteDisplayGate",
        "makeDecision(for record: DeadReckoningReplayReviewGapRecord)",
        "makeDecisions(for pack: DeadReckoningReplayReviewPack)",
        "passesSixSecondCandidateGate",
        "passesThirtySecondReviewGate",
        "hiddenByB18ProductDecision",
        "futureProductReviewOnly",
    ])
    require("Tests/iOSTests/EstimatedRouteDisplayGateTests.swift", [
        "testShortHighQualityGapBecomesCandidateButHidden",
        "testThirtySecondHighQualityGapIsFutureProductReviewOnly",
        "testLongGapIsBlockedEvenWhenOtherEvidenceLooksGood",
        "testLargeClosureErrorIsBlockedForElectricSkateboardCoreCandidate",
        "testWalkingLowSpeedTrapWithPoorHeadingIsBlocked",
        "testPolicyUsesTwoTierSixSecondAndThirtySecondGates",
        "20260701-204949",
        "20260701-204705",
    ])
    require("Shared/Models/SessionData.swift", [
        'static let currentDebugBuildTaskID = "Task-030c-b19"',
    ])
    for loc in [
        "Shared/Localization/en.lproj/Localizable.strings",
        "Shared/Localization/zh-Hant.lproj/Localizable.strings",
        "Shared/Localization/ja.lproj/Localizable.strings",
    ]:
        require(loc, ['"debug.build.currentTaskID" = "Task-030c-b19";'])

    require("SkateTrack.xcodeproj/project.pbxproj", [
        "EstimatedRouteDisplayDecision.swift in Sources",
        "EstimatedRouteDisplayGate.swift in Sources",
        "EstimatedRouteDisplayGateTests.swift in Sources",
    ])
    require("docs/planning/Task-030c-b18_Product_Decision_Checkpoint_and_Safety_Gated_Display_Plan_EN_v1.1.md", [
        "`EstimatedRouteDisplayDecision` and `EstimatedRouteDisplayGate` must be **in-memory only**",
        "maximumCandidateGapDurationSeconds: TimeInterval = 6",
        "maximumReviewOnlyGapDurationSeconds: TimeInterval = 30",
        "Task-030c_Post-b15_Localization_Completion_Plan_EN_v1.2",
    ])
    require("docs/history/DEV_LOG.md", [
        "Task-030c-b18-A — Product Decision Gate and In-Memory Estimated Route Display Decision",
        "maximumCandidateGapDurationSeconds = 6",
        "maximumReviewOnlyGapDurationSeconds = 30",
        "No Core Data attribute, SessionRepository persistence, SessionEntityMapper mapping, or `.skatetrack` package schema change is introduced.",
    ])
    require("docs/adr/ADR-INDEX.md", [
        "Task-030c-b18-A — Product Decision Gate and In-Memory Estimated Route Display Decision",
        "maximumCandidateGapDurationSeconds = 6",
        "maximumReviewOnlyGapDurationSeconds = 30",
        "no Core Data persistence",
    ])
    require("docs/reference/FILE_STRUCTURE.md", [
        "Task-030c-b18-A product decision gate and in-memory estimated route display decision",
        "EstimatedRouteDisplayDecision.swift",
        "EstimatedRouteDisplayGate.swift",
        "verify_task030c_b18a_product_decision_gate.py",
    ])
    require("docs/release/KNOWN_LIMITATIONS_PRE_ADP.md", [
        "Task-030c-b18-A — Product Decision Gate and In-Memory Estimated Route Display Decision",
        "No Core Data attribute",
        "estimatedRouteActive",
    ])

    require_first_line(
        "Shared/Models/EstimatedRouteDisplayDecision.swift",
        "// [協作區] Shared/Models/EstimatedRouteDisplayDecision.swift",
    )
    require_first_line(
        "iOS/Core/SensorEngine/EstimatedRouteDisplayGate.swift",
        "// [自主區] iOS/Core/SensorEngine/EstimatedRouteDisplayGate.swift",
    )
    require_first_line(
        "Tests/iOSTests/EstimatedRouteDisplayGateTests.swift",
        "// [自主區] Tests/iOSTests/EstimatedRouteDisplayGateTests.swift",
    )
    for relative_path in [
        "Shared/Models/EstimatedRouteDisplayDecision.swift",
        "iOS/Core/SensorEngine/EstimatedRouteDisplayGate.swift",
        "Tests/iOSTests/EstimatedRouteDisplayGateTests.swift",
    ]:
        require_under_line_limit(relative_path)

    persistence_forbidden = [
        "NSManagedObject",
        "NSEntityDescription",
        "SessionEntityMapper",
        "SessionRepository",
        "PersistenceController",
        "debugRecordingDiagnosticsData",
        "estimatedRouteDecisionData",
    ]
    for relative_path in [
        "Shared/Models/EstimatedRouteDisplayDecision.swift",
        "iOS/Core/SensorEngine/EstimatedRouteDisplayGate.swift",
    ]:
        require_absent(relative_path, persistence_forbidden)

    production_forbidden = [
        "estimatedRouteActive: true",
        "productionRouteMutationApplied = true",
        "trustedMetricsMutationApplied = true",
        "estimatedRouteDisplayEnabled = true",
        "userVisibleDisplayAllowed = true",
        "routeMap",
        "mapMatching",
        "roadSnapping",
        "trustedDistanceOverride",
        "CLLocationManager",
    ]
    for relative_path in [
        "Shared/Models/EstimatedRouteDisplayDecision.swift",
        "iOS/Core/SensorEngine/EstimatedRouteDisplayGate.swift",
        "Tests/iOSTests/EstimatedRouteDisplayGateTests.swift",
        "iOS/Core/SensorEngine/SensorFusionEngine.swift",
    ]:
        require_absent(relative_path, production_forbidden)

    for persistence_file in [
        "Shared/Persistence/SessionRepository.swift",
        "Shared/Persistence/SessionEntityMapper.swift",
    ]:
        if (ROOT / persistence_file).exists() and "EstimatedRouteDisplayDecision" in read(persistence_file):
            raise AssertionError(f"{persistence_file} must not persist EstimatedRouteDisplayDecision in b18-A")

    panel_path = ROOT / "iOS/Features/Debug/EstimatedRouteReviewPanel.swift"
    if panel_path.exists():
        panel_text = panel_path.read_text(encoding="utf-8")
        debug_index = panel_text.find("#if DEBUG")
        type_index = panel_text.find("struct EstimatedRouteReviewPanel")
        endif_index = panel_text.rfind("#endif")
        if not (0 <= debug_index < type_index < endif_index):
            raise AssertionError("EstimatedRouteReviewPanel.swift must wrap the entire type in #if DEBUG")

    print("Task-030c-b18-A product decision gate checks passed.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"Task-030c-b18-A check failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
