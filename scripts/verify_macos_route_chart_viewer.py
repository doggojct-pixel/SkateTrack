#!/usr/bin/env python3
"""Verify Task-028b macOS route / chart visualization foundation."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "macOS/Features/SessionBrowser/MacSessionBrowserView.swift",
    "macOS/Features/SessionBrowser/MacSessionDetailView.swift",
    "macOS/Features/SessionBrowser/MacSessionViewerModel.swift",
    "macOS/Features/SessionBrowser/MacSpeedSparklineView.swift",
    "macOS/Features/SessionBrowser/MacRoutePreviewView.swift",
    "scripts/verify_macos_route_chart_viewer.py",
    "docs/adr/ADR-INDEX.md",
]

LOCALIZATION_KEYS = [
    "mac.viewer.chart.speed.title",
    "mac.viewer.route.data.title",
    "mac.viewer.route.unique_points",
    "mac.viewer.route.preview.title",
    "mac.viewer.route.preview.empty",
    "mac.viewer.route.preview.not_mapmatched",
    "mac.viewer.route.quality.unavailable",
    "mac.viewer.route.quality.limited",
    "mac.viewer.route.quality.usable",
]

FORBIDDEN_VIEWER_TOKENS = [
    "MapKit",
    "MKMapView",
    "Charts",
    "Chart(",
    "FileDocument",
    "SessionRepository",
    "PersistenceController",
    "GoogleSignIn",
    "GIDSignIn",
    "CloudKit",
    "StoreKit",
]

FORBIDDEN_PROJECT_TOKENS = [
    "UTExportedTypeDeclarations",
    "CFBundleDocumentTypes",
    "LSSupportsOpeningDocumentsInPlace",
    "com.apple.developer.icloud-container-identifiers",
    "com.apple.developer.ubiquity-container-identifiers",
]


def fail(message: str) -> None:
    print(f"Task-028b macOS route/chart viewer check failed: {message}", file=sys.stderr)
    sys.exit(1)


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def ensure_files() -> None:
    missing = [path for path in REQUIRED_FILES if not (ROOT / path).exists()]
    if missing:
        fail("missing required files: " + ", ".join(missing))


def ensure_project_membership() -> None:
    project = read("SkateTrack.xcodeproj/project.pbxproj")
    for token in ["MacRoutePreviewView.swift", "MacSpeedSparklineView.swift", "MacSessionViewerModel.swift"]:
        if token not in project:
            fail(f"missing project membership token: {token}")
    mac_sources = re.search(r"A2EF5573281ED5113A3645DD /\* Sources \*/ = \{.*?files = \((.*?)\);", project, re.S)
    if not mac_sources:
        fail("could not locate macOS sources build phase")
    sources_text = mac_sources.group(1)
    for token in ["MacRoutePreviewView.swift in Sources", "MacSpeedSparklineView.swift in Sources"]:
        if token not in sources_text:
            fail(f"macOS sources phase missing {token}")


def ensure_route_foundation() -> None:
    detail = read("macOS/Features/SessionBrowser/MacSessionDetailView.swift")
    model = read("macOS/Features/SessionBrowser/MacSessionViewerModel.swift")
    route_preview = read("macOS/Features/SessionBrowser/MacRoutePreviewView.swift")
    speed_chart = read("macOS/Features/SessionBrowser/MacSpeedSparklineView.swift")

    for token in [
        "visualizationSection",
        "MacRoutePreviewView(points: model.routePoints, summary: model.routeSummary)",
        "MacSpeedSparklineView(points: model.speedPoints)",
        "mac.viewer.route.data.title",
        "mac.viewer.route.unique_points",
        "LazyVGrid(columns: visualizationColumns",
    ]:
        if token not in detail:
            fail(f"MacSessionDetailView missing visualization token: {token}")

    for token in [
        "MacRoutePoint",
        "MacRouteVisualizationQuality",
        "routePoints",
        "uniqueRoutePointCount",
        "routeQuality(",
        "distanceMetersBetween",
        "downsample(routePoints:",
    ]:
        if token not in model:
            fail(f"MacSessionViewerModel missing route derivation token: {token}")

    for token in [
        "struct MacRoutePreviewView",
        "routePath(in:",
        "routeGrid(in:",
        "MacRoutePreviewPill",
        "mac.viewer.route.preview.not_mapmatched",
        "MacRouteVisualizationQuality",
    ]:
        if token not in route_preview:
            fail(f"MacRoutePreviewView missing token: {token}")

    for token in ["mac.viewer.chart.speed.title", "speedPath(in:", ".frame(height: 132)"]:
        if token not in speed_chart:
            fail(f"MacSpeedSparklineView missing Task-028b chart token: {token}")


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
        "Task-028b",
        "Route / Chart Visualization Foundation",
        "MacRoutePreviewView",
        "Lightweight SwiftUI Path route",
        "lightweight SwiftUI Path",
        "read-only",
        "MapKit",
        "Charts",
    ]:
        if token not in docs:
            fail(f"documentation missing token: {token}")


def main() -> int:
    ensure_files()
    ensure_project_membership()
    ensure_route_foundation()
    ensure_boundaries()
    ensure_localization()
    ensure_docs()
    print("Task-028b macOS route/chart viewer check passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
