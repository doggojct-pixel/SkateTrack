#!/usr/bin/env python3
"""Verify Task-030e-MacViewer-003 in-memory multi-package preview state."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "macOS/Features/SessionBrowser/MacMultiPackageViewerState.swift",
    "macOS/Features/Import/MacPackageImportViewModel.swift",
    "macOS/Features/SessionBrowser/MacSessionBrowserView.swift",
    "Shared/Localization/en.lproj/Localizable.strings",
    "Shared/Localization/zh-Hant.lproj/Localizable.strings",
    "Shared/Localization/ja.lproj/Localizable.strings",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
]

FORBIDDEN_TOKENS = [
    "SessionRepository(",
    "PersistenceController",
    "saveSession(",
    "deleteSession(",
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
    print(f"Task-030e multi-package state check failed: {message}", file=sys.stderr)
    sys.exit(1)


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def ensure_files() -> None:
    missing = [path for path in REQUIRED_FILES if not (ROOT / path).exists()]
    if missing:
        fail("missing required files: " + ", ".join(missing))


def ensure_state_model() -> None:
    state = read("macOS/Features/SessionBrowser/MacMultiPackageViewerState.swift")
    for token in [
        "// [協作區]",
        "struct MacMultiPackageViewerSelection",
        "struct MacPackageOpenBatchSummary",
        "struct MacMultiPackageViewerState",
        "private(set) var packages: [MacPackageImportPreview]",
        "private(set) var selection: MacMultiPackageViewerSelection",
        "var selectedPackage: MacPackageImportPreview?",
        "var selectedPackageSession: SkateTrackPackageSession?",
        "var batchSummary: MacPackageOpenBatchSummary",
        "mutating func replace(with preview: MacPackageImportPreview)",
        "mutating func replace(with previews: [MacPackageImportPreview])",
        "mutating func appendOrReplacePackage",
        "mutating func selectPackage(id: UUID?)",
        "mutating func selectSession(id: UUID?)",
        "mutating func removePackage(id: UUID)",
        "mutating func clear()",
        "mutating func ensureValidSelection()",
    ]:
        if token not in state:
            fail(f"MacMultiPackageViewerState missing token: {token}")
    if "FileManager" in state or "Data(contentsOf:" in state:
        fail("state model must not read files directly")


def ensure_view_model_boundary() -> None:
    view_model = read("macOS/Features/Import/MacPackageImportViewModel.swift")
    for token in [
        "@Published private(set) var viewerState = MacMultiPackageViewerState()",
        "var openedPackages: [MacPackageImportPreview]",
        "var batchSummary: MacPackageOpenBatchSummary",
        "var selectedPackageID: UUID?",
        "var selectedSessionID: UUID?",
        "var selectedViewerModels: [MacSessionViewerModel]",
        "var selectedViewerModel: MacSessionViewerModel?",
        "nextState.mergeOpenedPreviews(result.previews)",
        "appendPackagePreviewForFutureBatch",
        "func selectPackage(id: UUID?)",
        "func selectSession(id: UUID?)",
        "func removePackage(id: UUID)",
        "func ensureDefaultSelection()",
        "clearPackagesForReadFailure",
        "SkateTrackPackageReader",
        "MacPackageOpenCoordinator",
        "func openPackages(from urls: [URL])",
    ]:
        if token not in view_model:
            fail(f"MacPackageImportViewModel missing multi-package state token: {token}")
    coordinator = read("macOS/Features/SessionBrowser/MacPackageOpenCoordinator.swift")
    for token in ["startAccessingSecurityScopedResource", "readPackage(from: url)"]:
        if token not in coordinator:
            fail(f"MacPackageOpenCoordinator missing read boundary token: {token}")
    # Later Task-030e stages may enable true multi-file opening at the browser boundary.


def ensure_browser_uses_boundary() -> None:
    browser = read("macOS/Features/SessionBrowser/MacSessionBrowserView.swift")
    for token in [
        "viewModel.selectedViewerModels",
        "viewModel.selectedViewerModel",
        "selectedSessionID: viewModel.selectedSessionID",
        "selectSessionAction: viewModel.selectSession",
        ".onAppear { viewModel.ensureDefaultSelection() }",
        "viewModel.openPackages(from: panel.urls)",
        "panel.allowsMultipleSelection = true",
    ]:
        if token not in browser:
            fail(f"MacSessionBrowserView missing view-model selection boundary token: {token}")
    if "@State private var selectedSessionID" in browser:
        fail("Session Browser must not own selected session state locally after Task-030e-003")
    # Task-030e-004 intentionally enables multi-file open while retaining 003 state ownership.


def ensure_project_membership() -> None:
    project = read("SkateTrack.xcodeproj/project.pbxproj")
    for token in [
        "MacMultiPackageViewerState.swift",
        "MacMultiPackageViewerState.swift in Sources",
    ]:
        if token not in project:
            fail(f"project missing token: {token}")
    mac_sources = re.search(r"A2EF5573281ED5113A3645DD /\* Sources \*/ = \{.*?files = \((.*?)\);", project, re.S)
    if not mac_sources:
        fail("could not locate macOS sources build phase")
    if "MacMultiPackageViewerState.swift in Sources" not in mac_sources.group(1):
        fail("macOS sources phase missing MacMultiPackageViewerState.swift")


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
        "Task-030e-MacViewer-003",
        "SkateTrack_BuildPlan_Task-030e_MacOS_MultiPackage_Viewer_EN_v1.2",
        "MacMultiPackageViewerState",
        "MacMultiPackageViewerSelection",
        "MacPackageOpenBatchSummary",
        "single-file compatibility retained",
        "multi-file open foundation",
        "read-only",
    ]:
        if token not in docs:
            fail(f"documentation missing token: {token}")


def ensure_boundaries() -> None:
    paths = [
        "macOS/Features/SessionBrowser/MacMultiPackageViewerState.swift",
        "macOS/Features/Import/MacPackageImportViewModel.swift",
        "macOS/Features/SessionBrowser/MacSessionBrowserView.swift",
    ]
    sources = "\n".join(read(path) for path in paths)
    for token in FORBIDDEN_TOKENS:
        if token in sources:
            fail(f"forbidden deferred/mutation token found: {token}")
    project = read("SkateTrack.xcodeproj/project.pbxproj")
    for token in ["UTExportedTypeDeclarations", "CFBundleDocumentTypes", "LSSupportsOpeningDocumentsInPlace"]:
        if token in project:
            fail(f"forbidden document association token found: {token}")


def main() -> int:
    ensure_files()
    ensure_state_model()
    ensure_view_model_boundary()
    ensure_browser_uses_boundary()
    ensure_project_membership()
    ensure_docs()
    ensure_boundaries()
    print("Task-030e multi-package state check passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
