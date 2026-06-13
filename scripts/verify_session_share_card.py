#!/usr/bin/env python3
"""Verify Task-023a Session Share Card preview foundation."""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "Shared/Models/SessionShareCardData.swift",
    "iOS/Hooks/useSessionShareCard.swift",
    "iOS/Features/SessionSummary/SessionShareCardPreviewView.swift",
    "iOS/Features/SessionSummary/SessionShareCardMetricView.swift",
    "iOS/Features/SessionSummary/SessionShareCardLockedView.swift",
    "iOS/Features/SessionSummary/SessionShareCardActionView.swift",
    "iOS/Features/SessionSummary/SessionSummaryShareStubView.swift",
]

PROJECT_TOKENS = [
    "SessionShareCardData.swift in Sources",
    "useSessionShareCard.swift in Sources",
    "SessionShareCardPreviewView.swift in Sources",
    "SessionShareCardMetricView.swift in Sources",
    "SessionShareCardLockedView.swift in Sources",
    "SessionShareCardActionView.swift in Sources",
    "SessionShareCardRenderer.swift in Sources",
    "SessionShareExportViewModel.swift in Sources",
    "SessionShareSheetView.swift in Sources",
    "SessionShareExportPayload.swift in Sources",
    "SessionShareExportService.swift in Sources",
]

LOCALIZATION_KEYS = [
    "summary.share.title",
    "summary.share.unlocked.subtitle",
    "summary.share.locked.sectionSubtitle",
    "summary.share.locked.title",
    "summary.share.locked.subtitle",
    "summary.share.card.eyebrow",
    "summary.share.brand",
    "summary.share.footer",
    "summary.share.spot",
    "summary.share.spot.none",
    "summary.share.equipment",
    "summary.share.equipment.none",
    "summary.share.route",
    "summary.share.route.available",
    "summary.share.route.unavailable",
    "summary.share.safety",
    "summary.share.safety.clear",
    "summary.share.safety.fallsFormat",
    "summary.share.action.title",
    "summary.share.action.subtitle",
    "summary.share.action.button",
    "summary.share.export.preparing",
    "summary.share.export.error.title",
    "summary.share.export.error.image",
    "summary.share.export.error.file",
    "summary.share.export.error.generic",
    "summary.share.export.error.dismiss",
    "summary.share.export.text.title",
    "summary.share.export.text.footer",
    "feature.session_share_card",
]

SOURCE_TOKENS = {
    "Shared/Models/SessionShareCardData.swift": [
        "struct SessionShareCardData",
        "Codable",
        "Sendable",
        "SessionShareCardMetricData",
        "SessionShareCardAccent",
    ],
    "iOS/Hooks/useSessionShareCard.swift": [
        "SessionShareCardViewModel",
        "func useSessionShareCard(content:",
        "UnitFormatter.distance",
        "routeStatusLocalizationKey",
        "safetyStatusText",
    ],
    "iOS/Features/SessionSummary/SessionSummaryShareStubView.swift": [
        "SessionSummaryShareStubView",
        "subscriptionStatus.hasAccess(to: .sessionShareCard)",
        "SessionShareCardPreviewView",
        "SessionShareCardLockedView",
        "SessionShareCardActionView",
        "session-summary-share-card-section",
    ],
    "iOS/Features/SessionSummary/SessionShareCardPreviewView.swift": [
        "SessionShareCardPreviewView",
        "SessionShareCardMetricView",
        "summary.share.card.eyebrow",
        "summary.share.footer",
        "session-share-card-preview",
    ],
    "iOS/Features/SessionSummary/SessionShareCardLockedView.swift": [
        "SessionShareCardLockedView",
        "LockedFeatureOverlayView",
        "feature: .sessionShareCard",
        "session-share-card-locked-view",
    ],
    "iOS/Features/SessionSummary/SessionShareCardActionView.swift": [
        "SessionShareCardActionView",
        "SessionShareExportViewModel",
        "summary.share.export.preparing",
        "session-share-card-action-view",
    ],
    "iOS/Features/SessionSummary/SessionSummaryView.swift": [
        "lockedFeature: .sessionShareCard",
        "SessionSummaryShareStubView(",
        "isShareCardPaywallPresented",
    ],
    "docs/history/DEV_LOG.md": [
        "Task-023b",
        "Quick Export",
    ],
    "docs/reference/FILE_STRUCTURE.md": [
        "Task-023b",
        "SessionShareCardPreviewView.swift",
        "SessionShareExportService.swift",
        "verify_session_share_export.py",
    ],
    "docs/adr/ADR-INDEX.md": [
        "Task-023b Confirmation",
        "GatedFeature.sessionShareCard",
    ],
}

FORBIDDEN_TOKENS = [
    "UIPasteboard",
    "PhotosUI",
    "PHPhotoLibrary",
    "URLSession",
    "AirDrop",
    "GoogleDrive",
    "WeatherKit",
    "AppStore.sync()",
    "Transaction.currentEntitlements",
]

MAX_LINES = {
    "Shared/Models/SessionShareCardData.swift": 160,
    "iOS/Hooks/useSessionShareCard.swift": 220,
    "iOS/Features/SessionSummary/SessionShareCardPreviewView.swift": 240,
    "iOS/Features/SessionSummary/SessionShareCardMetricView.swift": 120,
    "iOS/Features/SessionSummary/SessionShareCardLockedView.swift": 140,
    "iOS/Features/SessionSummary/SessionShareCardActionView.swift": 180,
    "iOS/Features/SessionSummary/SessionShareCardRenderer.swift": 120,
    "iOS/Features/SessionSummary/SessionShareExportViewModel.swift": 140,
    "iOS/Features/SessionSummary/SessionShareSheetView.swift": 100,
    "iOS/Core/SessionSharing/SessionShareExportPayload.swift": 120,
    "iOS/Core/SessionSharing/SessionShareExportService.swift": 220,
    "iOS/Features/SessionSummary/SessionSummaryShareStubView.swift": 160,
    "iOS/Features/SessionSummary/SessionSummaryView.swift": 360,
}


def fail(message: str) -> None:
    print(f"❌ {message}")
    sys.exit(1)


def read(relative: str) -> str:
    path = ROOT / relative
    if not path.exists():
        fail(f"Missing required file: {relative}")
    return path.read_text(encoding="utf-8")


def verify_required_files() -> None:
    for relative in REQUIRED_FILES:
        if not (ROOT / relative).exists():
            fail(f"Missing required file: {relative}")


def verify_project_membership() -> None:
    project = read("SkateTrack.xcodeproj/project.pbxproj")
    for token in PROJECT_TOKENS:
        if token not in project:
            fail(f"Project file missing token: {token}")

    for filename in [Path(item).name for item in REQUIRED_FILES]:
        file_refs = len(re.findall(rf"/\* {re.escape(filename)} \*/ = {{isa = PBXFileReference;", project))
        if file_refs < 1:
            fail(f"Missing PBXFileReference for {filename}")


def verify_localization() -> None:
    for locale in ["en", "zh-Hant"]:
        text = read(f"Shared/Localization/{locale}.lproj/Localizable.strings")
        for key in LOCALIZATION_KEYS:
            if f'"{key}"' not in text:
                fail(f"Missing localization key {key} in {locale}")


def verify_source_tokens() -> None:
    for relative, tokens in SOURCE_TOKENS.items():
        text = read(relative)
        for token in tokens:
            if token not in text:
                fail(f"{relative} missing token: {token}")


def verify_line_counts() -> None:
    for relative, limit in MAX_LINES.items():
        count = len(read(relative).splitlines())
        if count > limit:
            fail(f"{relative} has {count} lines; limit is {limit}")


def verify_scope_boundaries() -> None:
    combined = "\n".join(read(relative) for relative in REQUIRED_FILES)
    for token in FORBIDDEN_TOKENS:
        if token in combined:
            fail(f"Task-023a must not include export/share-system token: {token}")

    model = read("Shared/Models/SessionShareCardData.swift")
    for forbidden in ["SwiftUI", "UIKit", "MapKit", "CoreData"]:
        if f"import {forbidden}" in model:
            fail(f"Shared share-card model must not import {forbidden}")


def main() -> None:
    verify_required_files()
    verify_project_membership()
    verify_localization()
    verify_source_tokens()
    verify_line_counts()
    verify_scope_boundaries()
    print("✅ Task-023b Session Share Card preview/export verification passed")


if __name__ == "__main__":
    main()
