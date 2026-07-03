#!/usr/bin/env python3
"""Verify Task-030c-b18-D product decision update boundaries."""
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


def require_first_line_marker(relative_path: str, marker: str) -> None:
    first_line = read(relative_path).splitlines()[0]
    if first_line != marker:
        raise AssertionError(f"{relative_path} first line must be {marker!r}, got {first_line!r}")


def require_swift_file_under_limit(relative_path: str, limit: int = 500) -> None:
    line_count = len(read(relative_path).splitlines())
    if line_count > limit:
        raise AssertionError(f"{relative_path} has {line_count} lines, limit is {limit}")


def main() -> int:
    require("Shared/Models/EstimatedRouteProductDecisionUpdate.swift", [
        "enum EstimatedRouteProductDecisionOutcome",
        "case keepDisabled",
        "struct EstimatedRouteProductDecisionUpdate",
        "struct EstimatedRouteProductDecisionSessionSummary",
        'taskIdentifier: String = \"Task-030c-b18-D\"',
        'sourceTaskIdentifier: String = \"Task-030c-b18-C\"',
        "self.outcome = .keepDisabled",
        "self.productDecisionCheckpointRequired = true",
        "self.generalUserEstimatedRouteDisplayAllowed = false",
        "self.debugReviewOnly = true",
        "self.routeGeometryIncluded = false",
        "self.normalSessionMapMutationApplied = false",
        "self.productionRouteMutationApplied = false",
        "self.trustedMetricsMutationApplied = false",
        "self.estimatedRouteDisplayEnabled = false",
        "self.persistedDecisionApplied = false",
        "self.userVisibleDisplayAllowed = false",
    ])
    require("iOS/Core/SensorEngine/EstimatedRouteProductDecisionUpdateBuilder.swift", [
        "enum EstimatedRouteProductDecisionUpdateBuilder",
        "requiredRealSessionRoles",
        "electricSkateboardCoreCandidate",
        "motorcycleControl",
        "motorcyclePressureTest",
        "surfskateShelteredHighRisk",
        "walkingLowSpeedTrap",
        "generalUserEstimatedRouteDisplayRemainsDisabled",
        "electricSkateboardCoreCandidateHasZeroUserVisibleEligibility",
        "walkingLowSpeedTrapRemainsBlocked",
        "surfskateShelteredHighRiskRemainsBlocked",
        "motorcyclePressureTestRemainsBlocked",
        "motorcycleControlIsLimitedCandidateEvidenceOnly",
    ])
    require("Tests/iOSTests/EstimatedRouteProductDecisionUpdateTests.swift", [
        "final class EstimatedRouteProductDecisionUpdateTests",
        "XCTAssertEqual(update.outcome, .keepDisabled)",
        "XCTAssertFalse(update.generalUserEstimatedRouteDisplayAllowed)",
        "XCTAssertFalse(update.routeGeometryIncluded)",
        "XCTAssertFalse(update.normalSessionMapMutationApplied)",
        "XCTAssertFalse(update.productionRouteMutationApplied)",
        "XCTAssertFalse(update.trustedMetricsMutationApplied)",
        "XCTAssertFalse(update.estimatedRouteDisplayEnabled)",
        "XCTAssertFalse(update.userVisibleDisplayAllowed)",
        "electricSkateboardCoreCandidate",
        "walkingLowSpeedTrap",
        "surfskateShelteredHighRisk",
        "motorcyclePressureTest",
        "motorcycleControl",
    ])
    require("Shared/Models/SessionData.swift", ['static let currentDebugBuildTaskID = "Task-030c-b19"'])
    for loc in [
        "Shared/Localization/en.lproj/Localizable.strings",
        "Shared/Localization/ja.lproj/Localizable.strings",
        "Shared/Localization/zh-Hant.lproj/Localizable.strings",
    ]:
        require(loc, ['"debug.build.currentTaskID" = "Task-030c-b19";'])
    require("SkateTrack.xcodeproj/project.pbxproj", [
        "EstimatedRouteProductDecisionUpdate.swift in Sources",
        "EstimatedRouteProductDecisionUpdateBuilder.swift in Sources",
        "EstimatedRouteProductDecisionUpdateTests.swift in Sources",
    ])
    require("docs/planning/Task-030c-b18-D_Real_Session_Recheck_and_Product_Decision_Mini_Plan_EN_v1.0.md", [
        "Task-030c-b18-D Real-Session Recheck and Product Decision Update Mini Plan EN v1.0",
        "Completed b18-A through b18-C Production Record",
        "Expected answer based on current evidence",
        "No. General-user estimated route display should remain disabled.",
    ])
    require("docs/adr/ADR-INDEX.md", [
        "Task-030c-b18-D — Real-Session Recheck and Product Decision Update",
        "General-user estimated route display remains disabled",
    ])
    require("docs/history/DEV_LOG.md", [
        "Task-030c-b18-D — Real-Session Recheck and Product Decision Update",
        "EstimatedRouteProductDecisionUpdate",
        "keepDisabled",
    ])
    require("docs/reference/FILE_STRUCTURE.md", [
        "Task-030c-b18-D real-session recheck and product decision update",
        "EstimatedRouteProductDecisionUpdate.swift",
        "EstimatedRouteProductDecisionUpdateBuilder.swift",
        "EstimatedRouteProductDecisionUpdateTests.swift",
        "verify_task030c_b18d_product_decision_update.py",
    ])
    require("docs/release/KNOWN_LIMITATIONS_PRE_ADP.md", [
        "Task-030c-b18-D — Real-Session Recheck and Product Decision Update",
        "General-user estimated route display remains disabled",
    ])
    require("docs/planning/Task-030c-b16_Localization_Foundation_Plan.md", [
        "Task-030c-b18-D Implementation Note",
        "EstimatedRouteProductDecisionUpdate",
        "general-user estimated route display remains disabled",
    ])
    require("docs/planning/Task-030c-b18_Product_Decision_Checkpoint_and_Safety_Gated_Display_Plan_EN_v1.1.md", [
        "Current implementation baseline:** Task-030c-b19",
        "b18-D implementation note",
        "EstimatedRouteProductDecisionUpdate",
        "General-user estimated route display remains disabled",
    ])

    require_first_line_marker("Shared/Models/EstimatedRouteProductDecisionUpdate.swift", "// [協作區] Shared/Models/EstimatedRouteProductDecisionUpdate.swift")
    require_first_line_marker("iOS/Core/SensorEngine/EstimatedRouteProductDecisionUpdateBuilder.swift", "// [自主區] iOS/Core/SensorEngine/EstimatedRouteProductDecisionUpdateBuilder.swift")
    require_first_line_marker("Tests/iOSTests/EstimatedRouteProductDecisionUpdateTests.swift", "// [自主區] Tests/iOSTests/EstimatedRouteProductDecisionUpdateTests.swift")
    for swift_file in [
        "Shared/Models/EstimatedRouteProductDecisionUpdate.swift",
        "iOS/Core/SensorEngine/EstimatedRouteProductDecisionUpdateBuilder.swift",
        "Tests/iOSTests/EstimatedRouteProductDecisionUpdateTests.swift",
    ]:
        require_swift_file_under_limit(swift_file)

    source_guard_files = [
        "Shared/Models/EstimatedRouteProductDecisionUpdate.swift",
        "iOS/Core/SensorEngine/EstimatedRouteProductDecisionUpdateBuilder.swift",
        "Tests/iOSTests/EstimatedRouteProductDecisionUpdateTests.swift",
        "iOS/Core/SensorEngine/SensorFusionEngine.swift",
        "Shared/Models/MotionSample.swift",
    ]
    for rel in source_guard_files:
        require_absent(rel, [
            "estimatedRouteActive: true",
            "productionRouteMutationApplied = true",
            "trustedMetricsMutationApplied = true",
            "estimatedRouteDisplayEnabled = true",
            "userVisibleDisplayAllowed = true",
            "normalSessionMapMutationApplied = true",
            "routeGeometryIncluded = true",
            "generalUserEstimatedRouteDisplayAllowed = true",
        ])

    for rel in [
        "Shared/Persistence/SessionRepository.swift",
        "Shared/Persistence/SessionEntityMapper.swift",
        "Shared/Export/SkateTrackPackagePayload.swift",
        "iOS/Features/SessionSummary/SessionRouteMapView.swift",
    ]:
        if (ROOT / rel).exists():
            require_absent(rel, ["EstimatedRouteProductDecisionUpdate", "EstimatedRouteProductDecisionUpdateBuilder"])

    route_tokens = ["Map(", "MKMapView", "Polyline", "MKPolyline", "Canvas(", "Path("]
    for rel in [
        "Shared/Models/EstimatedRouteProductDecisionUpdate.swift",
        "iOS/Core/SensorEngine/EstimatedRouteProductDecisionUpdateBuilder.swift",
        "Tests/iOSTests/EstimatedRouteProductDecisionUpdateTests.swift",
    ]:
        require_absent(rel, route_tokens)

    print("Task-030c-b18-D product decision update checks passed.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"Task-030c-b18-D check failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
