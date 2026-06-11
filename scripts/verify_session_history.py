#!/usr/bin/env python3
"""Verify Task-017a/017b Session History, free-limit, and Summary handoff contracts."""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "iOS/Features/SessionHistory/SessionHistoryView.swift",
    "iOS/Features/SessionHistory/SessionHistoryListView.swift",
    "iOS/Features/SessionHistory/SessionHistoryCardView.swift",
    "iOS/Features/SessionHistory/SessionHistoryFilterBar.swift",
    "iOS/Features/SessionHistory/HistoryLimitPaywallBanner.swift",
    "iOS/Features/SessionHistory/SessionSummaryHandoffView.swift",
    "iOS/Hooks/useSessionHistory.swift",
]

LOCALIZATION_KEYS = [
    "root.nav.ride",
    "history.title",
    "history.subtitle",
    "history.thisWeek",
    "history.totalDistance",
    "history.totalSessions",
    "history.allTime",
    "history.filter.all",
    "history.filter.skate",
    "history.filter.inline",
    "history.filter.electric",
    "history.empty.title",
    "history.empty.subtitle",
    "history.filtered.empty.title",
    "history.filtered.empty.subtitle",
    "history.loading",
    "history.error.title",
    "history.error.generic",
    "history.retry",
    "history.limit.title",
    "history.limit.subtitleFormat",
    "history.limit.cta",
    "history.card.distance",
    "history.card.maxSpeed",
    "history.card.duration",
    "history.card.locked",
    "history.summary.placeholder.title",
    "history.summary.placeholder.subtitle",
    "history.summary.placeholder.close",
    "history.summary.handoff.title",
    "history.summary.handoff.subtitle",
    "history.summary.handoff.distance",
    "history.summary.handoff.maxSpeed",
    "history.summary.handoff.duration",
    "history.summary.handoff.avgSpeed",
    "history.summary.handoff.nextTaskTitle",
    "history.summary.handoff.nextTaskSubtitle",
    "history.summary.handoff.close",
]

PROJECT_TOKENS = [
    "SessionHistoryView.swift in Sources",
    "SessionHistoryListView.swift in Sources",
    "SessionHistoryCardView.swift in Sources",
    "SessionHistoryFilterBar.swift in Sources",
    "HistoryLimitPaywallBanner.swift in Sources",
    "SessionSummaryHandoffView.swift in Sources",
    "useSessionHistory.swift in Sources",
    "iOS/Features/SessionHistory",
]

SOURCE_TOKENS = {
    "iOS/Hooks/useSessionHistory.swift": [
        "SessionHistoryViewModel",
        "SessionRepositoryProtocol",
        "fetchRecentSessions(limit:",
        "freeAccessibleSessionCount = 5",
        "SessionHistoryFilter",
        "groupedSections(isSubscriber:",
        "lockedSessionCount(isSubscriber:",
    ],
    "iOS/Features/SessionHistory/SessionHistoryView.swift": [
        "SessionHistoryView",
        "SubscriptionPaywallView",
        "lockedFeature: .unlimitedHistory",
        "HistoryLimitPaywallBanner",
        "SessionHistoryFilterBar",
        "SessionHistoryListView",
        "SessionSummaryView(",
        "refreshable",
        "history.loadIfNeeded()",
    ],

    "iOS/Features/SessionHistory/SessionSummaryHandoffView.swift": [
        "SessionSummaryHandoffView",
        "Task-018",
        "history.summary.handoff.title",
        "history.summary.handoff.nextTaskTitle",
        "session-summary-handoff-view",
    ],
    "iOS/App/RootNavigationView.swift": [
        "RootPrimaryScreen",
        "SessionHistoryView(subscriptionStatus:",
        "rootPrimarySwitch",
        "history.title",
    ],
    "docs/decisions/ADR-0001-subscription-entitlement-strategy.md": [
        "Project-wide paid feature rule after Task-017a",
        "Task-017a therefore implements the free 5-session History limit",
        "AppStoreSubscriptionProvider",
    ],
    "docs/DEV_LOG.md": [
        "Task-017a Session History Foundation + Free Limit",
        "Task-017b History Navigation + Summary Handoff",
        "free 5-session History limit",
    ],
    "docs/FILE_STRUCTURE.md": [
        "Task-017a Session History Foundation + Free Limit",
        "Task-017b History Navigation + Summary Handoff",
        "SessionHistory/",
        "SessionSummaryHandoffView.swift",
        "SessionSummary/",
        "verify_session_history.py",
    ],
}

FORBIDDEN_TOKENS = [
    "AppStore.sync()",
    "Transaction.currentEntitlements",
    "Product.products(for:",
    "SKPaymentQueue",
]

MAX_LINES = {
    "iOS/Features/SessionHistory/SessionHistoryView.swift": 380,
    "iOS/Features/SessionHistory/SessionHistoryListView.swift": 280,
    "iOS/Features/SessionHistory/SessionHistoryCardView.swift": 200,
    "iOS/Features/SessionHistory/SessionHistoryFilterBar.swift": 180,
    "iOS/Features/SessionHistory/HistoryLimitPaywallBanner.swift": 180,
    "iOS/Features/SessionHistory/SessionSummaryHandoffView.swift": 260,
    "iOS/Hooks/useSessionHistory.swift": 350,
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
        path = ROOT / relative
        if not path.exists():
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
            fail(f"Task-017a must not add real StoreKit production token: {token}")

    history_view = read("iOS/Features/SessionHistory/SessionHistoryView.swift")
    if "subscriptionStatus.isSubscriber" not in history_view:
        fail("History view must consume useSubscriptionStatus subscriber state")
    if "setDebugSubscriptionOverride" in history_view:
        fail("History view must not hardcode DEBUG subscriber override")


def main() -> None:
    verify_files()
    verify_line_counts()
    verify_project_membership()
    verify_localization()
    verify_source_contracts()
    print("✅ Task-017a/017b Session History verification passed")


if __name__ == "__main__":
    main()
