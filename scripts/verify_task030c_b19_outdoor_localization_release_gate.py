#!/usr/bin/env python3
"""Verify Task-030c-b19 outdoor localization release gate boundaries."""
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
    require("Shared/Models/OutdoorLocalizationReleaseGate.swift", [
        "enum OutdoorLocalizationReleaseDecision",
        "case releaseReady",
        "case limitedDisclosure",
        "case blocked",
        "enum OutdoorLocalizationReleaseBlockingReason",
        "struct OutdoorLocalizationReleasePolicy",
        "struct OutdoorLocalizationReleaseEvidence",
        "struct OutdoorLocalizationReleaseGate",
        'taskIdentifier: String = "Task-030c-b19"',
        "self.realGPSOnly = true",
        "self.generalUserEstimatedRouteDisplayAllowed = false",
        "self.estimatedRouteDisplayEnabled = false",
        "self.estimatedRouteActive = false",
        "self.routeGeometryMutationApplied = false",
        "self.trustedMetricsMutationApplied = false",
        "self.persistenceSchemaMutationApplied = false",
        "minimumTrustedGPSCoverageRatio",
        "maximumAllowedStartupWarmupSeconds",
        "maximumAllowedGPSGapSeconds",
        "maximumAllowedHorizontalAccuracyMeters",
        "maximumLimitedDisclosureHorizontalAccuracyMeters",
        "maximumLowSpeedTrapDurationSeconds",
    ])
    require("iOS/Core/SensorEngine/OutdoorLocalizationReleaseGateBuilder.swift", [
        "enum OutdoorLocalizationReleaseGateBuilder",
        "conservativePolicy",
        "minimumTrustedGPSCoverageRatio: 0.80",
        "maximumAllowedStartupWarmupSeconds: 30",
        "maximumAllowedGPSGapSeconds: 10",
        "maximumAllowedHorizontalAccuracyMeters: 25",
        "maximumLimitedDisclosureHorizontalAccuracyMeters: 65",
        "maximumLowSpeedTrapDurationSeconds: 20",
        "releaseReady",
        "limitedDisclosure",
        "blocked",
        "estimatedRouteDisplayDisabledByB18D",
        "estimatedRouteDisplayRemainsDisabled",
    ])
    require("Tests/iOSTests/OutdoorLocalizationReleaseGateTests.swift", [
        "final class OutdoorLocalizationReleaseGateTests",
        "XCTAssertEqual(gate.decision, .releaseReady)",
        "XCTAssertEqual(gate.decision, .limitedDisclosure)",
        "XCTAssertEqual(gate.decision, .blocked)",
        "walkingLowSpeedTrap",
        "surfskateShelteredHighRisk",
        "motorcyclePressureTest",
        "XCTAssertFalse(gate.generalUserEstimatedRouteDisplayAllowed)",
        "XCTAssertFalse(gate.estimatedRouteDisplayEnabled)",
        "XCTAssertFalse(gate.estimatedRouteActive)",
        "XCTAssertFalse(gate.routeGeometryMutationApplied)",
        "XCTAssertFalse(gate.trustedMetricsMutationApplied)",
        "XCTAssertFalse(gate.persistenceSchemaMutationApplied)",
    ])
    require("Shared/Models/SessionData.swift", ['static let currentDebugBuildTaskID = "Task-030c-b19"'])
    for loc in [
        "Shared/Localization/en.lproj/Localizable.strings",
        "Shared/Localization/ja.lproj/Localizable.strings",
        "Shared/Localization/zh-Hant.lproj/Localizable.strings",
    ]:
        require(loc, ['"debug.build.currentTaskID" = "Task-030c-b19";'])
    require("SkateTrack.xcodeproj/project.pbxproj", [
        "OutdoorLocalizationReleaseGate.swift in Sources",
        "OutdoorLocalizationReleaseGateBuilder.swift in Sources",
        "OutdoorLocalizationReleaseGateTests.swift in Sources",
    ])
    require("docs/planning/Task-030c-b19_Outdoor_Localization_Release_Gate_Mini_Plan_EN_v1.0.md", [
        "Task-030c-b19 Outdoor Localization Release Gate Mini Plan EN v1.0",
        "Outdoor Localization Release Gate",
        "releaseReady",
        "limitedDisclosure",
        "blocked",
        "estimatedRouteActive = false",
        "b19 does not enable estimated route display",
    ])
    require("docs/adr/ADR-INDEX.md", [
        "Task-030c-b19 — Outdoor Localization Release Gate",
        "OutdoorLocalizationReleaseGate",
        "General-user estimated route display remains disabled",
    ])
    require("docs/history/DEV_LOG.md", [
        "Task-030c-b19 — Outdoor Localization Release Gate",
        "OutdoorLocalizationReleaseGateBuilder",
        "estimatedRouteActive false",
    ])
    require("docs/reference/FILE_STRUCTURE.md", [
        "Task-030c-b19 outdoor localization release gate",
        "OutdoorLocalizationReleaseGate.swift",
        "OutdoorLocalizationReleaseGateBuilder.swift",
        "OutdoorLocalizationReleaseGateTests.swift",
        "verify_task030c_b19_outdoor_localization_release_gate.py",
    ])
    require("docs/release/KNOWN_LIMITATIONS_PRE_ADP.md", [
        "Task-030c-b19 — Outdoor Localization Release Gate",
        "does not enable estimated route display",
    ])
    require("docs/planning/Task-030c-b16_Localization_Foundation_Plan.md", [
        "Task-030c-b19 Implementation Note",
        "OutdoorLocalizationReleaseGate",
        "general-user estimated route display remains disabled",
    ])
    require("docs/planning/Task-030c-b18_Product_Decision_Checkpoint_and_Safety_Gated_Display_Plan_EN_v1.1.md", [
        "Current implementation baseline:** Task-030c-b19",
        "b19 implementation note",
        "OutdoorLocalizationReleaseGate",
        "General-user estimated route display remains disabled",
    ])

    require_first_line_marker("Shared/Models/OutdoorLocalizationReleaseGate.swift", "// [協作區] Shared/Models/OutdoorLocalizationReleaseGate.swift")
    require_first_line_marker("iOS/Core/SensorEngine/OutdoorLocalizationReleaseGateBuilder.swift", "// [自主區] iOS/Core/SensorEngine/OutdoorLocalizationReleaseGateBuilder.swift")
    require_first_line_marker("Tests/iOSTests/OutdoorLocalizationReleaseGateTests.swift", "// [自主區] Tests/iOSTests/OutdoorLocalizationReleaseGateTests.swift")
    for swift_file in [
        "Shared/Models/OutdoorLocalizationReleaseGate.swift",
        "iOS/Core/SensorEngine/OutdoorLocalizationReleaseGateBuilder.swift",
        "Tests/iOSTests/OutdoorLocalizationReleaseGateTests.swift",
    ]:
        require_swift_file_under_limit(swift_file)

    safety_guard_files = [
        "Shared/Models/OutdoorLocalizationReleaseGate.swift",
        "iOS/Core/SensorEngine/OutdoorLocalizationReleaseGateBuilder.swift",
        "Tests/iOSTests/OutdoorLocalizationReleaseGateTests.swift",
        "iOS/Core/SensorEngine/SensorFusionEngine.swift",
        "Shared/Models/MotionSample.swift",
    ]
    for rel in safety_guard_files:
        require_absent(rel, [
            "estimatedRouteActive: true",
            "generalUserEstimatedRouteDisplayAllowed = true",
            "estimatedRouteDisplayEnabled = true",
            "routeGeometryMutationApplied = true",
            "trustedMetricsMutationApplied = true",
            "persistenceSchemaMutationApplied = true",
        ])

    for rel in [
        "Shared/Persistence/SessionRepository.swift",
        "Shared/Persistence/SessionEntityMapper.swift",
        "Shared/Export/SkateTrackPackagePayload.swift",
        "iOS/Features/SessionSummary/SessionRouteMapView.swift",
    ]:
        if (ROOT / rel).exists():
            require_absent(rel, ["OutdoorLocalizationReleaseGate", "OutdoorLocalizationReleaseGateBuilder"])

    route_tokens = ["Map(", "MKMapView", "Polyline", "MKPolyline", "Canvas(", "Path("]
    for rel in [
        "Shared/Models/OutdoorLocalizationReleaseGate.swift",
        "iOS/Core/SensorEngine/OutdoorLocalizationReleaseGateBuilder.swift",
        "Tests/iOSTests/OutdoorLocalizationReleaseGateTests.swift",
    ]:
        require_absent(rel, route_tokens)

    print("Task-030c-b19 outdoor localization release gate checks passed.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"Task-030c-b19 check failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
