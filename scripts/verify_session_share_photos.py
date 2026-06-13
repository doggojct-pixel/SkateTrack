#!/usr/bin/env python3
"""Verify Task-023c save-to-Photos boundary and export-scope documentation."""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "iOS/Core/SessionSharing/SessionSharePhotoLibrarySaver.swift",
    "iOS/Features/SessionSummary/SessionSharePhotoSaveState.swift",
    "iOS/Features/SessionSummary/SessionShareExportViewModel.swift",
    "iOS/Features/SessionSummary/SessionShareCardActionView.swift",
    "docs/adr/ADR-INDEX.md",
]

PROJECT_TOKENS = [
    "SessionSharePhotoLibrarySaver.swift in Sources",
    "SessionSharePhotoSaveState.swift in Sources",
    "INFOPLIST_KEY_NSPhotoLibraryAddUsageDescription",
]

LOCALIZATION_KEYS = [
    "summary.share.photos.button",
    "summary.share.photos.saving",
    "summary.share.photos.success",
    "summary.share.photos.error.permission",
    "summary.share.photos.error.save",
]

INFO_PLIST_KEY = "NSPhotoLibraryAddUsageDescription"

SOURCE_TOKENS = {
    "iOS/Core/SessionSharing/SessionSharePhotoLibrarySaver.swift": [
        "import Photos",
        "PHPhotoLibrary.requestAuthorization(for: .addOnly)",
        "PHPhotoLibrary.authorizationStatus(for: .addOnly)",
        "PHPhotoLibrary.shared().performChanges",
        "PHAssetChangeRequest.creationRequestForAsset",
        "SessionSharePhotoLibraryError",
    ],
    "iOS/Features/SessionSummary/SessionSharePhotoSaveState.swift": [
        "enum SessionSharePhotoSaveState",
        "case saving",
        "case saved",
        "case failed(String)",
        "summary.share.photos.success",
    ],
    "iOS/Features/SessionSummary/SessionShareExportViewModel.swift": [
        "SessionSharePhotoLibrarySaver",
        "photoSaveState",
        "saveCardToPhotos(card:",
        "resetPhotoSaveState",
    ],
    "iOS/Features/SessionSummary/SessionShareCardActionView.swift": [
        "summary.share.photos.button",
        "saveCardToPhotos(card: card)",
        "session-share-photo-save-status",
    ],
    "docs/adr/ADR-INDEX.md": [
        "Task-023c",
        "Task-027",
        "AirDrop-specific package",
        "portable archive",
        "NSPhotoLibraryAddUsageDescription",
    ],
    "docs/history/DEV_LOG.md": [
        "Task-023c",
        "Save Share Card to Photos",
        "ADR-0004",
    ],
    "docs/reference/FILE_STRUCTURE.md": [
        "Task-023c",
        "SessionSharePhotoLibrarySaver.swift",
        "ADR-0004",
    ],
    "docs/adr/ADR-INDEX.md": [
        "Task-023c Confirmation",
        "GatedFeature.sessionShareCard",
    ],
}

MAX_LINES = {
    "iOS/Core/SessionSharing/SessionSharePhotoLibrarySaver.swift": 140,
    "iOS/Features/SessionSummary/SessionSharePhotoSaveState.swift": 80,
    "iOS/Features/SessionSummary/SessionShareExportViewModel.swift": 160,
    "iOS/Features/SessionSummary/SessionShareCardActionView.swift": 200,
}

FORBIDDEN_ANYWHERE = [
    "UIImageWriteToSavedPhotosAlbum",
    "NSPhotoLibraryUsageDescription",
    "PhotosUI",
    "URLSession",
    "GoogleDrive",
    "CloudKit",
    "CKContainer",
    "AppStore.sync()",
    "Transaction.currentEntitlements",
]

ALLOWED_TOKEN_FILES = {
    "import Photos": ["iOS/Core/SessionSharing/SessionSharePhotoLibrarySaver.swift"],
    "PHPhotoLibrary": ["iOS/Core/SessionSharing/SessionSharePhotoLibrarySaver.swift"],
    "PHAssetChangeRequest": ["iOS/Core/SessionSharing/SessionSharePhotoLibrarySaver.swift"],
}


def fail(message: str) -> None:
    print(f"❌ {message}")
    sys.exit(1)


def read(relative: str) -> str:
    path = ROOT / relative
    if not path.exists():
        fail(f"Missing required file: {relative}")
    return path.read_text(encoding="utf-8")


def relevant_swift_files() -> list[Path]:
    return [
        ROOT / "iOS/Core/SessionSharing/SessionSharePhotoLibrarySaver.swift",
        ROOT / "iOS/Features/SessionSummary/SessionSharePhotoSaveState.swift",
        ROOT / "iOS/Features/SessionSummary/SessionShareExportViewModel.swift",
        ROOT / "iOS/Features/SessionSummary/SessionShareCardActionView.swift",
    ]


def verify_files() -> None:
    for relative in REQUIRED_FILES:
        if not (ROOT / relative).exists():
            fail(f"Missing required file: {relative}")


def verify_project() -> None:
    project = read("SkateTrack.xcodeproj/project.pbxproj")
    for token in PROJECT_TOKENS:
        if token not in project:
            fail(f"Project file missing token: {token}")
    if "INFOPLIST_KEY_NSPhotoLibraryUsageDescription" in project:
        fail("Project should use add-only Photos permission, not full photo-library usage description")
    for filename in [Path(item).name for item in REQUIRED_FILES if item.endswith(".swift")]:
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
        info = read(f"Shared/Localization/{locale}.lproj/InfoPlist.strings")
        if INFO_PLIST_KEY not in info:
            fail(f"Missing {INFO_PLIST_KEY} in {locale} InfoPlist.strings")
        if "NSPhotoLibraryUsageDescription" in info:
            fail(f"{locale} InfoPlist.strings should not request full photo-library access")


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
    project = read("SkateTrack.xcodeproj/project.pbxproj")
    for token in FORBIDDEN_ANYWHERE:
        if token in project:
            fail(f"Forbidden token {token} found in project file")
        for path in relevant_swift_files():
            relative = str(path.relative_to(ROOT))
            if token in path.read_text(encoding="utf-8"):
                fail(f"Forbidden token {token} found in {relative}")

    for token, allowed_files in ALLOWED_TOKEN_FILES.items():
        for path in relevant_swift_files():
            relative = str(path.relative_to(ROOT))
            if token in path.read_text(encoding="utf-8") and relative not in allowed_files:
                fail(f"Token {token} is only allowed in {allowed_files}, found in {relative}")


def main() -> None:
    verify_files()
    verify_project()
    verify_localization()
    verify_sources()
    verify_line_counts()
    verify_boundaries()
    print("✅ Task-023c Save to Photos verification passed")


if __name__ == "__main__":
    main()
