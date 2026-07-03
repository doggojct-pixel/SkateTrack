#!/usr/bin/env python3
"""Verify Task-030e-MacViewer-002 browser-first IA shell."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "macOS/App/MacRootView.swift",
    "macOS/Features/Import/MacImportView.swift",
    "macOS/Features/Import/MacPackageImportViewModel.swift",
    "macOS/Features/SessionBrowser/MacSessionBrowserView.swift",
    "macOS/Features/SessionBrowser/MacSessionDetailView.swift",
    "Shared/Localization/en.lproj/Localizable.strings",
    "Shared/Localization/zh-Hant.lproj/Localizable.strings",
    "Shared/Localization/ja.lproj/Localizable.strings",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
]

REQUIRED_LOCALIZATION_KEYS = [
    "mac.viewer.open.title",
    "mac.viewer.open.subtitle",
    "mac.viewer.open.button",
    "mac.viewer.open.clear",
    "mac.viewer.open.readonly",
    "mac.viewer.open.error.title",
    "mac.viewer.open.current_file.format",
    "mac.accessibility.browser_header.label",
    "mac.accessibility.browser_header.hint",
]

FORBIDDEN_MUTATION_TOKENS = [
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
    "mapMatch",
    "snapToRoad",
    "reconstructRoute",
    "mutateRouteGeometry",
    "trustedMetricsMutation",
]


def fail(message: str) -> None:
    print(f"Task-030e browser-first IA check failed: {message}", file=sys.stderr)
    sys.exit(1)


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def ensure_files() -> None:
    missing = [path for path in REQUIRED_FILES if not (ROOT / path).exists()]
    if missing:
        fail("missing required files: " + ", ".join(missing))


def ensure_root_browser_first() -> None:
    root = read("macOS/App/MacRootView.swift")
    for token in [
        "Task-030e",
        "case sessionBrowser",
        "@State private var selection: MacRootDestination = .sessionBrowser",
        "MacSessionBrowserView(viewModel: packageViewModel)",
        "NavigationSplitView(columnVisibility:",
    ]:
        if token not in root:
            fail(f"MacRootView missing browser-first token: {token}")
    if "case importPackage" in root:
        fail("Import must not be a primary MacRootDestination in Task-030e-002")
    if "selection = .importPackage" in root:
        fail("Browser package opening must not route through an Import destination")


def ensure_browser_open_action() -> None:
    browser = read("macOS/Features/SessionBrowser/MacSessionBrowserView.swift")
    for token in [
        "@ObservedObject private var viewModel: MacPackageImportViewModel",
        "MacPackageBrowserHeaderView",
        "openPackagePanel",
        "NSOpenPanel",
        "allowsMultipleSelection = false",
        "allowedContentTypes = [.data]",
        "viewModel.importPackage(from: url)",
        "viewModel.clearPreview",
        "mac.viewer.open.title",
        "mac.viewer.open.button",
        "mac.viewer.open.readonly",
    ]:
        if token not in browser:
            fail(f"MacSessionBrowserView missing browser open token: {token}")
    for forbidden in ["openImportAction", "Go to Import", "MacImportView("]:
        if forbidden in browser:
            fail(f"MacSessionBrowserView still contains disconnected Import flow token: {forbidden}")
    if "allowsMultipleSelection = true" in browser:
        fail("Task-030e-002 must not implement multi-file open yet")


def ensure_localization() -> None:
    for lang in ["en.lproj", "zh-Hant.lproj", "ja.lproj"]:
        text = read(f"Shared/Localization/{lang}/Localizable.strings")
        for key in REQUIRED_LOCALIZATION_KEYS:
            if f'"{key}"' not in text:
                fail(f"missing localization key {key} in {lang}")
        if "Go to Import" in text or "前往匯入" in text or "読み込みへ移動" in text:
            fail(f"{lang} still contains old Go to Import browser copy")


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
        "Task-030e-MacViewer-002",
        "browser-first",
        "Open Packages",
        "read-only",
        "SkateTrack_BuildPlan_Task-030e_MacOS_MultiPackage_Viewer_EN_v1.2",
    ]:
        if token not in docs:
            fail(f"documentation missing token: {token}")


def ensure_no_deferred_scope() -> None:
    project = read("SkateTrack.xcodeproj/project.pbxproj")
    for project_token in ["UTExportedTypeDeclarations", "CFBundleDocumentTypes", "LSSupportsOpeningDocumentsInPlace"]:
        if project_token in project:
            fail(f"forbidden project document token found: {project_token}")
    sources = "\n".join(
        read(path)
        for path in [
            "macOS/App/MacRootView.swift",
            "macOS/Features/SessionBrowser/MacSessionBrowserView.swift",
            "macOS/Features/Import/MacImportView.swift",
            "macOS/Features/Import/MacPackageImportViewModel.swift",
        ]
    )
    for token in FORBIDDEN_MUTATION_TOKENS:
        if token in sources:
            fail(f"forbidden deferred/mutation token found: {token}")
    if re.search(r"MapKit|MKMapView|\.sheet\(|WindowGroup\(", sources):
        fail("Task-030e-002 must not implement map or expanded route inspection yet")


def main() -> int:
    ensure_files()
    ensure_root_browser_first()
    ensure_browser_open_action()
    ensure_localization()
    ensure_docs()
    ensure_no_deferred_scope()
    print("Task-030e browser-first IA check passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
