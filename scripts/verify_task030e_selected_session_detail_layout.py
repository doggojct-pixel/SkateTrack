#!/usr/bin/env python3
"""Verify Task-030e-MacViewer-008 selected session detail layout alignment."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "macOS/Features/SessionBrowser/MacSessionDetailView.swift",
    "macOS/Features/SessionBrowser/MacRoutePreviewView.swift",
    "macOS/Features/SessionBrowser/MacRouteInspectionView.swift",
    "macOS/Features/SessionBrowser/MacRouteInspectionWindowPresenter.swift",
    "macOS/Features/SessionBrowser/MacRouteMapContextView.swift",
    "macOS/Features/SessionBrowser/MacSpeedSparklineView.swift",
    "SkateTrack.xcodeproj/project.pbxproj",
    "Shared/Localization/en.lproj/Localizable.strings",
    "Shared/Localization/zh-Hant.lproj/Localizable.strings",
    "Shared/Localization/ja.lproj/Localizable.strings",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
]

DETAIL_TOKENS = [
    "Task-030e-MacViewer-008 selected-session detail layout alignment",
    "private var visualizationSection: some View",
    "ViewThatFits(in: .horizontal)",
    "routeColumn",
    "sessionSideColumn",
    "MacRoutePreviewView(points: model.routePoints, summary: model.routeSummary)",
    "MacSpeedSparklineView(points: model.speedPoints)",
    "routeDataSection",
    "privacySection",
    "mac.viewer.route.map_deferred",
    "mac.viewer.privacy.readonly",
    ".frame(minWidth: 540, maxWidth: .infinity, alignment: .topLeading)",
    ".frame(width: 360, alignment: .topLeading)",
]

PREVIEW_TOKENS = [
    "openRouteInspectorWindow",
    "MacRouteInspectionWindowPresenter.shared.open(points: points, summary: summary)",
    "expandedInspectionButton",
    "MacRouteVisualLegendView(isCompact: true)",
]

INSPECTION_TOKENS = [
    "struct MacRouteInspectionView: View",
    "closeAction: @escaping () -> Void",
    "mac.viewer.route.inspect.resizable_note",
    "GeometryReader",
    "mapPanel(height: mapHeight(for: proxy.size.height))",
    "mapHeight(for availableHeight: CGFloat)",
    "MacRouteMapContextView(points: points, summary: summary)",
]

WINDOW_TOKENS = [
    "final class MacRouteInspectionWindowPresenter",
    "styleMask: [.titled, .closable, .miniaturizable, .resizable]",
    "window.minSize = NSSize(width: 860, height: 680)",
    "window.isReleasedWhenClosed = false",
    "NSHostingView(rootView: contentView)",
    "openWindows.append(window)",
    "windowWillClose",
]

PROJECT_TOKENS = [
    "30EC00000000000000000001 /* MacRouteInspectionWindowPresenter.swift */ = {isa = PBXFileReference;",
    "30EC00000000000000000101 /* MacRouteInspectionWindowPresenter.swift in Sources */ = {isa = PBXBuildFile;",
    "30EC00000000000000000001 /* MacRouteInspectionWindowPresenter.swift */,",
    "30EC00000000000000000101 /* MacRouteInspectionWindowPresenter.swift in Sources */,",
]

LOCALIZATION_KEYS = [
    "mac.viewer.route.inspect.resizable_note",
    "mac.viewer.route.inspect.open",
    "mac.viewer.route.inspect.title",
    "mac.viewer.route.inspect.close",
]

DOC_TOKENS = [
    "Task-030e-MacViewer-008",
    "Selected Session Detail Layout Alignment",
    "MacRouteInspectionWindowPresenter",
    "resizable route inspection window",
    "ViewThatFits",
    "no route geometry mutation",
    "no trusted metrics mutation",
]

FORBIDDEN_TOKENS = [
    "showsUserLocation = true",
    "CLLocationManager",
    "requestWhenInUseAuthorization",
    "requestAlwaysAuthorization",
    "snapToRoad",
    "mapMatch",
    "roadMatch",
    "reconstructRoute",
    "mutateRouteGeometry",
    "routeGeometryMutationApplied = true",
    "trustedMetricsMutationApplied = true",
    "estimatedRouteDisplayEnabled = true",
    "PersistenceController",
    "SessionRepository",
    "CoreData",
    "UTExportedTypeDeclarations",
    "CFBundleDocumentTypes",
    "LSSupportsOpeningDocumentsInPlace",
]

CHECKED_SWIFT_FILES = [
    "macOS/Features/SessionBrowser/MacSessionDetailView.swift",
    "macOS/Features/SessionBrowser/MacRoutePreviewView.swift",
    "macOS/Features/SessionBrowser/MacRouteInspectionView.swift",
    "macOS/Features/SessionBrowser/MacRouteInspectionWindowPresenter.swift",
]


def fail(message: str) -> None:
    print(f"Task-030e 008 selected session detail layout check failed: {message}", file=sys.stderr)
    sys.exit(1)


def read(rel: str) -> str:
    path = ROOT / rel
    if not path.exists():
        fail(f"missing required file: {rel}")
    return path.read_text(encoding="utf-8")


def require(name: str, text: str, tokens: list[str]) -> None:
    missing = [token for token in tokens if token not in text]
    if missing:
        fail(f"{name} missing token(s): " + ", ".join(missing))


def reject(name: str, text: str, tokens: list[str]) -> None:
    present = [token for token in tokens if token in text]
    if present:
        fail(f"{name} contains forbidden token(s): " + ", ".join(present))


def ensure_files() -> None:
    missing = [rel for rel in REQUIRED_FILES if not (ROOT / rel).exists()]
    if missing:
        fail("missing required files: " + ", ".join(missing))


def ensure_swift_headers_and_line_counts() -> None:
    for rel in CHECKED_SWIFT_FILES:
        text = read(rel)
        lines = text.splitlines()
        if not lines or lines[0] not in {"// [協作區] " + Path(rel).name, "// [協作區] " + rel, "// [自主區] " + Path(rel).name, "// [自主區] " + rel}:
            fail(f"{rel} missing collaboration/autonomous header on first line")
        if len(lines) > 500:
            fail(f"{rel} exceeds 500 lines: {len(lines)}")


def ensure_project_membership(project: str) -> None:
    require("project.pbxproj", project, PROJECT_TOKENS)
    mac_sources = re.search(r"A2EF5573281ED5113A3645DD /\* Sources \*/ = \{.*?files = \((.*?)\);", project, re.S)
    if not mac_sources:
        fail("could not locate macOS Sources build phase")
    if "MacRouteInspectionWindowPresenter.swift in Sources" not in mac_sources.group(1):
        fail("macOS Sources build phase missing MacRouteInspectionWindowPresenter.swift")


def ensure_localization() -> None:
    for lang in ["en", "zh-Hant", "ja"]:
        text = read(f"Shared/Localization/{lang}.lproj/Localizable.strings")
        for key in LOCALIZATION_KEYS:
            if f'"{key}" = ' not in text:
                fail(f"missing localization key {key} in {lang}")


def main() -> int:
    ensure_files()
    detail = read("macOS/Features/SessionBrowser/MacSessionDetailView.swift")
    preview = read("macOS/Features/SessionBrowser/MacRoutePreviewView.swift")
    inspection = read("macOS/Features/SessionBrowser/MacRouteInspectionView.swift")
    window = read("macOS/Features/SessionBrowser/MacRouteInspectionWindowPresenter.swift")
    map_context = read("macOS/Features/SessionBrowser/MacRouteMapContextView.swift")
    project = read("SkateTrack.xcodeproj/project.pbxproj")

    require("MacSessionDetailView.swift", detail, DETAIL_TOKENS)
    require("MacRoutePreviewView.swift", preview, PREVIEW_TOKENS)
    require("MacRouteInspectionView.swift", inspection, INSPECTION_TOKENS)
    require("MacRouteInspectionWindowPresenter.swift", window, WINDOW_TOKENS)
    require("MacRouteMapContextView.swift", map_context, ["showsUserLocation = false", "setVisibleMapRect"])
    ensure_project_membership(project)
    ensure_swift_headers_and_line_counts()
    ensure_localization()

    docs = "\n".join(read(path) for path in ["docs/history/DEV_LOG.md", "docs/reference/FILE_STRUCTURE.md"])
    require("docs", docs, DOC_TOKENS)

    for rel in CHECKED_SWIFT_FILES + ["macOS/Features/SessionBrowser/MacRouteMapContextView.swift"]:
        reject(rel, read(rel), FORBIDDEN_TOKENS)
    reject("project.pbxproj", project, ["UTExportedTypeDeclarations", "CFBundleDocumentTypes", "LSSupportsOpeningDocumentsInPlace"])

    print("Task-030e 008 selected session detail layout check passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
