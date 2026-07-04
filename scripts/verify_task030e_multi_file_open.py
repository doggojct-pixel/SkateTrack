#!/usr/bin/env python3
"""Verify Task-030e-MacViewer-004 multi-file open foundation."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "macOS/Features/SessionBrowser/MacPackageOpenCoordinator.swift",
    "macOS/Features/SessionBrowser/MacPackageOpenResultStatusView.swift",
    "macOS/Features/SessionBrowser/MacMultiPackageViewerState.swift",
    "macOS/Features/Import/MacPackageImportViewModel.swift",
    "macOS/Features/SessionBrowser/MacSessionBrowserView.swift",
    "Shared/Localization/en.lproj/Localizable.strings",
    "Shared/Localization/zh-Hant.lproj/Localizable.strings",
    "Shared/Localization/ja.lproj/Localizable.strings",
    "SkateTrack.xcodeproj/project.pbxproj",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
]

REQUIRED_LOCALIZATION_KEYS = [
    "mac.viewer.open.panel.title",
    "mac.viewer.open.panel.prompt",
    "mac.viewer.open.panel.message",
    "mac.viewer.open.current_batch.format",
    "mac.viewer.open.partial_failure.title",
    "mac.viewer.open.partial_failure.message.format",
    "mac.viewer.open.failed.title",
    "mac.viewer.open.failed.message.format",
    "mac.viewer.open.failure.overflow.format",
    "mac.accessibility.open_result.label",
    "mac.accessibility.open_result.hint",
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
    print(f"Task-030e multi-file open check failed: {message}", file=sys.stderr)
    sys.exit(1)


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def ensure_files() -> None:
    missing = [path for path in REQUIRED_FILES if not (ROOT / path).exists()]
    if missing:
        fail("missing required files: " + ", ".join(missing))


def ensure_open_coordinator() -> None:
    coordinator = read("macOS/Features/SessionBrowser/MacPackageOpenCoordinator.swift")
    for token in [
        "// [協作區]",
        "struct MacPackageOpenFailure: Identifiable, Equatable",
        "struct MacPackageOpenResult: Equatable",
        "struct MacPackageOpenCoordinator",
        "func openPackages(from urls: [URL]) -> MacPackageOpenResult",
        "private enum MacPackagePreviewReadResult: Equatable",
        "case success(MacPackageImportPreview)",
        "case failure(String)",
        "private func readPreview(from url: URL) -> MacPackagePreviewReadResult",
        "url.pathExtension.lowercased() == \"skatetrack\"",
        "url.startAccessingSecurityScopedResource()",
        "url.stopAccessingSecurityScopedResource()",
        "reader.readPackage(from: url)",
        "SkateTrackPackageError",
        "failures.append",
        "previews.append",
        "requestedFileCount: urls.count",
    ]:
        if token not in coordinator:
            fail(f"MacPackageOpenCoordinator missing token: {token}")
    if "throw" in coordinator:
        fail("coordinator should classify per-file failures instead of throwing one batch error")


def ensure_view_model_batch_boundary() -> None:
    view_model = read("macOS/Features/Import/MacPackageImportViewModel.swift")
    for token in [
        "@Published private(set) var lastOpenResult: MacPackageOpenResult?",
        "private let openCoordinator: MacPackageOpenCoordinator",
        "self.openCoordinator = MacPackageOpenCoordinator(reader: reader)",
        "func importPackage(from url: URL)",
        "openPackages(from: [url])",
        "func openPackages(from urls: [URL])",
        "let result = openCoordinator.openPackages(from: urls)",
        "lastOpenResult = result",
        "if result.hasAnySuccess",
        "nextState.replace(with: result.previews)",
        "clearPackagesForReadFailure(errorMessageKey: result.primaryErrorMessageKey ?? \"mac.import.error.generic\")",
    ]:
        if token not in view_model:
            fail(f"MacPackageImportViewModel missing batch boundary token: {token}")
    if "Data(contentsOf:" in view_model:
        fail("view model must delegate file reading to the coordinator/reader boundary")


def ensure_browser_multi_select() -> None:
    browser = read("macOS/Features/SessionBrowser/MacSessionBrowserView.swift")
    for token in [
        "MacPackageBrowserHeaderView(",
        "batchSummary: viewModel.batchSummary",
        "MacPackageOpenResultStatusView(result: lastOpenResult)",
        "panel.title = String(localized: \"mac.viewer.open.panel.title\")",
        "panel.prompt = String(localized: \"mac.viewer.open.panel.prompt\")",
        "panel.message = String(localized: \"mac.viewer.open.panel.message\")",
        "panel.allowsMultipleSelection = true",
        "panel.allowedContentTypes = [.data]",
        "!panel.urls.isEmpty",
        "viewModel.openPackages(from: panel.urls)",
        "mac.viewer.open.current_batch.format",
    ]:
        if token not in browser:
            fail(f"MacSessionBrowserView missing multi-select token: {token}")
    if "viewModel.importPackage(from: url)" in browser:
        fail("Session Browser should use the multi-file open view-model boundary after Task-030e-004")
    if "allowedContentTypes = [.skatetrack" in browser or "UTType(" in browser:
        fail("Task-030e-004 must not add custom UTType handling")


def ensure_state_supports_batch_replace() -> None:
    state = read("macOS/Features/SessionBrowser/MacMultiPackageViewerState.swift")
    for token in [
        "mutating func replace(with previews: [MacPackageImportPreview])",
        "packages = uniquePreviews(from: previews)",
        "private func uniquePreviews(from previews: [MacPackageImportPreview])",
        "preview.fileURL.standardizedFileURL.path",
        "ensureValidSelection()",
    ]:
        if token not in state:
            fail(f"MacMultiPackageViewerState missing batch replace token: {token}")


def ensure_result_status_view() -> None:
    result_view = read("macOS/Features/SessionBrowser/MacPackageOpenResultStatusView.swift")
    for token in [
        "struct MacPackageOpenResultStatusView: View",
        "let result: MacPackageOpenResult",
        "result.hasFailures",
        "result.isPartialSuccess",
        "ForEach(Array(result.failures.prefix(3)))",
        "Text(LocalizedStringKey(failure.errorMessageKey))",
        "mac.viewer.open.partial_failure.title",
        "mac.viewer.open.failed.title",
        "mac.viewer.open.failure.overflow.format",
        "mac.accessibility.open_result.label",
    ]:
        if token not in result_view:
            fail(f"MacPackageOpenResultStatusView missing token: {token}")


def ensure_localization() -> None:
    for lang in ["en.lproj", "zh-Hant.lproj", "ja.lproj"]:
        text = read(f"Shared/Localization/{lang}/Localizable.strings")
        for key in REQUIRED_LOCALIZATION_KEYS:
            if f'"{key}"' not in text:
                fail(f"missing localization key {key} in {lang}")


def ensure_project_membership() -> None:
    project = read("SkateTrack.xcodeproj/project.pbxproj")
    for token in [
        "MacPackageOpenCoordinator.swift",
        "MacPackageOpenCoordinator.swift in Sources",
        "MacPackageOpenResultStatusView.swift",
        "MacPackageOpenResultStatusView.swift in Sources",
    ]:
        if token not in project:
            fail(f"project missing token: {token}")
    mac_sources = re.search(r"A2EF5573281ED5113A3645DD /\* Sources \*/ = \{.*?files = \((.*?)\);", project, re.S)
    if not mac_sources:
        fail("could not locate macOS sources build phase")
    for token in ["MacPackageOpenCoordinator.swift in Sources", "MacPackageOpenResultStatusView.swift in Sources"]:
        if token not in mac_sources.group(1):
            fail(f"macOS sources phase missing {token}")


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
        "Task-030e-MacViewer-004",
        "Multi-File Open Foundation",
        "MacPackageOpenCoordinator",
        "MacPackageOpenResultStatusView",
        "allowsMultipleSelection = true",
        "partial success",
        "read-only",
        "no custom UTType",
        "SkateTrack_BuildPlan_Task-030e_MacOS_MultiPackage_Viewer_EN_v1.2",
    ]:
        if token not in docs:
            fail(f"documentation missing token: {token}")


def ensure_boundaries() -> None:
    paths = [
        "macOS/Features/SessionBrowser/MacPackageOpenCoordinator.swift",
        "macOS/Features/SessionBrowser/MacPackageOpenResultStatusView.swift",
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
    ensure_open_coordinator()
    ensure_view_model_batch_boundary()
    ensure_browser_multi_select()
    ensure_state_supports_batch_replace()
    ensure_result_status_view()
    ensure_localization()
    ensure_project_membership()
    ensure_docs()
    ensure_boundaries()
    print("Task-030e multi-file open check passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
