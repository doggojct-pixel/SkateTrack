#!/usr/bin/env python3
"""Verify Task-018a Session Summary Foundation contracts."""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "iOS/Features/SessionSummary/SessionSummaryView.swift",
    "iOS/Features/SessionSummary/SessionSummaryMetricsGridView.swift",
    "iOS/Features/SessionSummary/SessionSummaryPlaceholderSectionView.swift",
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
    "summary.route.empty.title",
    "summary.route.empty.subtitle",
    "summary.charts.placeholder.title",
    "summary.charts.placeholder.subtitle",
    "summary.health.placeholder.title",
    "summary.health.placeholder.subtitle",
]

PROJECT_TOKENS = [
    "SessionSummaryView.swift in Sources",
    "SessionSummaryMetricsGridView.swift in Sources",
    "SessionSummaryPlaceholderSectionView.swift in Sources",
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
        "SessionSummaryPlaceholderSectionView",
        "summary.route.preview.title",
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
    "iOS/Features/SessionHistory/SessionHistoryView.swift": [
        "SessionSummaryView(sessionID:",
        "selectedSummarySession",
    ],
    "docs/DEV_LOG.md": [
        "Task-018a Session Summary Foundation + Core Metrics",
        "SessionSummaryView",
    ],
    "docs/FILE_STRUCTURE.md": [
        "Task-018a Session Summary Foundation + Core Metrics",
        "iOS/Features/SessionSummary",
        "verify_session_summary.py",
    ],
}

FORBIDDEN_TOKENS = [
    "Map(",
    "import MapKit",
    "import Charts",
    "AppStore.sync()",
    "Transaction.currentEntitlements",
    "Product.products(for:",
]

MAX_LINES = {
    "iOS/Features/SessionSummary/SessionSummaryView.swift": 360,
    "iOS/Features/SessionSummary/SessionSummaryMetricsGridView.swift": 180,
    "iOS/Features/SessionSummary/SessionSummaryPlaceholderSectionView.swift": 160,
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
    print("✅ Task-018a Session Summary verification passed")


if __name__ == "__main__":
    main()
