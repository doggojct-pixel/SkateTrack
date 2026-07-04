#!/usr/bin/env python3
"""Verify Task-030e-MacViewer-007B iOS route visual parity + expanded inspection."""
from __future__ import annotations
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def fail(message: str) -> None:
    print(f"Task-030e 007B route visual inspection check failed: {message}", file=sys.stderr)
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

REQUIRED_FILES = [
    "macOS/Features/SessionBrowser/MacRouteVisualStyle.swift",
    "macOS/Features/SessionBrowser/MacRouteInspectionView.swift",
    "macOS/Features/SessionBrowser/MacRouteInspectionWindowPresenter.swift",
    "macOS/Features/SessionBrowser/MacRouteMapContextView.swift",
    "macOS/Features/SessionBrowser/MacRoutePreviewView.swift",
    "macOS/Features/SessionBrowser/MacSessionViewerModel.swift",
    "macOS/Features/SessionBrowser/MacRouteDisplayPipeline.swift",
    "SkateTrack.xcodeproj/project.pbxproj",
    "Shared/Localization/en.lproj/Localizable.strings",
    "Shared/Localization/zh-Hant.lproj/Localizable.strings",
    "Shared/Localization/ja.lproj/Localizable.strings",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
]

STYLE_TOKENS = [
    "// [協作區] macOS/Features/SessionBrowser/MacRouteVisualStyle.swift",
    "enum MacRouteVisualStyle",
    "fluorescentPinkGlow",
    "brightOrangeAccent",
    "trustedGreenRoute",
    "startMarker",
    "finishMarker",
    "Color(red: 1.0, green: 0.2, blue: 0.6)",
    "Color(red: 1.0, green: 0.56, blue: 0.0)",
    "Color(red: 0.0, green: 0.831, blue: 0.667)",
]


PIPELINE_TOKENS = [
    "// [協作區] macOS/Features/SessionBrowser/MacRouteDisplayPipeline.swift",
    "enum MacSessionMetricsDeriver",
    "private static func smoothDisplayCoordinate",
]

MODEL_TOKENS = [
    "struct MacRoutePoint: Identifiable, Equatable",
    "let confidence: RouteSegmentConfidence",
    "let hasStartupWarmup: Bool",
]

INSPECTION_TOKENS = [
    "// [協作區] macOS/Features/SessionBrowser/MacRouteInspectionView.swift",
    "struct MacRouteInspectionView: View",
    "MacRouteMapContextView(points: points, summary: summary)",
    "mac.viewer.route.inspect.fit_bounds",
    "mac.viewer.route.inspect.resizable_note",
    "MacRouteVisualLegendView(isCompact: false)",
    "MacRouteInspectionMetricView",
    "mac.viewer.route.inspect.readonly",
]

WINDOW_PRESENTER_TOKENS = [
    "// [協作區] macOS/Features/SessionBrowser/MacRouteInspectionWindowPresenter.swift",
    "final class MacRouteInspectionWindowPresenter",
    "styleMask: [.titled, .closable, .miniaturizable, .resizable]",
    "window.minSize = NSSize(width: 860, height: 680)",
    "NSHostingView(rootView: contentView)",
    "openWindows.append(window)",
]

PREVIEW_TOKENS = [
    "openRouteInspectorWindow",
    "MacRouteInspectionWindowPresenter.shared.open(points: points, summary: summary)",
    "MacRouteVisualLegendView(isCompact: true)",
    "expandedInspectionButton",
    "mac.viewer.route.inspect.open",
]

MAP_TOKENS = [
    "routeOverlayStyles: [ObjectIdentifier: MacRouteVisualStyle]",
    "fluorescentPinkGlow",
    "brightOrangeAccent",
    "trustedGreenRoute",
    "MacRouteVisualStyle.startMarker.appKitColor",
    "MacRouteVisualStyle.finishMarker.appKitColor",
    "setVisibleMapRect",
    "showsUserLocation = false",
]

PROJECT_TOKENS = [
    "30E900000000000000000001 /* MacRouteVisualStyle.swift */ = {isa = PBXFileReference;",
    "30EA00000000000000000001 /* MacRouteInspectionView.swift */ = {isa = PBXFileReference;",
    "30EC00000000000000000001 /* MacRouteInspectionWindowPresenter.swift */ = {isa = PBXFileReference;",
    "30E900000000000000000101 /* MacRouteVisualStyle.swift in Sources */ = {isa = PBXBuildFile;",
    "30EA00000000000000000101 /* MacRouteInspectionView.swift in Sources */ = {isa = PBXBuildFile;",
    "30EC00000000000000000101 /* MacRouteInspectionWindowPresenter.swift in Sources */ = {isa = PBXBuildFile;",
    "30EB00000000000000000101 /* MacRouteDisplayPipeline.swift in Sources */ = {isa = PBXBuildFile;",
    "30E900000000000000000001 /* MacRouteVisualStyle.swift */,",
    "30EA00000000000000000001 /* MacRouteInspectionView.swift */,",
    "30EC00000000000000000001 /* MacRouteInspectionWindowPresenter.swift */,",
    "30EB00000000000000000001 /* MacRouteDisplayPipeline.swift */,",
]

LOCALIZATION_KEYS = [
    "mac.viewer.route.inspect.open",
    "mac.viewer.route.inspect.title",
    "mac.viewer.route.inspect.subtitle",
    "mac.viewer.route.inspect.resizable_note",
    "mac.viewer.route.inspect.close",
    "mac.viewer.route.inspect.fit_bounds",
    "mac.viewer.route.inspect.metadata.title",
    "mac.viewer.route.inspect.metadata.samples",
    "mac.viewer.route.inspect.metadata.unique",
    "mac.viewer.route.inspect.metadata.distance",
    "mac.viewer.route.inspect.metadata.quality",
    "mac.viewer.route.inspect.readonly",
    "mac.viewer.route.legend.title",
    "mac.viewer.route.legend.green",
    "mac.viewer.route.legend.orange",
    "mac.viewer.route.legend.pink",
    "mac.viewer.route.legend.start",
    "mac.viewer.route.legend.finish",
    "mac.viewer.route.visual_parity.note",
    "mac.accessibility.route_inspection.label",
    "mac.accessibility.route_inspection.hint",
]

DOC_TOKENS = [
    "Task-030e-MacViewer-007B",
    "iOS Route Visual Parity + Expanded Route Inspection",
    "MacRouteVisualStyle",
    "MacRouteInspectionView",
    "MacRouteInspectionWindowPresenter",
    "resizable route inspection window",
    "fluorescent pink",
    "bright orange",
    "green route line",
    "no route geometry mutation",
    "no trusted metrics mutation",
]

FORBIDDEN = [
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
    "UTExportedTypeDeclarations",
    "CFBundleDocumentTypes",
    "LSSupportsOpeningDocumentsInPlace",
]

CHECKED_SOURCE_FILES = [
    "macOS/Features/SessionBrowser/MacRouteVisualStyle.swift",
    "macOS/Features/SessionBrowser/MacRouteInspectionView.swift",
    "macOS/Features/SessionBrowser/MacRouteInspectionWindowPresenter.swift",
    "macOS/Features/SessionBrowser/MacRouteMapContextView.swift",
    "macOS/Features/SessionBrowser/MacRoutePreviewView.swift",
    "macOS/Features/SessionBrowser/MacSessionViewerModel.swift",
    "macOS/Features/SessionBrowser/MacRouteDisplayPipeline.swift",
]


def main() -> int:
    for rel in REQUIRED_FILES:
        if not (ROOT / rel).exists():
            fail(f"missing required file: {rel}")

    style = read("macOS/Features/SessionBrowser/MacRouteVisualStyle.swift")
    inspection = read("macOS/Features/SessionBrowser/MacRouteInspectionView.swift")
    window_presenter = read("macOS/Features/SessionBrowser/MacRouteInspectionWindowPresenter.swift")
    preview = read("macOS/Features/SessionBrowser/MacRoutePreviewView.swift")
    map_context = read("macOS/Features/SessionBrowser/MacRouteMapContextView.swift")
    model = read("macOS/Features/SessionBrowser/MacSessionViewerModel.swift")
    pipeline = read("macOS/Features/SessionBrowser/MacRouteDisplayPipeline.swift")
    project = read("SkateTrack.xcodeproj/project.pbxproj")

    require("MacRouteVisualStyle.swift", style, STYLE_TOKENS)
    require("MacRouteInspectionView.swift", inspection, INSPECTION_TOKENS)
    require("MacRouteInspectionWindowPresenter.swift", window_presenter, WINDOW_PRESENTER_TOKENS)
    require("MacRoutePreviewView.swift", preview, PREVIEW_TOKENS)
    require("MacRouteMapContextView.swift", map_context, MAP_TOKENS)
    require("MacSessionViewerModel.swift", model, MODEL_TOKENS)
    require("MacRouteDisplayPipeline.swift", pipeline, PIPELINE_TOKENS)
    require("project.pbxproj", project, PROJECT_TOKENS)

    mac_sources = re.search(r"A2EF5573281ED5113A3645DD /\* Sources \*/ = \{.*?files = \((.*?)\);", project, re.S)
    if not mac_sources:
        fail("could not locate macOS sources build phase")
    sources_text = mac_sources.group(1)
    for token in ["MacRouteVisualStyle.swift in Sources", "MacRouteInspectionView.swift in Sources", "MacRouteInspectionWindowPresenter.swift in Sources", "MacRouteDisplayPipeline.swift in Sources"]:
        if token not in sources_text:
            fail(f"macOS sources phase missing {token}")

    for rel in CHECKED_SOURCE_FILES:
        text = read(rel)
        if len(text.splitlines()) > 500:
            fail(f"{rel} exceeds 500 lines")
        reject(rel, text, FORBIDDEN)
    reject("project.pbxproj", project, FORBIDDEN)

    for lang in ["en", "zh-Hant", "ja"]:
        text = read(f"Shared/Localization/{lang}.lproj/Localizable.strings")
        for key in LOCALIZATION_KEYS:
            if f'"{key}" = ' not in text:
                fail(f"missing localization key {key} in {lang}")

    docs = "\n".join(read(path) for path in [
        "docs/history/DEV_LOG.md",
        "docs/reference/FILE_STRUCTURE.md",
        "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    ])
    require("docs", docs, DOC_TOKENS)

    print("Task-030e 007B route visual inspection check passed")
    return 0

if __name__ == "__main__":
    sys.exit(main())
