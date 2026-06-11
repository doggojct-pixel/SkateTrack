#!/usr/bin/env python3
"""Verify Task-018a/018b Session Summary foundation, route, safety, and share contracts."""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "iOS/Features/SessionSummary/SessionSummaryView.swift",
    "iOS/Features/SessionSummary/SessionSummaryMetricsGridView.swift",
    "iOS/Features/SessionSummary/SessionSummaryPlaceholderSectionView.swift",
    "iOS/Features/SessionSummary/SessionRouteMapView.swift",
    "iOS/Features/SessionSummary/SessionSummarySafetyStatusView.swift",
    "iOS/Features/SessionSummary/SessionSummaryShareStubView.swift",
    "iOS/Hooks/useSessionSummary.swift",
]

LOCALIZATION_KEYS = [
    "summary.title",
    "summary.subtitle",
    "summary.loading",
    "summary.error.title",
    "summary.error.generic",
    "summary.retry",
    "summary.close",
    "summary.metric.distance",
    "summary.metric.duration",
    "summary.metric.maxSpeed",
    "summary.metric.avgSpeed",
    "summary.metric.elevationGain",
    "summary.metric.movingRatio",
    "summary.metric.falls",
    "summary.metric.tricks",
    "summary.route.preview.title",
    "summary.route.preview.subtitle",
    "summary.route.map.title",
    "summary.route.map.subtitle",
    "summary.route.empty.title",
    "summary.route.empty.subtitle",
    "summary.route.empty.detail",
    "summary.route.start",
    "summary.route.finish",
    "summary.route.sampleCountFormat",
    "summary.safety.clear.title",
    "summary.safety.clear.subtitle",
    "summary.safety.falls.title",
    "summary.safety.falls.subtitleFormat",
    "summary.safety.metric.falls",
    "summary.safety.metric.impact",
    "summary.safety.metric.confirmed",
    "summary.safety.impactFormat",
    "summary.share.title",
    "summary.share.subtitle",
    "summary.share.button",
    "summary.share.stub.alert.title",
    "summary.share.stub.alert.message",
    "summary.share.stub.alert.dismiss",
    "summary.charts.placeholder.title",
    "summary.charts.placeholder.subtitle",
    "summary.health.placeholder.title",
    "summary.health.placeholder.subtitle",
]

PROJECT_TOKENS = [
    "SessionSummaryView.swift in Sources",
    "SessionSummaryMetricsGridView.swift in Sources",
    "SessionSummaryPlaceholderSectionView.swift in Sources",
    "SessionRouteMapView.swift in Sources",
    "SessionSummarySafetyStatusView.swift in Sources",
    "SessionSummaryShareStubView.swift in Sources",
    "useSessionSummary.swift in Sources",
    "iOS/Features/SessionSummary",
]

SOURCE_TOKENS = {
    "iOS/Hooks/useSessionSummary.swift": [
        "SessionSummaryViewModel",
        "SessionRepositoryProtocol",
        "fetchSession(id:",
        "loadMotionSamples(for:",
        "SessionSummaryContent",
        "SessionSummaryViewState",
    ],
    "iOS/Features/SessionSummary/SessionSummaryView.swift": [
        "SessionSummaryView",
        "useSessionSummary(sessionID:",
        "SessionSummaryMetricsGridView",
        "SessionRouteMapView",
        "SessionSummarySafetyStatusView",
        "SessionSummaryShareStubView",
        "summary.charts.placeholder.title",
        "summary.health.placeholder.title",
        "refreshable",
    ],
    "iOS/Features/SessionSummary/SessionSummaryMetricsGridView.swift": [
        "SessionSummaryMetricItem",
        "session-summary-metrics-grid",
    ],
    "iOS/Features/SessionSummary/SessionSummaryPlaceholderSectionView.swift": [
        "SessionSummaryPlaceholderSectionView",
        "session-summary-placeholder-section",
    ],
    "iOS/Features/SessionSummary/SessionRouteMapView.swift": [
        "import MapKit",
        "MapPolyline",
        "Annotation",
        "session-route-map-view",
        "session-route-map-empty",
    ],
    "iOS/Features/SessionSummary/SessionSummarySafetyStatusView.swift": [
        "SessionSummarySafetyStatusView",
        "FallEvent",
        "session-summary-safety-status",
    ],
    "iOS/Features/SessionSummary/SessionSummaryShareStubView.swift": [
        "SessionSummaryShareStubView",
        "summary.share.stub.alert.title",
        "session-summary-share-stub",
    ],
    "iOS/Features/SessionHistory/SessionHistoryView.swift": [
        "SessionSummaryView(sessionID:",
        "selectedSummarySession",
    ],
    "docs/DEV_LOG.md": [
        "Task-018b Route Map + Safety / Share Stub",
        "SessionRouteMapView",
    ],
    "docs/FILE_STRUCTURE.md": [
        "Task-018b Route Map + Safety / Share Stub",
        "SessionRouteMapView.swift",
        "verify_session_summary.py",
    ],
}

FORBIDDEN_TOKENS = [
    "import Charts",
    "AppStore.sync()",
    "Transaction.currentEntitlements",
    "Product.products(for:",
]

MAX_LINES = {
    "iOS/Features/SessionSummary/SessionSummaryView.swift": 360,
    "iOS/Features/SessionSummary/SessionSummaryMetricsGridView.swift": 180,
    "iOS/Features/SessionSummary/SessionSummaryPlaceholderSectionView.swift": 160,
    "iOS/Features/SessionSummary/SessionRouteMapView.swift": 260,
    "iOS/Features/SessionSummary/SessionSummarySafetyStatusView.swift": 220,
    "iOS/Features/SessionSummary/SessionSummaryShareStubView.swift": 180,
    "iOS/Hooks/useSessionSummary.swift": 240,
}


def fail(message: str) -> None:
    print(f"❌ {message}")
    sys.exit(1)


def read(relative: str) -> str:
    path = ROOT / relative
    if not path.exists():
        fail(f"Missing required file: {relative}")
    return path.read_text(encoding="utf-8")


def verify_files() -> None:
    for relative in REQUIRED_FILES:
        if not (ROOT / relative).exists():
            fail(f"Missing required file: {relative}")


def verify_line_counts() -> None:
    for relative, limit in MAX_LINES.items():
        count = len(read(relative).splitlines())
        if count > limit:
            fail(f"{relative} has {count} lines; limit is {limit}")


def verify_project_membership() -> None:
    project = read("SkateTrack.xcodeproj/project.pbxproj")
    for token in PROJECT_TOKENS:
        if token not in project:
            fail(f"Project file missing membership token: {token}")

    for filename in [Path(item).name for item in REQUIRED_FILES]:
        file_refs = len(re.findall(rf"/\* {re.escape(filename)} \*/ = {{isa = PBXFileReference;", project))
        build_files = len(re.findall(rf"/\* {re.escape(filename)} in Sources \*/ = {{isa = PBXBuildFile;", project))
        sources = len(re.findall(rf"/\* {re.escape(filename)} in Sources \*/,", project))
        if file_refs < 1:
            fail(f"Missing PBXFileReference for {filename}")
        if build_files < 1:
            fail(f"Missing PBXBuildFile for {filename}")
        if sources < 1:
            fail(f"Missing PBXSourcesBuildPhase entry for {filename}")


def verify_localization() -> None:
    for locale in ["en", "zh-Hant"]:
        text = read(f"Shared/Localization/{locale}.lproj/Localizable.strings")
        for key in LOCALIZATION_KEYS:
            if f'"{key}"' not in text:
                fail(f"Missing localization key {key} in {locale}")


def verify_source_contracts() -> None:
    for relative, tokens in SOURCE_TOKENS.items():
        text = read(relative)
        for token in tokens:
            if token not in text:
                fail(f"{relative} missing token: {token}")

    combined = "\n".join(read(relative) for relative in REQUIRED_FILES)
    for token in FORBIDDEN_TOKENS:
        if token in combined:
            fail(f"Task-018a must not add deferred feature token: {token}")

    summary_view = read("iOS/Features/SessionSummary/SessionSummaryView.swift")
    if "No fake health metrics are shown" in summary_view:
        fail("User-facing copy must stay in Localizable.strings, not raw Swift strings")


def main() -> None:
    verify_files()
    verify_line_counts()
    verify_project_membership()
    verify_localization()
    verify_source_contracts()
    print("✅ Task-018b Session Summary route map / safety verification passed")


if __name__ == "__main__":
    main()
