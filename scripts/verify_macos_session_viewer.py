#!/usr/bin/env python3
"""Verify Task-028a macOS read-only Session Viewer foundation."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "macOS/App/MacRootView.swift",
    "macOS/Features/Import/MacImportView.swift",
    "macOS/Features/Import/MacPackagePreviewView.swift",
    "macOS/Features/Import/MacPackageImportViewModel.swift",
    "macOS/Features/SessionBrowser/MacSessionBrowserView.swift",
    "macOS/Features/SessionBrowser/MacSessionDetailView.swift",
    "macOS/Features/SessionBrowser/MacSessionViewerModel.swift",
    "macOS/Features/SessionBrowser/MacSpeedSparklineView.swift",
    "macOS/Features/SessionBrowser/MacRoutePreviewView.swift",
    "Shared/Export/SkateTrackPackageReader.swift",
    "Shared/Models/SkateTrackPackagePayload.swift",
    "scripts/verify_macos_session_viewer.py",
    "docs/adr/ADR-INDEX.md",
]

PROJECT_MEMBERSHIP = [
    "MacSessionBrowserView.swift",
    "MacSessionDetailView.swift",
    "MacSessionViewerModel.swift",
    "MacSpeedSparklineView.swift",
    "MacRoutePreviewView.swift",
]

LOCALIZATION_KEYS = [
    "mac.viewer.title",
    "mac.viewer.empty.title",
    "mac.viewer.metrics.title",
    "mac.viewer.metrics.derived_notice",
    "mac.viewer.chart.speed.title",
    "mac.viewer.route.title",
    "mac.viewer.route.preview.title",
    "mac.viewer.route.data.title",
    "mac.viewer.package.current",
    "mac.viewer.package.single_session",
    "mac.viewer.package.session_count.format",
    "mac.viewer.detail.title",
    "mac.viewer.privacy.readonly",
]

FORBIDDEN_PROJECT_TOKENS = [
    "UTExportedTypeDeclarations",
    "CFBundleDocumentTypes",
    "LSSupportsOpeningDocumentsInPlace",
    "com.apple.developer.icloud-container-identifiers",
    "com.apple.developer.ubiquity-container-identifiers",
]

FORBIDDEN_VIEWER_TOKENS = [
    "UIKit",
    "UIDocumentPickerViewController",
    "MKMapView",
    "MapKit",
    "Charts",
    "Chart(",
    "FileDocument",
    "GoogleSignIn",
    "GIDSignIn",
    "CloudKit",
    "StoreKit",
    "PersistenceController",
    "SessionRepository",
    "BackupPackagePayload",
]


def fail(message: str) -> None:
    print(f"Task-028a macOS session viewer check failed: {message}", file=sys.stderr)
    sys.exit(1)


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def ensure_files() -> None:
    missing = [path for path in REQUIRED_FILES if not (ROOT / path).exists()]
    if missing:
        fail("missing required files: " + ", ".join(missing))


def ensure_root_shared_preview_state() -> None:
    root = read("macOS/App/MacRootView.swift")
    for token in [
        "@StateObject private var packageViewModel",
        "MacImportView(viewModel: packageViewModel)",
        "MacSessionBrowserView(",
        "preview: packageViewModel.preview",
        "openImportAction",
        "selection = .importPackage",
        "NavigationSplitView(columnVisibility:",
    ]:
        if token not in root:
            fail(f"MacRootView missing shared-state/navigation token: {token}")
    if "MacLockedDestinationView(\n                destination: selection,\n                titleKey: \"mac.import.locked.sessions.title\"" in root:
        fail("Session Browser should no longer be a locked placeholder in Task-028a")
    if "RootNavigationView" in root:
        fail("macOS viewer must not reuse iOS RootNavigationView")


def ensure_import_reuses_view_model() -> None:
    import_view = read("macOS/Features/Import/MacImportView.swift")
    for token in [
        "@ObservedObject private var viewModel",
        "init(viewModel: MacPackageImportViewModel",
        "NSOpenPanel",
        "allowedContentTypes = [.data]",
    ]:
        if token not in import_view:
            fail(f"MacImportView missing shared VM or NSOpenPanel token: {token}")
    if "@StateObject private var viewModel" in import_view:
        fail("MacImportView must not own a separate StateObject; browser and import need shared preview state")


def ensure_session_browser() -> None:
    browser = read("macOS/Features/SessionBrowser/MacSessionBrowserView.swift")
    detail = read("macOS/Features/SessionBrowser/MacSessionDetailView.swift")
    model = read("macOS/Features/SessionBrowser/MacSessionViewerModel.swift")
    sparkline = read("macOS/Features/SessionBrowser/MacSpeedSparklineView.swift")
    route_preview = read("macOS/Features/SessionBrowser/MacRoutePreviewView.swift")
    preview = read("macOS/Features/Import/MacPackagePreviewView.swift")

    for token in [
        "MacPackageImportPreview?",
        "preview?.payload.sessions.map(MacSessionViewerModel.init)",
        "selectedSessionID",
        "MacCurrentPackageSessionSummaryView",
        "MacPackageSessionSelectorButton",
        "MacSessionDetailView",
        "openImportAction",
        "mac.viewer.empty.title",
        "mac.viewer.package.current",
        "mac.viewer.package.single_session",
        "mac.viewer.package.session_count.format",
        "ScrollView",
        "VStack(alignment: .leading, spacing: 18)",
    ]:
        if token not in browser:
            fail(f"MacSessionBrowserView missing token: {token}")
    if ".frame(width: 238)" in browser or "sessionList(preview:" in browser:
        fail("MacSessionBrowserView should no longer use a separate middle session-list column")
    for token in [
        "MacSpeedSparklineView",
        "displayMetrics",
        "usesDerivedMetrics",
        "routeSummary",
        "routePoints",
        "MacRoutePreviewView",
        "visualizationSection",
        "mac.viewer.privacy.readonly",
        "mac.viewer.route.map_deferred",
        "mac.viewer.detail.title",
        "compactGridColumns",
        "minimum: 172",
        "minHeight: 58",
    ]:
        if token not in detail:
            fail(f"MacSessionDetailView missing token: {token}")
    if ".font(.largeTitle.bold())" in detail or "private var header" in detail:
        fail("MacSessionDetailView should not duplicate the package-session hero; the top summary belongs in MacSessionBrowserView")
    for token in [
        "MacSessionViewerModel",
        "MacRoutePoint",
        "MacRouteVisualizationQuality",
        "deriveMetrics",
        "deriveDistanceKilometers",
        "motionSamples.isEmpty ? session.motionSamples : motionSamples",
        "shouldUseDerivedMetrics",
        "distanceMetersBetween",
        "downsample(points:",
    ]:
        if token not in model:
            fail(f"MacSessionViewerModel missing derived metric token: {token}")
    for token in ["Path", "speedPath", "gridLines", "mac.viewer.sparkline.empty", ".frame(height: 132)"]:
        if token not in sparkline:
            fail(f"MacSpeedSparklineView missing token: {token}")
    for token in ["MacRoutePreviewView", "routePath", "routeGrid", "MacRoutePreviewPill", "mac.viewer.route.preview.title", "mac.viewer.route.preview.not_mapmatched"]:
        if token not in route_preview:
            fail(f"MacRoutePreviewView missing token: {token}")
    if "MacSessionViewerModel" not in preview or "viewer_ready" not in preview:
        fail("MacPackagePreviewView should use Task-028a viewer-derived metrics and no longer advertise viewer as locked")


def ensure_boundaries() -> None:
    project = read("SkateTrack.xcodeproj/project.pbxproj")
    for token in FORBIDDEN_PROJECT_TOKENS:
        if token in project:
            fail(f"project contains deferred document/capability token: {token}")

    for path in [
        "macOS/Features/SessionBrowser/MacSessionBrowserView.swift",
        "macOS/Features/SessionBrowser/MacSessionDetailView.swift",
        "macOS/Features/SessionBrowser/MacSessionViewerModel.swift",
        "macOS/Features/SessionBrowser/MacSpeedSparklineView.swift",
        "macOS/Features/SessionBrowser/MacRoutePreviewView.swift",
    ]:
        text = read(path)
        for token in FORBIDDEN_VIEWER_TOKENS:
            if token in text:
                fail(f"forbidden token {token!r} found in {path}")


def ensure_project_membership() -> None:
    project = read("SkateTrack.xcodeproj/project.pbxproj")
    for token in PROJECT_MEMBERSHIP:
        if token not in project:
            fail(f"missing project membership for {token}")
    mac_sources = re.search(r"A2EF5573281ED5113A3645DD /\* Sources \*/ = \{.*?files = \((.*?)\);", project, re.S)
    if not mac_sources:
        fail("could not locate macOS sources build phase")
    sources_text = mac_sources.group(1)
    for token in [f"{name} in Sources" for name in PROJECT_MEMBERSHIP]:
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
            "docs/history/DEV_LOG.md",
            "docs/reference/FILE_STRUCTURE.md",
            "docs/process/DEVELOPMENT_RULES.md",
            "docs/adr/ADR-INDEX.md",
        ]
    )
    for token in [
        "Task-028a",
        "Read-only Session Viewer Foundation",
        "MacSessionBrowserView",
        "derived metrics",
        "MacSpeedSparklineView",
        "compact macOS dashboard",
        "layout polish",
        "right-side stacked layout",
        "read-only",
        "Task-028b",
        "Route / Chart Visualization Foundation",
        "MacRoutePreviewView",
        "custom UTType",
    ]:
        if token not in docs:
            fail(f"documentation missing token: {token}")


def main() -> int:
    ensure_files()
    ensure_root_shared_preview_state()
    ensure_import_reuses_view_model()
    ensure_session_browser()
    ensure_boundaries()
    ensure_project_membership()
    ensure_localization()
    ensure_docs()
    print("Task-028a macOS session viewer check passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
