#!/usr/bin/env python3
"""Verify Task-030c-b18-C DEBUG-only estimated route review panel boundaries."""

from pathlib import Path
import re
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


def require_debug_wrapped_type(relative_path: str, type_token: str) -> None:
    text = read(relative_path)
    debug_index = text.find("#if DEBUG")
    type_index = text.find(type_token)
    endif_index = text.rfind("#endif")
    if debug_index == -1:
        raise AssertionError(f"{relative_path} must contain #if DEBUG")
    if type_index == -1:
        raise AssertionError(f"{relative_path} must contain {type_token}")
    if endif_index == -1:
        raise AssertionError(f"{relative_path} must end with #endif")
    if not (debug_index < type_index < endif_index):
        raise AssertionError(f"{type_token} must be fully inside #if DEBUG in {relative_path}")
    final_non_empty = [line.strip() for line in text.splitlines() if line.strip()][-1]
    if final_non_empty != "#endif":
        raise AssertionError(f"{relative_path} final non-empty line must be #endif")


def require_no_hardcoded_text_literals(relative_path: str) -> None:
    text = read(relative_path)
    forbidden = re.findall(r"\bText\(\s*\"", text)
    if forbidden:
        raise AssertionError(f"{relative_path} must not use hard-coded Text string literals")


def require_no_route_rendering(relative_path: str) -> None:
    text = read(relative_path)
    forbidden_patterns = [
        r"\bMap\s*\(",
        r"\bMKMapView\b",
        r"\bPolyline\b",
        r"\bMKPolyline\b",
        r"\bCanvas\s*\(",
        r"\bPath\s*\(",
    ]
    for pattern in forbidden_patterns:
        if re.search(pattern, text):
            raise AssertionError(f"{relative_path} must not render route/map geometry: {pattern}")


def require_localization_keys() -> None:
    keys = [
        "debug.estimatedRouteReview.title",
        "debug.estimatedRouteReview.subtitle",
        "debug.estimatedRouteReview.safetyFlags",
        "debug.estimatedRouteReview.routeGeometryDisabled",
        "debug.estimatedRouteReview.userVisibleDisplayDisabled",
        "debug.estimatedRouteReview.trustedMetricsDisabled",
        "debug.estimatedRouteReview.persistenceDisabled",
        "debug.estimatedRouteReview.records",
        "debug.estimatedRouteReview.empty",
        "debug.estimatedRouteReview.disposition",
        "debug.estimatedRouteReview.gapDuration",
        "debug.estimatedRouteReview.blockingReasons",
        "debug.estimatedRouteReview.recordUserVisibleDisabled",
    ]
    for loc in [
        "Shared/Localization/en.lproj/Localizable.strings",
        "Shared/Localization/zh-Hant.lproj/Localizable.strings",
        "Shared/Localization/ja.lproj/Localizable.strings",
    ]:
        require(loc, [f'"{key}" =' for key in keys])


def require_no_production_wiring() -> None:
    forbidden_tokens = ["EstimatedRouteReviewPanel", "useEstimatedRouteReview"]
    production_roots = [
        ROOT / "iOS/Features/SessionSummary",
        ROOT / "iOS/Features/SessionRecording",
        ROOT / "iOS/Hooks",
        ROOT / "iOS/Core/SessionRecording",
        ROOT / "Shared/Persistence",
        ROOT / "Shared/Export",
        ROOT / "iOS/Core/Export",
    ]
    for root in production_roots:
        if not root.exists():
            continue
        for path in root.rglob("*.swift"):
            if path.name == "useEstimatedRouteReview.swift":
                continue
            text = path.read_text(encoding="utf-8")
            for token in forbidden_tokens:
                if token in text:
                    raise AssertionError(f"Production file {path.relative_to(ROOT)} must not reference {token}")


def main() -> int:
    require("iOS/Features/Debug/EstimatedRouteReviewPanel.swift", [
        "#if DEBUG",
        "import SwiftUI",
        "struct EstimatedRouteReviewPanel: View",
        "let overlay: EstimatedRouteReviewOverlay",
        "debug.estimatedRouteReview.title",
        "debug.estimatedRouteReview.subtitle",
        "debug.estimatedRouteReview.safetyFlags",
        "debug.estimatedRouteReview.routeGeometryDisabled",
        "debug.estimatedRouteReview.userVisibleDisplayDisabled",
        "debug.estimatedRouteReview.trustedMetricsDisabled",
        "debug.estimatedRouteReview.persistenceDisabled",
        "debug.estimatedRouteReview.records",
        "debug.estimatedRouteReview.empty",
        "debug.estimatedRouteReview.disposition",
        "debug.estimatedRouteReview.gapDuration",
        "debug.estimatedRouteReview.blockingReasons",
        "debug.estimatedRouteReview.recordUserVisibleDisabled",
        "overlay.userVisibleDisplayAllowed",
        "overlay.routeGeometryIncluded",
        "overlay.trustedMetricsMutationApplied",
        "overlay.persistedOverlayApplied",
        "record.userVisibleDisplayAllowed",
    ])
    require("Tests/iOSTests/EstimatedRouteReviewPanelTests.swift", [
        "#if DEBUG",
        "final class EstimatedRouteReviewPanelTests",
        "testPanelCanBeCreatedForFiveRealSessionRegressionRoles",
        "testPanelInputKeepsAllSafetyFlagsDisabled",
        "testEmptyOverlayCanRenderLocalizedEmptyStatePath",
        "testMotorcycleControlCandidateRemainsHiddenInPanelInput",
        "electricSkateboardCoreCandidate",
        "walkingLowSpeedTrap",
        "surfskateShelteredHighRisk",
        "motorcyclePressureTest",
        "motorcycleControl",
        "XCTAssertFalse(overlay.userVisibleDisplayAllowed)",
        "XCTAssertFalse(overlay.routeGeometryIncluded)",
        "XCTAssertFalse(record.userVisibleDisplayAllowed)",
    ])
    require("Shared/Models/SessionData.swift", [
        'static let currentDebugBuildTaskID = "Task-030c-b18-C"',
    ])
    for loc in [
        "Shared/Localization/en.lproj/Localizable.strings",
        "Shared/Localization/zh-Hant.lproj/Localizable.strings",
        "Shared/Localization/ja.lproj/Localizable.strings",
    ]:
        require(loc, ['"debug.build.currentTaskID" = "Task-030c-b18-C";'])

    require("SkateTrack.xcodeproj/project.pbxproj", [
        "EstimatedRouteReviewPanel.swift in Sources",
        "EstimatedRouteReviewPanelTests.swift in Sources",
    ])
    require("docs/planning/Task-030c-b18-C_DEBUG_Review_Panel_Mini_Plan_EN_v1.1.md", [
        "Task-030c-b18-C DEBUG Review Panel Mini Plan EN v1.1",
        "Localization policy clarified",
        "Hook boundary clarified",
        "Verifier priority clarified",
        "Route rendering non-goal tightened",
        "the review panel must not render route polylines",
    ])
    require("docs/planning/Task-030c-b18_Product_Decision_Checkpoint_and_Safety_Gated_Display_Plan_EN_v1.1.md", [
        "Current implementation baseline:** Task-030c-b18-C",
        "b18-C implementation note",
        "DEBUG-only review panel",
        "must not render route polylines",
    ])
    require("docs/history/DEV_LOG.md", [
        "Task-030c-b18-C — DEBUG-Only Estimated Route Review Panel",
        "fully `#if DEBUG`-wrapped SwiftUI review panel",
        "No general-user estimated route display is enabled.",
    ])
    require("docs/adr/ADR-INDEX.md", [
        "Task-030c-b18-C — DEBUG-Only Estimated Route Review Panel",
        "The entire `EstimatedRouteReviewPanel` type is wrapped in `#if DEBUG`",
        "no route rendering",
    ])
    require("docs/reference/FILE_STRUCTURE.md", [
        "Task-030c-b18-C DEBUG-only estimated route review panel",
        "EstimatedRouteReviewPanel.swift",
        "verify_task030c_b18c_debug_review_panel.py",
    ])
    require("docs/release/KNOWN_LIMITATIONS_PRE_ADP.md", [
        "Task-030c-b18-C — DEBUG-Only Estimated Route Review Panel",
        "The panel does not render route polylines",
        "not reachable in release builds",
    ])

    require_first_line(
        "iOS/Features/Debug/EstimatedRouteReviewPanel.swift",
        "// [協作區] iOS/Features/Debug/EstimatedRouteReviewPanel.swift",
    )
    require_first_line(
        "Tests/iOSTests/EstimatedRouteReviewPanelTests.swift",
        "// [協作區] Tests/iOSTests/EstimatedRouteReviewPanelTests.swift",
    )
    for relative_path in [
        "iOS/Features/Debug/EstimatedRouteReviewPanel.swift",
        "Tests/iOSTests/EstimatedRouteReviewPanelTests.swift",
    ]:
        require_under_line_limit(relative_path)
        require_no_route_rendering(relative_path)

    require_debug_wrapped_type(
        "iOS/Features/Debug/EstimatedRouteReviewPanel.swift",
        "struct EstimatedRouteReviewPanel: View",
    )
    require_debug_wrapped_type(
        "Tests/iOSTests/EstimatedRouteReviewPanelTests.swift",
        "final class EstimatedRouteReviewPanelTests",
    )

    hook_path = ROOT / "iOS/Hooks/useEstimatedRouteReview.swift"
    if hook_path.exists():
        require_first_line(
            "iOS/Hooks/useEstimatedRouteReview.swift",
            "// [協作區] iOS/Hooks/useEstimatedRouteReview.swift",
        )
        require_debug_wrapped_type("iOS/Hooks/useEstimatedRouteReview.swift", "useEstimatedRouteReview")
        require_under_line_limit("iOS/Hooks/useEstimatedRouteReview.swift")
        require_no_route_rendering("iOS/Hooks/useEstimatedRouteReview.swift")

    require_no_hardcoded_text_literals("iOS/Features/Debug/EstimatedRouteReviewPanel.swift")
    require_localization_keys()
    require_no_production_wiring()

    production_forbidden = [
        "estimatedRouteActive: true",
        "productionRouteMutationApplied = true",
        "trustedMetricsMutationApplied = true",
        "estimatedRouteDisplayEnabled = true",
        "userVisibleDisplayAllowed = true",
        "normalSessionMapMutationApplied = true",
        "routeGeometryIncluded = true",
        "CLLocationManager",
        "trustedDistanceOverride",
        "roadSnapping",
        "mapMatching",
    ]
    for relative_path in [
        "iOS/Features/Debug/EstimatedRouteReviewPanel.swift",
        "Tests/iOSTests/EstimatedRouteReviewPanelTests.swift",
    ]:
        require_absent(relative_path, production_forbidden)

    for persistence_file in [
        "Shared/Persistence/SessionRepository.swift",
        "Shared/Persistence/SessionEntityMapper.swift",
        "Shared/Export/SkateTrackPackageExporter.swift",
        "iOS/Core/Export/SkateTrackPackageExportService.swift",
    ]:
        path = ROOT / persistence_file
        if path.exists():
            text = path.read_text(encoding="utf-8")
            if "EstimatedRouteReviewPanel" in text or "useEstimatedRouteReview" in text:
                raise AssertionError(f"{persistence_file} must not reference b18-C debug panel")

    print("Task-030c-b18-C DEBUG review panel checks passed.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"Task-030c-b18-C check failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
