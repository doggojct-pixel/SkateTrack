#!/usr/bin/env python3
"""Verify Task-023b local share-card export and share-sheet boundaries."""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "iOS/Core/SessionSharing/SessionShareExportPayload.swift",
    "iOS/Core/SessionSharing/SessionShareExportService.swift",
    "iOS/Features/SessionSummary/SessionShareCardRenderer.swift",
    "iOS/Features/SessionSummary/SessionShareExportViewModel.swift",
    "iOS/Features/SessionSummary/SessionShareSheetView.swift",
    "iOS/Features/SessionSummary/SessionShareCardActionView.swift",
]

PROJECT_TOKENS = [
    "iOS/Core/SessionSharing",
    "SessionShareExportPayload.swift in Sources",
    "SessionShareExportService.swift in Sources",
    "SessionShareCardRenderer.swift in Sources",
    "SessionShareExportViewModel.swift in Sources",
    "SessionShareSheetView.swift in Sources",
]

LOCALIZATION_KEYS = [
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
]

SOURCE_TOKENS = {
    "iOS/Core/SessionSharing/SessionShareExportPayload.swift": [
        "SessionShareExportPayload",
        "directoryURL",
        "imageURL",
        "textURL",
        "jsonURL",
        "itemURLs",
    ],
    "iOS/Core/SessionSharing/SessionShareExportService.swift": [
        "SessionShareExportService",
        "FileManager = .default",
        "temporaryDirectory",
        "SkateTrackShare",
        "skatetrack-share-card.png",
        "skatetrack-summary.txt",
        "skatetrack-summary.json",
        "cleanup(_ payload:",
    ],
    "iOS/Features/SessionSummary/SessionShareCardRenderer.swift": [
        "ImageRenderer",
        "SessionShareCardPreviewView",
        "pngData()",
        "UIScreen.main.scale",
    ],
    "iOS/Features/SessionSummary/SessionShareExportViewModel.swift": [
        "SessionShareExportViewModel",
        "prepareShare(card:",
        "cleanupActivePayload",
        "SessionShareCardRenderer",
        "SessionShareExportService",
    ],
    "iOS/Features/SessionSummary/SessionShareSheetView.swift": [
        "UIActivityViewController",
        "UIViewControllerRepresentable",
        "completionWithItemsHandler",
        "itemURLs",
    ],
    "iOS/Features/SessionSummary/SessionShareCardActionView.swift": [
        "SessionShareExportViewModel",
        "prepareShare(card: card)",
        "SessionShareSheetView",
        "summary.share.export.preparing",
        "session-share-card-action-view",
    ],
    "docs/DEV_LOG.md": [
        "Task-023b",
        "Quick Export",
    ],
    "docs/FILE_STRUCTURE.md": [
        "Task-023b",
        "SessionShareExportService.swift",
        "SessionShareSheetView.swift",
    ],
    "docs/decisions/ADR-0001-subscription-entitlement-strategy.md": [
        "Task-023b Confirmation",
        "GatedFeature.sessionShareCard",
    ],
}

MAX_LINES = {
    "iOS/Core/SessionSharing/SessionShareExportPayload.swift": 120,
    "iOS/Core/SessionSharing/SessionShareExportService.swift": 220,
    "iOS/Features/SessionSummary/SessionShareCardRenderer.swift": 120,
    "iOS/Features/SessionSummary/SessionShareExportViewModel.swift": 140,
    "iOS/Features/SessionSummary/SessionShareSheetView.swift": 100,
    "iOS/Features/SessionSummary/SessionShareCardActionView.swift": 180,
}

FORBIDDEN_ANYWHERE = [
    "PHPhotoLibrary",
    "PhotosUI",
    "UIImageWriteToSavedPhotosAlbum",
    "URLSession",
    "GoogleDrive",
    "CloudKit",
    "CKContainer",
    "AppStore.sync()",
    "Transaction.currentEntitlements",
    "DEVELOPMENT_TEAM",
    "PROVISIONING_PROFILE",
    "SessionShareCardRenderer = SessionShareCardRenderer()",
]

ALLOWED_TOKEN_FILES = {
    "ImageRenderer": ["iOS/Features/SessionSummary/SessionShareCardRenderer.swift"],
    "UIActivityViewController": ["iOS/Features/SessionSummary/SessionShareSheetView.swift"],
    "temporaryDirectory": ["iOS/Core/SessionSharing/SessionShareExportService.swift"],
    "FileManager = .default": ["iOS/Core/SessionSharing/SessionShareExportService.swift"],
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


def verify_project() -> None:
    project = read("SkateTrack.xcodeproj/project.pbxproj")
    for token in PROJECT_TOKENS:
        if token not in project:
            fail(f"Project file missing token: {token}")
    for filename in [Path(item).name for item in REQUIRED_FILES]:
        if len(re.findall(rf"/\* {re.escape(filename)} \*/ = {{isa = PBXFileReference;", project)) < 1:
            fail(f"Missing PBXFileReference for {filename}")
        if len(re.findall(rf"/\* {re.escape(filename)} in Sources \*/ = {{isa = PBXBuildFile;", project)) < 1:
            fail(f"Missing PBXBuildFile for {filename}")


def verify_localization() -> None:
    for locale in ["en", "zh-Hant"]:
        text = read(f"Shared/Localization/{locale}.lproj/Localizable.strings")
        for key in LOCALIZATION_KEYS:
            if f'"{key}"' not in text:
                fail(f"Missing localization key {key} in {locale}")


def verify_sources() -> None:
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


def verify_boundaries() -> None:
    for relative in REQUIRED_FILES:
        text = read(relative)
        for token in FORBIDDEN_ANYWHERE:
            if token in text:
                fail(f"Forbidden token {token} found in {relative}")
        for token, allowed_files in ALLOWED_TOKEN_FILES.items():
            if token in text and relative not in allowed_files:
                fail(f"Token {token} is only allowed in {allowed_files}, found in {relative}")


def main() -> None:
    verify_files()
    verify_project()
    verify_localization()
    verify_sources()
    verify_line_counts()
    verify_boundaries()
    print("✅ Task-023b Session Share Export verification passed")


if __name__ == "__main__":
    main()
