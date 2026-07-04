#!/usr/bin/env python3
"""Verify Task-030e-MacViewer-005 package cards and batch summary UI."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "macOS/Features/SessionBrowser/MacPackageCardListView.swift",
    "macOS/Features/SessionBrowser/MacSessionBrowserView.swift",
    "macOS/Features/SessionBrowser/MacMultiPackageViewerState.swift",
    "macOS/Features/Import/MacPackageImportViewModel.swift",
    "Shared/Localization/en.lproj/Localizable.strings",
    "Shared/Localization/zh-Hant.lproj/Localizable.strings",
    "Shared/Localization/ja.lproj/Localizable.strings",
    "SkateTrack.xcodeproj/project.pbxproj",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
]

REQUIRED_LOCALIZATION_KEYS = [
    "mac.viewer.packages.title",
    "mac.viewer.packages.summary.format",
    "mac.viewer.packages.card.position.format",
    "mac.viewer.packages.card.session_count.format",
    "mac.viewer.packages.card.route_count.format",
    "mac.viewer.packages.card.motion_count.format",
    "mac.viewer.packages.card.remove",
    "mac.viewer.packages.card.selected",
    "mac.viewer.packages.card.not_selected",
    "mac.viewer.packages.card.hint",
    "mac.accessibility.package_cards.label",
    "mac.accessibility.package_cards.hint",
]

FORBIDDEN_TOKENS = [
    "SessionRepository(",
    "PersistenceController",
    "saveSession(",
    "deleteSession(",
    "CoreData",
    "CloudKit",
    "GoogleSignIn",
    "GIDSignIn",
    "UTExportedTypeDeclarations",
    "CFBundleDocumentTypes",
    "LSSupportsOpeningDocumentsInPlace",
    "MapKit",
    "MKMapView",
    "mapMatch",
    "snapToRoad",
    "reconstructRoute",
    "mutateRouteGeometry",
    "trustedMetricsMutation",
]


def fail(message: str) -> None:
    print(f"Task-030e package cards check failed: {message}", file=sys.stderr)
    sys.exit(1)


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def ensure_files() -> None:
    missing = [path for path in REQUIRED_FILES if not (ROOT / path).exists()]
    if missing:
        fail("missing required files: " + ", ".join(missing))


def ensure_package_cards_view() -> None:
    cards = read("macOS/Features/SessionBrowser/MacPackageCardListView.swift")
    for token in [
        "// [協作區]",
        "struct MacPackageCardListView: View",
        "let packages: [MacPackageImportPreview]",
        "let selectedPackageID: UUID?",
        "let batchSummary: MacPackageOpenBatchSummary",
        "let selectPackageAction: (UUID) -> Void",
        "let removePackageAction: (UUID) -> Void",
        "packages.count > 1",
        "MacPackageSelectionCard(",
        "selectPackageAction(package.id)",
        "removePackageAction(package.id)",
        "private var cardSelectButton: some View",
        "contentShape(RoundedRectangle",
        "mac.viewer.packages.summary.format",
        "mac.viewer.packages.card.session_count.format",
        "mac.viewer.packages.card.route_count.format",
        "mac.viewer.packages.card.motion_count.format",
        "mac.viewer.packages.card.remove",
        "mac.accessibility.package_cards.label",
    ]:
        if token not in cards:
            fail(f"MacPackageCardListView missing token: {token}")
    if "import AppKit" in cards:
        fail("package card view should remain SwiftUI-only")


def ensure_browser_hosts_cards() -> None:
    browser = read("macOS/Features/SessionBrowser/MacSessionBrowserView.swift")
    for token in [
        "MacPackageCardListView(",
        "packages: viewModel.openedPackages",
        "selectedPackageID: viewModel.selectedPackageID",
        "batchSummary: viewModel.batchSummary",
        "selectPackageAction: { viewModel.selectPackage(id: $0) }",
        "removePackageAction: viewModel.removePackage",
    ]:
        if token not in browser:
            fail(f"MacSessionBrowserView missing package-card host token: {token}")
    if browser.find("MacPackageCardListView(") > browser.find("if let preview"):
        fail("package cards should appear before selected package detail content")


def ensure_state_and_view_model_boundaries() -> None:
    state = read("macOS/Features/SessionBrowser/MacMultiPackageViewerState.swift")
    view_model = read("macOS/Features/Import/MacPackageImportViewModel.swift")
    for token in [
        "mutating func selectPackage(id: UUID?)",
        "mutating func removePackage(id: UUID)",
        "selection.selectedSessionID = nil",
        "ensureValidSelection()",
    ]:
        if token not in state:
            fail(f"MacMultiPackageViewerState missing selection token: {token}")
    for token in [
        "var openedPackages: [MacPackageImportPreview]",
        "var selectedPackageID: UUID?",
        "func selectPackage(id: UUID?)",
        "func removePackage(id: UUID)",
    ]:
        if token not in view_model:
            fail(f"MacPackageImportViewModel missing package-card boundary token: {token}")


def ensure_localization() -> None:
    for lang in ["en.lproj", "zh-Hant.lproj", "ja.lproj"]:
        text = read(f"Shared/Localization/{lang}/Localizable.strings")
        for key in REQUIRED_LOCALIZATION_KEYS:
            if f'"{key}"' not in text:
                fail(f"missing localization key {key} in {lang}")


def ensure_project_membership() -> None:
    project = read("SkateTrack.xcodeproj/project.pbxproj")
    for token in [
        "30E600000000000000000001 /* MacPackageCardListView.swift */ = {isa = PBXFileReference;",
        "30E600000000000000000101 /* MacPackageCardListView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 30E600000000000000000001",
        "30E600000000000000000001 /* MacPackageCardListView.swift */,",
        "30E600000000000000000101 /* MacPackageCardListView.swift in Sources */,",
    ]:
        if token not in project:
            fail(f"project missing token: {token}")
    mac_sources = re.search(r"A2EF5573281ED5113A3645DD /\* Sources \*/ = \{.*?files = \((.*?)\);", project, re.S)
    if not mac_sources:
        fail("could not locate macOS sources build phase")
    if "MacPackageCardListView.swift in Sources" not in mac_sources.group(1):
        fail("macOS sources phase missing MacPackageCardListView.swift")


def ensure_docs() -> None:
    docs = "\n".join(
        read(path)
        for path in [
            "docs/history/DEV_LOG.md",
            "docs/reference/FILE_STRUCTURE.md",
            "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
        ]
    )
    for token in [
        "Task-030e-MacViewer-005",
        "Package Cards and Batch Summary",
        "MacPackageCardListView",
        "package switching",
        "package removal",
        "read-only",
        "SkateTrack_BuildPlan_Task-030e_MacOS_MultiPackage_Viewer_EN_v1.2",
    ]:
        if token not in docs:
            fail(f"documentation missing token: {token}")


def ensure_boundaries() -> None:
    paths = [
        "macOS/Features/SessionBrowser/MacPackageCardListView.swift",
        "macOS/Features/SessionBrowser/MacSessionBrowserView.swift",
        "macOS/Features/SessionBrowser/MacMultiPackageViewerState.swift",
        "macOS/Features/Import/MacPackageImportViewModel.swift",
    ]
    sources = "\n".join(read(path) for path in paths)
    for token in FORBIDDEN_TOKENS:
        if token in sources:
            fail(f"forbidden deferred/mutation token found: {token}")


def main() -> int:
    ensure_files()
    ensure_package_cards_view()
    ensure_browser_hosts_cards()
    ensure_state_and_view_model_boundaries()
    ensure_localization()
    ensure_project_membership()
    ensure_docs()
    ensure_boundaries()
    print("Task-030e package cards check passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
