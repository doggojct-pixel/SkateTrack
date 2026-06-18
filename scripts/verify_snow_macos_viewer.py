#!/usr/bin/env python3
"""Verify Snow-Task-007 macOS Snow viewer boundary guardrails."""
from __future__ import annotations

import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "macOS/Core/Snow/MacSnowAnalysisAvailability.swift",
    "macOS/Core/Snow/MacSnowSessionAnalysis.swift",
    "macOS/Core/Snow/MacSnowAnalysisViewModel.swift",
    "macOS/Core/Snow/MacSnowSessionAnalysisMapper.swift",
    "macOS/Core/Snow/MacSnowRouteFilter.swift",
    "macOS/Core/Snow/MacSnowMockAnalysisProvider.swift",
    "macOS/Features/Snow/MacSnowRootView.swift",
    "macOS/Features/Snow/MacSnowSessionBrowserView.swift",
    "macOS/Features/Snow/MacSnowDashboardView.swift",
    "macOS/Features/Snow/MacSnowRouteElevationView.swift",
    "macOS/Features/Snow/MacSnowVerticalDropChartView.swift",
    "macOS/Features/Snow/MacSnowSegmentTimelineView.swift",
    "macOS/Features/Snow/MacSnowSegmentInspectorView.swift",
    "macOS/Features/Snow/MacSnowDistanceInspectorView.swift",
    "macOS/Features/Snow/MacSnowUnavailableDataView.swift",
    "macOS/Features/Snow/MacSnowComponents.swift",
    "macOS/Features/Snow/MacSnowStyle.swift",
    "macOS/Features/Snow/MacSnowFormatters.swift",
    "scripts/create_snow_task007_review_pack.sh",
    "docs/process/PHASE_1C_SNOW_AGENT_STATE.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "docs/release/MANUAL_QA_MATRIX_PRE_ADP.md",
    "docs/DOCUMENTATION_INDEX.md",
]

REQUIRED_TOKENS = {
    "macOS/Core/Snow/MacSnowAnalysisAvailability.swift": [
        "enum MacSnowAnalysisSource",
        "case debugMock",
        "case coreDataRepository",
        "case importedPackage",
        "enum MacSnowAnalysisAvailability",
        "case available(MacSnowSessionAnalysis)",
        "case packageSchemaPending",
    ],
    "macOS/Core/Snow/MacSnowSessionAnalysis.swift": [
        "struct MacSnowSessionAnalysis",
        "let source: MacSnowAnalysisSource",
        "let distanceBreakdown: SnowDistanceBreakdown",
        "let verticalMetrics: SnowVerticalMetrics",
        "let motionSamples: [MotionSample]",
        "let hasLimitedAltitudeData: Bool",
        "struct MacSnowSegmentSelection",
        "struct MacSnowRoutePoint",
        "struct MacSnowElevationPoint",
    ],
    "macOS/Core/Snow/MacSnowAnalysisViewModel.swift": [
        "final class MacSnowAnalysisViewModel",
        "ObservableObject",
        "@Published private(set) var availability",
        "MacSnowMockAnalysisProvider",
        "#if DEBUG",
    ],
    "macOS/Core/Snow/MacSnowSessionAnalysisMapper.swift": [
        "enum MacSnowSessionAnalysisMapper",
        "SnowSessionState",
        "makePackageSchemaPending",
        "MacSnowRouteFilter.hasLimitedAltitudeData",
    ],
    "macOS/Core/Snow/MacSnowRouteFilter.swift": [
        "enum MacSnowRouteFilter",
        "routeSamples",
        "elevationPoints",
        "hasLimitedAltitudeData",
    ],
    "macOS/Core/Snow/MacSnowMockAnalysisProvider.swift": [
        "#if DEBUG",
        "enum MacSnowMockScenario",
        "enum MacSnowMockAnalysisProvider",
        "case limitedAltitude",
        "case packagePending",
    ],
    "macOS/Features/Snow/MacSnowRootView.swift": [
        "struct MacSnowRootView",
        "MacSnowDashboardView",
        "MacSnowRouteElevationView",
        "MacSnowSegmentTimelineView",
        "MacSnowSegmentInspectorView",
        "MacSnowDistanceInspectorView",
        "MacSnowUnavailableDataView",
    ],
    "macOS/Features/Snow/MacSnowDashboardView.swift": [
        "struct MacSnowDashboardView",
        "skiDistanceMeters",
        "liftDistanceMeters",
        "routeDistanceMeters",
        "hasLimitedAltitudeData",
    ],
    "macOS/Features/Snow/MacSnowRouteElevationView.swift": [
        "struct MacSnowRouteElevationView",
        "MacSnowRouteFilter.routeSamples",
        "MacSnowRoutePathView",
        "MacSnowVerticalDropChartView",
    ],
    "macOS/Features/Snow/MacSnowVerticalDropChartView.swift": [
        "struct MacSnowVerticalDropChartView",
        "hasLimitedAltitudeData",
        "mac.snow.elevation.limited",
    ],
    "macOS/Features/Snow/MacSnowSegmentTimelineView.swift": [
        "struct MacSnowSegmentTimelineView",
        "selectedSegmentID",
        "MacSnowSegmentTimelineRow",
    ],
    "macOS/Features/Snow/MacSnowSegmentInspectorView.swift": [
        "struct MacSnowSegmentInspectorView",
        "manual_placeholder",
        "confidence",
        "altitude_delta",
    ],
    "macOS/Features/Snow/MacSnowDistanceInspectorView.swift": [
        "struct MacSnowDistanceInspectorView",
        "skiDistanceMeters",
        "liftDistanceMeters",
        "routeDistanceMeters",
        "unknownDistanceMeters",
    ],
    "macOS/Features/Snow/MacSnowUnavailableDataView.swift": [
        "struct MacSnowUnavailableDataView",
        "packageSchemaPending",
        "mac.snow.unavailable.package_schema_pending",
    ],
    "macOS/Features/Snow/MacSnowComponents.swift": [
        "struct MacSnowSection",
        "struct MacSnowMetricTile",
        "struct MacSnowStatusPill",
    ],
    "macOS/Features/Snow/MacSnowStyle.swift": [
        "enum MacSnowStyle",
        "static let ice",
        "auroraGradient",
        "panelGradient",
        "selectedRowGradient",
        "mapGradient",
        "segmentColor",
    ],
    "macOS/Features/Snow/MacSnowFormatters.swift": [
        "enum MacSnowFormatters",
        "distanceKilometers",
        "speedKmh",
    ],
    "scripts/create_snow_task007_review_pack.sh": [
        "SnowTask007_ReviewPack",
        "MacSnowSessionAnalysis is a struct",
        "packageSchemaPending",
        "SAFETY_CHECK_PACKAGE_SCHEMA_MODIFIED_IN_TASK007.txt",
        "SAFETY_CHECK_DEBUG_MOCK_GATING.txt",
    ],
    "docs/process/PHASE_1C_SNOW_AGENT_STATE.md": [
        "Snow-Task-007 macOS Snow Viewer State",
        "MacSnowSessionAnalysis` is a struct",
        "packageSchemaPending",
        "Snow-Task-008",
    ],
    "docs/reference/FILE_STRUCTURE.md": [
        "Snow-Task-007 macOS Snow Viewer Files",
        "macOS/Core/Snow/MacSnowSessionAnalysis.swift",
        "macOS/Features/Snow/MacSnowRootView.swift",
        "scripts/create_snow_task007_review_pack.sh",
    ],
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
        "Snow-Task-007 macOS Snow Viewer v0 limitations",
        "packageSchemaPending",
        "Snow-Task-008",
    ],
    "docs/release/MANUAL_QA_MATRIX_PRE_ADP.md": [
        "Phase 1c Snow Mode macOS viewer smoke test",
        "Snow Analysis Preview",
        "macOS Snow viewer smoke test complete",
    ],
    "docs/DOCUMENTATION_INDEX.md": [
        "Snow-Task-007 macOS Snow viewer",
        "verify_snow_macos_viewer.py",
        "read-only macOS Snow viewer",
    ],
}

FORBIDDEN_TOKENS = [
    "SnowPrototype",
    "MacSnowPrototype",
    "Shared/PreviewData/SnowPrototype",
    "WatchConnectivity",
    "WCSession",
    "WatchBridge",
    "WatchSessionCoordinator",
    "HealthKit",
    "WeatherKit",
    "CloudKit",
    "CoreLocation",
    "CLLocationManager",
    "SnowSessionRepository.save",
    "NSManagedObjectContext",
]

FORBIDDEN_CHANGED_PREFIXES = [
    "Shared/Models/SkateTrackPackageManifest.swift",
    "Shared/Models/SkateTrackPackagePayload.swift",
    "Shared/Export/SkateTrackPackageReader.swift",
    "Shared/Export/SkateTrackPackageWriter.swift",
    "Shared/Models/BackupPackageManifest.swift",
    "Shared/Models/BackupPackagePayload.swift",
    "Shared/Persistence/",
    "Shared/WatchBridge/",
    "iOS/",
    "watchOS/",
]

FORBIDDEN_CHANGED_FILES = [
    "Shared/Models/MotionSample.swift",
    "Shared/Models/SnowRun.swift",
    "Shared/Models/SnowSegment.swift",
    "Shared/Models/SnowDistanceBreakdown.swift",
    "Shared/Models/SnowVerticalMetrics.swift",
    "Shared/Models/SnowSessionState.swift",
]

# Snow-Task-007 originally blocked package/export/iOS paths to keep the
# read-only macOS viewer task from drifting into Snow package compatibility.
# Snow-Task-008a is the explicitly approved package-compatibility task, so
# these exact paths are allowed to be modified while the 007 feature checks
# continue to run as cumulative regression guardrails.
POST_007_ALLOWED_TASK008A_CHANGED_PATHS = {
    "Shared/Models/SkateTrackPackageManifest.swift",
    "Shared/Models/SkateTrackPackagePayload.swift",
    "Shared/Models/SkateTrackPackageSnowPayload.swift",
    "Shared/Export/SkateTrackPackageReader.swift",
    "Shared/Export/SkateTrackPackageWriter.swift",
    "iOS/Core/Export/SkateTrackPackageExportProvider.swift",
    "iOS/Hooks/useSkateTrackPackageExport.swift",
    "iOS/Features/SessionSummary/SessionPackageExportActionView.swift",
    "macOS/Core/Snow/MacSnowSessionAnalysisMapper.swift",
    "macOS/Features/Import/MacPackageImportViewModel.swift",
    "macOS/Features/Import/MacPackagePreviewView.swift",
    "Tests/iOSTests/SkateTrackPackageSnowCompatibilityTests.swift",
    "scripts/verify_snow_package_compatibility.py",
}

PROJECT_TOKENS = [
    "MacSnowAnalysisAvailability.swift",
    "MacSnowSessionAnalysis.swift",
    "MacSnowAnalysisViewModel.swift",
    "MacSnowSessionAnalysisMapper.swift",
    "MacSnowRouteFilter.swift",
    "MacSnowMockAnalysisProvider.swift",
    "MacSnowRootView.swift",
    "MacSnowSessionBrowserView.swift",
    "MacSnowDashboardView.swift",
    "MacSnowRouteElevationView.swift",
    "MacSnowVerticalDropChartView.swift",
    "MacSnowSegmentTimelineView.swift",
    "MacSnowSegmentInspectorView.swift",
    "MacSnowDistanceInspectorView.swift",
    "MacSnowUnavailableDataView.swift",
    "MacSnowComponents.swift",
    "MacSnowStyle.swift",
    "MacSnowFormatters.swift",
    "MacSnowAnalysisAvailability.swift in Sources",
    "MacSnowSessionAnalysis.swift in Sources",
    "MacSnowAnalysisViewModel.swift in Sources",
    "MacSnowSessionAnalysisMapper.swift in Sources",
    "MacSnowRouteFilter.swift in Sources",
    "MacSnowMockAnalysisProvider.swift in Sources",
    "MacSnowRootView.swift in Sources",
    "MacSnowSessionBrowserView.swift in Sources",
    "MacSnowDashboardView.swift in Sources",
    "MacSnowRouteElevationView.swift in Sources",
    "MacSnowVerticalDropChartView.swift in Sources",
    "MacSnowSegmentTimelineView.swift in Sources",
    "MacSnowSegmentInspectorView.swift in Sources",
    "MacSnowDistanceInspectorView.swift in Sources",
    "MacSnowUnavailableDataView.swift in Sources",
    "MacSnowComponents.swift in Sources",
    "MacSnowStyle.swift in Sources",
    "MacSnowFormatters.swift in Sources",
]


MAC_ROOT_TOKENS = [
    "case snowAnalysisPreview",
    "MacSnowDebugPreviewContainer",
    "loadMockScenario(.resortDay)",
    "mac.snow.sidebar.debug_preview",
]

LOCALIZATION_KEYS = [
    "mac.snow.sidebar.debug_preview",
    "mac.snow.sidebar.debug_preview.subtitle",
    "mac.snow.dashboard.title",
    "mac.snow.dashboard.subtitle",
    "mac.snow.metric.runs",
    "mac.snow.metric.ski_distance",
    "mac.snow.metric.lift_distance",
    "mac.snow.metric.route_distance",
    "mac.snow.metric.vertical_drop",
    "mac.snow.metric.top_speed",
    "mac.snow.route.title",
    "mac.snow.elevation.limited",
    "mac.snow.timeline.title",
    "mac.snow.inspector.title",
    "mac.snow.distance.title",
    "mac.snow.unavailable.package_schema_pending",
    "mac.snow.guardrail.read_only",
    "mac.snow.guardrail.debug_mock",
]


def fail(message: str) -> None:
    raise SystemExit(f"[snow-task-007] FAIL: {message}")


def read(path: str) -> str:
    file_path = ROOT / path
    if not file_path.exists():
        fail(f"missing required file: {path}")
    return file_path.read_text(encoding="utf-8")


def git_changed_files() -> list[str]:
    result = subprocess.run(
        ["git", "-C", str(ROOT), "diff", "--name-only", "HEAD"],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        fail("unable to inspect git diff against HEAD")
    return [line.strip() for line in result.stdout.splitlines() if line.strip()]


def main() -> None:
    for path in REQUIRED_FILES:
        read(path)

    for path, tokens in REQUIRED_TOKENS.items():
        content = read(path)
        for token in tokens:
            if token not in content:
                fail(f"{path} missing token: {token}")

    analysis_content = read("macOS/Core/Snow/MacSnowSessionAnalysis.swift")
    if "struct MacSnowSessionAnalysis" not in analysis_content:
        fail("MacSnowSessionAnalysis must be a struct")
    if "class MacSnowSessionAnalysis" in analysis_content:
        fail("MacSnowSessionAnalysis must not be a class")

    production_source_paths = [
        path for path in REQUIRED_FILES
        if path.startswith("macOS/Core/Snow/")
        or path.startswith("macOS/Features/Snow/")
        or path == "macOS/App/MacRootView.swift"
    ]
    for path in production_source_paths:
        content = read(path)
        for token in FORBIDDEN_TOKENS:
            if token in content:
                fail(f"forbidden token '{token}' found in {path}")

    mock_content = read("macOS/Core/Snow/MacSnowMockAnalysisProvider.swift")
    if not mock_content.lstrip().startswith("//") or "#if DEBUG" not in mock_content:
        fail("MacSnowMockAnalysisProvider must be DEBUG-gated")

    changed = git_changed_files()
    for path in changed:
        if path in POST_007_ALLOWED_TASK008A_CHANGED_PATHS:
            continue
        if path in FORBIDDEN_CHANGED_FILES:
            fail(f"forbidden Snow value type modified in Task-007: {path}")
        for prefix in FORBIDDEN_CHANGED_PREFIXES:
            if path.startswith(prefix):
                fail(f"forbidden path modified in Task-007: {path}")
        if path.endswith(".skatetrack"):
            fail(f".skatetrack sample files are forbidden: {path}")

    project = read("SkateTrack.xcodeproj/project.pbxproj")
    for token in PROJECT_TOKENS:
        if token not in project:
            fail(f"project membership missing token: {token}")

    mac_root = read("macOS/App/MacRootView.swift")
    for token in MAC_ROOT_TOKENS:
        if token not in mac_root:
            fail(f"MacRootView missing DEBUG Snow integration token: {token}")
    if "case snowAnalysisPreview" in mac_root and "#if DEBUG" not in mac_root:
        fail("Snow Analysis Preview must remain DEBUG-gated")

    for locale in ["en", "zh-Hant", "ja"]:
        localization = read(f"Shared/Localization/{locale}.lproj/Localizable.strings")
        for key in LOCALIZATION_KEYS:
            if f'"{key}"' not in localization:
                fail(f"missing localization key {key} in {locale}")

    print(
        "[snow-task-007] PASS: macOS Snow analysis data boundary, "
        "struct-based presentation model, DEBUG mock provider, core viewer UI views, "
        "DEBUG MacRootView integration, localization, route/elevation filtering, "
        "documentation, review-pack script, project membership, and post-007 Task-008a package guardrails are present."
    )


if __name__ == "__main__":
    main()
