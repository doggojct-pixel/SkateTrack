#!/usr/bin/env python3
"""Verify Task-027b macOS .skatetrack import stub and package preview boundaries."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "macOS/App/SkateTrackMacApp.swift",
    "macOS/App/MacRootView.swift",
    "macOS/Features/Import/MacImportView.swift",
    "macOS/Features/Import/MacPackagePreviewView.swift",
    "macOS/Features/Import/MacPackageImportViewModel.swift",
    "macOS/Features/Shared/MacLockedFeatureCardView.swift",
    "macOS/Features/SessionBrowser/MacSessionViewerModel.swift",
    "Shared/Export/SkateTrackPackageReader.swift",
    "Shared/Models/SkateTrackPackageManifest.swift",
    "Shared/Models/SkateTrackPackagePayload.swift",
    "scripts/verify_macos_package_preview.py",
    "docs/decisions/ADR-0007-portable-skatetrack-package-strategy.md",
]

PROJECT_MEMBERSHIP = [
    "MacRootView.swift",
    "MacImportView.swift",
    "MacPackagePreviewView.swift",
    "MacPackageImportViewModel.swift",
    "MacLockedFeatureCardView.swift",
    "SkateTrackPackageReader.swift",
]

LOCALIZATION_KEYS = [
    "mac.import.title",
    "mac.import.hero.title",
    "mac.import.button.choose",
    "mac.import.error.extension",
    "mac.package.preview.valid",
    "mac.package.preview.manifest.title",
    "mac.package.preview.locked.viewer.title",
]

FORBIDDEN_PROJECT_TOKENS = [
    "UTExportedTypeDeclarations",
    "CFBundleDocumentTypes",
    "LSSupportsOpeningDocumentsInPlace",
    "com.apple.developer.icloud-container-identifiers",
    "com.apple.developer.ubiquity-container-identifiers",
]

FORBIDDEN_MAC_TOKENS = [
    "UIDocumentPickerViewController",
    "UIApplication",
    "UIKit",
    "GoogleSignIn",
    "GIDSignIn",
    "GoogleService-Info.plist",
    "Drive API",
    "CloudKit",
]


def fail(message: str) -> None:
    print(f"Task-027b macOS package preview check failed: {message}", file=sys.stderr)
    sys.exit(1)


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def ensure_files() -> None:
    missing = [path for path in REQUIRED_FILES if not (ROOT / path).exists()]
    if missing:
        fail("missing required files: " + ", ".join(missing))


def ensure_macos_shell() -> None:
    app = read("macOS/App/SkateTrackMacApp.swift")
    root = read("macOS/App/MacRootView.swift")
    if "MacRootView()" not in app:
        fail("macOS app must load MacRootView")
    if "NavigationSplitView" not in root:
        fail("MacRootView must use NavigationSplitView")
    if "RootNavigationView" in root or "iOS/App" in root:
        fail("macOS shell must not reuse iOS RootNavigationView")
    for token in [
        "MacImportView(viewModel: packageViewModel)",
        "MacSessionBrowserView",
        "MacLockedFeatureCardView",
        "mac.import.sidebar",
        "NavigationSplitView(columnVisibility:",
        "NavigationSplitViewVisibility = .all",
        "MacSidebarView",
        "MacRootDetailView",
        "navigationSplitViewColumnWidth",
    ]:
        if token not in root:
            fail(f"MacRootView missing stability token: {token}")
    if "List(selection:" in root:
        fail("MacRootView should use a stable custom sidebar instead of List(selection:) for Task-027b")
    if "@State private var selection: MacRootDestination?" in root:
        fail("MacRootView selection must be non-optional to avoid nil detail/sidebar collapse")


def ensure_import_boundary() -> None:
    import_view = read("macOS/Features/Import/MacImportView.swift")
    view_model = read("macOS/Features/Import/MacPackageImportViewModel.swift")
    preview = read("macOS/Features/Import/MacPackagePreviewView.swift")
    locked = read("macOS/Features/Shared/MacLockedFeatureCardView.swift")

    for token in ["NSOpenPanel", "allowedContentTypes = [.data]", "viewModel.importPackage"]:
        if token not in import_view:
            fail(f"MacImportView missing token: {token}")
    for token in [".padding(.top,", ".frame(maxWidth: .infinity, alignment: .topLeading)"]:
        if token not in import_view:
            fail(f"MacImportView missing titlebar-safe layout token: {token}")
    if "allowedContentTypes = [.skatetrack]" in import_view or "UTType(exportedAs" in import_view:
        fail("Task-027b must not declare/use a custom .skatetrack UTType")
    for token in ["SkateTrackPackageReader", "readPackage(from: url)", "startAccessingSecurityScopedResource", "pathExtension.lowercased() == \"skatetrack\""]:
        if token not in view_model:
            fail(f"view model missing token: {token}")
    for token in ["packageError.localizationKey", "clearPreview", "MacPackageImportPreview"]:
        if token not in view_model:
            fail(f"view model missing state/error token: {token}")
    for token in ["schemaVersion", "packageType", "motionSampleCount", "routeSampleCount", "summaryMetrics", "privacyNotes", "MacLockedFeatureCardView", "MacSessionViewerModel"]:
        if token not in preview:
            fail(f"preview view missing token: {token}")
    if "StoreKit" in locked or "Transaction" in locked:
        fail("locked feature card must not imply production StoreKit or transactions")


def ensure_no_forbidden_runtime_services() -> None:
    for path in [
        "macOS/App/SkateTrackMacApp.swift",
        "macOS/App/MacRootView.swift",
        "macOS/Features/Import/MacImportView.swift",
        "macOS/Features/Import/MacPackagePreviewView.swift",
        "macOS/Features/Import/MacPackageImportViewModel.swift",
        "macOS/Features/Shared/MacLockedFeatureCardView.swift",
    ]:
        text = read(path)
        for token in FORBIDDEN_MAC_TOKENS:
            if token in text:
                fail(f"forbidden token {token!r} found in {path}")

    project = read("SkateTrack.xcodeproj/project.pbxproj")
    for token in FORBIDDEN_PROJECT_TOKENS:
        if token in project:
            fail(f"project contains deferred document/capability token: {token}")


def ensure_project_membership() -> None:
    project = read("SkateTrack.xcodeproj/project.pbxproj")
    for token in PROJECT_MEMBERSHIP:
        if token not in project:
            fail(f"missing project membership for {token}")
    mac_sources = re.search(r"A2EF5573281ED5113A3645DD /\* Sources \*/ = \{.*?files = \((.*?)\);", project, re.S)
    if not mac_sources:
        fail("could not locate macOS sources build phase")
    sources_text = mac_sources.group(1)
    for token in [
        "MacRootView.swift in Sources",
        "MacImportView.swift in Sources",
        "MacPackagePreviewView.swift in Sources",
        "MacPackageImportViewModel.swift in Sources",
        "MacLockedFeatureCardView.swift in Sources",
        "SkateTrackPackageReader.swift in Sources",
    ]:
        if token not in sources_text:
            fail(f"macOS sources phase missing {token}")


def ensure_localization() -> None:
    for lang in ["en.lproj", "zh-Hant.lproj"]:
        text = read(f"Shared/Localization/{lang}/Localizable.strings")
        for key in LOCALIZATION_KEYS:
            if f'"{key}"' not in text:
                fail(f"missing localization key {key} in {lang}")


def ensure_docs() -> None:
    docs = "\n".join(
        read(path)
        for path in [
            "docs/DEV_LOG.md",
            "docs/FILE_STRUCTURE.md",
            "docs/decisions/ADR-0007-portable-skatetrack-package-strategy.md",
            "docs/Task026-030_TechRisk_Solutions.md",
        ]
    )
    for token in [
        "Task-027b",
        "macOS Import Stub",
        "NSOpenPanel",
        "NavigationSplitView",
        "stable custom sidebar",
        "titlebar",
        "packageType = export",
        "custom UTType",
        "Task-028a",
    ]:
        if token not in docs:
            fail(f"documentation missing token: {token}")


def main() -> int:
    ensure_files()
    ensure_macos_shell()
    ensure_import_boundary()
    ensure_no_forbidden_runtime_services()
    ensure_project_membership()
    ensure_localization()
    ensure_docs()
    print("Task-027b macOS package preview check passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
