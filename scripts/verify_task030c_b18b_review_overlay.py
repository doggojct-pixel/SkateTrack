#!/usr/bin/env python3
"""Verify Task-030c-b18-B review-only estimated route overlay artifact boundaries."""

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
    require("Shared/Models/EstimatedRouteReviewOverlay.swift", [
        "struct EstimatedRouteReviewOverlayRecord",
        "let sourceDecisionTaskIdentifier: String",
        "let sessionReviewRole: String?",
        "let decisionState: EstimatedRouteDisplayDecisionState",
        "let reviewDisposition: String",
        "let reviewArtifactOnly: Bool",
        "let routeGeometryIncluded: Bool",
        "let persistedOverlayApplied: Bool",
        "let userVisibleDisplayAllowed: Bool",
        "self.reviewArtifactOnly = true",
        "self.routeGeometryIncluded = false",
        "self.productionRouteMutationApplied = false",
        "self.trustedMetricsMutationApplied = false",
        "self.estimatedRouteDisplayEnabled = false",
        "self.persistedOverlayApplied = false",
        "self.userVisibleDisplayAllowed = false",
        "struct EstimatedRouteReviewOverlay",
        "taskIdentifier: String = \"Task-030c-b18-B\"",
        "sourceTaskIdentifier: String = \"Task-030c-b18-A\"",
        "self.reviewOnly = true",
        "self.exportedReviewArtifactOnly = true",
        "self.normalSessionMapMutationApplied = false",
        "self.productDecisionCheckpointRequired = true",
    ])
    require("iOS/Core/SensorEngine/EstimatedRouteReviewOverlayBuilder.swift", [
        "enum EstimatedRouteReviewOverlayBuilder",
        "makeOverlay(",
        "EstimatedRouteDisplayGate.makeDecisions(for: pack)",
        "sessionReviewRoles[decision.sessionIdentifier]",
        "makeRecord(",
        "reviewDisposition(for: decision.state)",
        "blockedRegressionTrap",
        "reviewOnlyEvidence",
        "candidateButHiddenByProductDecision",
        "futureProductReviewOnly",
    ])
    require("Tests/iOSTests/EstimatedRouteReviewOverlayTests.swift", [
        "testOverlayIsReviewOnlyAndNeverUserVisible",
        "testRealSessionRegressionTrapsRemainBlockedOrHidden",
        "testReviewRolesAreCarriedWithoutPersistenceOrRouteGeometry",
        "testElectricSkateboardCoreCandidateIsNotPromotedToProductDisplay",
        "electricSkateboardCoreCandidate",
        "walkingLowSpeedTrap",
        "surfskateShelteredHighRisk",
        "motorcyclePressureTest",
        "motorcycleControl",
        "20260701-204949",
        "20260701-204705",
        "20260701-192842",
        "20260629-131547",
        "20260629-132410",
        "XCTAssertFalse(overlay.userVisibleDisplayAllowed)",
        "XCTAssertFalse(record.userVisibleDisplayAllowed)",
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
        "EstimatedRouteReviewOverlay.swift in Sources",
        "EstimatedRouteReviewOverlayBuilder.swift in Sources",
        "EstimatedRouteReviewOverlayTests.swift in Sources",
    ])
    require("docs/planning/Task-030c-b18_Product_Decision_Checkpoint_and_Safety_Gated_Display_Plan_EN_v1.1.md", [
        "b18-B implementation note",
        "review-only overlay artifact contract",
        "b18-B verifier requirements",
        "The five real-session regression roles are represented in deterministic XCTest coverage.",
    ])
    require("docs/history/DEV_LOG.md", [
        "Task-030c-b18-B — Review-Only Estimated Route Overlay Artifact",
        "five b17-D-3 real-session regression roles",
        "No Core Data, SessionRepository, SessionEntityMapper, `.skatetrack` schema, route map, or trusted metric mutation is introduced.",
    ])
    require("docs/adr/ADR-INDEX.md", [
        "Task-030c-b18-B — Review-Only Estimated Route Overlay Artifact",
        "The overlay artifact is not route geometry and is not a product route.",
        "estimatedRouteActive remains false",
    ])
    require("docs/reference/FILE_STRUCTURE.md", [
        "Task-030c-b18-B review-only estimated route overlay artifact",
        "EstimatedRouteReviewOverlay.swift",
        "EstimatedRouteReviewOverlayBuilder.swift",
        "verify_task030c_b18b_review_overlay.py",
    ])
    require("docs/release/KNOWN_LIMITATIONS_PRE_ADP.md", [
        "Task-030c-b18-B — Review-Only Estimated Route Overlay Artifact",
        "The overlay artifact is not a normal route overlay and is not visible to general users.",
        "five real-session regression traps",
    ])
    require("scripts/verify_task030c_post_b15_v12_alignment.py", [
        "Task-030c-b18-B",
        "Task-030c-b18-B Implementation Note",
        "EstimatedRouteReviewOverlay.swift in Sources",
        "EstimatedRouteReviewOverlayBuilder.swift in Sources",
        "EstimatedRouteReviewOverlayTests.swift in Sources",
    ])

    require_first_line(
        "Shared/Models/EstimatedRouteReviewOverlay.swift",
        "// [協作區] Shared/Models/EstimatedRouteReviewOverlay.swift",
    )
    require_first_line(
        "iOS/Core/SensorEngine/EstimatedRouteReviewOverlayBuilder.swift",
        "// [自主區] iOS/Core/SensorEngine/EstimatedRouteReviewOverlayBuilder.swift",
    )
    require_first_line(
        "Tests/iOSTests/EstimatedRouteReviewOverlayTests.swift",
        "// [自主區] Tests/iOSTests/EstimatedRouteReviewOverlayTests.swift",
    )
    for relative_path in [
        "Shared/Models/EstimatedRouteReviewOverlay.swift",
        "iOS/Core/SensorEngine/EstimatedRouteReviewOverlayBuilder.swift",
        "Tests/iOSTests/EstimatedRouteReviewOverlayTests.swift",
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
        "estimatedRouteOverlayData",
    ]
    production_forbidden = [
        "estimatedRouteActive: true",
        "productionRouteMutationApplied = true",
        "trustedMetricsMutationApplied = true",
        "estimatedRouteDisplayEnabled = true",
        "userVisibleDisplayAllowed = true",
        "normalSessionMapMutationApplied = true",
        "routeMap",
        "mapMatching",
        "roadSnapping",
        "trustedDistanceOverride",
        "CLLocationManager",
    ]
    for relative_path in [
        "Shared/Models/EstimatedRouteReviewOverlay.swift",
        "iOS/Core/SensorEngine/EstimatedRouteReviewOverlayBuilder.swift",
        "Tests/iOSTests/EstimatedRouteReviewOverlayTests.swift",
    ]:
        require_absent(relative_path, persistence_forbidden)
        require_absent(relative_path, production_forbidden)

    for persistence_file in [
        "Shared/Persistence/SessionRepository.swift",
        "Shared/Persistence/SessionEntityMapper.swift",
    ]:
        path = ROOT / persistence_file
        if path.exists():
            text = path.read_text(encoding="utf-8")
            if "EstimatedRouteReviewOverlay" in text or "EstimatedRouteReviewOverlayRecord" in text:
                raise AssertionError(f"{persistence_file} must not persist b18-B overlay artifacts")

    print("Task-030c-b18-B review-only overlay checks passed.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"Task-030c-b18-B check failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
