#!/usr/bin/env python3
"""Verify Task-030e-008-1 macOS elevation profile + total ascent display alignment."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "macOS/Features/SessionBrowser/MacSessionDetailView.swift",
    "macOS/Features/SessionBrowser/MacSessionViewerModel.swift",
    "macOS/Features/SessionBrowser/MacSpeedSparklineView.swift",
    "macOS/Features/SessionBrowser/MacElevationDisplayPipeline.swift",
    "SkateTrack.xcodeproj/project.pbxproj",
    "scripts/verify_task030e_elevation_profile.py",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
]

CHECKED_SWIFT_FILES = [
    "macOS/Features/SessionBrowser/MacSessionDetailView.swift",
    "macOS/Features/SessionBrowser/MacSessionViewerModel.swift",
    "macOS/Features/SessionBrowser/MacSpeedSparklineView.swift",
    "macOS/Features/SessionBrowser/MacElevationDisplayPipeline.swift",
]

DETAIL_TOKENS = [
    "summary.metric.elevationGain",
    "formattedElevation(model.displayMetrics.elevationGainMeters)",
    "MacElevationProfileView(points: model.elevationPoints)",
    "unit.length.meter.valueFormat",
]

MODEL_TOKENS = [
    "let elevationPoints: [MacElevationPoint]",
    "MacElevationDisplayPipeline.elevationPoints(session: session, samples: samples)",
    "struct MacElevationPoint: Identifiable, Equatable",
    "let elevationMeters: Double",
    "let segmentID: Int",
]

PIPELINE_TOKENS = [
    "enum MacElevationDisplayPipeline",
    "static func elevationPoints(session: SessionData, samples: [MotionSample])",
    "trustedBarometerRelativeAltitude",
    "trustedCoreLocationAbsoluteAltitude",
    "trustedDebugAltitude",
    "smoothedElevationPoints",
    "downsample(elevationPoints:",
    "display-only elevation profile points",
]

CHART_TOKENS = [
    "struct MacElevationProfileView: View",
    "mac.viewer.chart.elevation.title",
    "mac.viewer.chart.elevation.empty",
    "elevationPath(points:",
    "unit.length.meter.valueFormat",
    "mac.viewer.chart.elevation.range.format",
    "MacElevationChartSegment",
]

LOCALIZATION_KEYS = [
    "summary.metric.elevationGain",
    "mac.viewer.chart.elevation.title",
    "mac.viewer.chart.elevation.empty",
    "mac.viewer.chart.elevation.hint",
    "unit.length.meter.valueFormat",
    "mac.viewer.chart.elevation.range.format",
]

DOC_TOKENS = [
    "Task-030e-MacViewer-008-1 Elevation Profile + Total Ascent Display Alignment",
    "MacElevationDisplayPipeline",
    "MacElevationProfileView",
    "summary.metric.elevationGain",
    "Shared Activity Visualization Pipeline extraction remains deferred",
    "no trusted metrics mutation",
]

FORBIDDEN_TOKENS = [
    "SessionRepository",
    "PersistenceController",
    "NSManagedObjectContext",
    "CoreData",
    "SkateTrackPackageWriter",
    "snapToRoad",
    "roadMatch",
    "mapMatch",
    "reconstructRoute",
    "mutateRouteGeometry",
    "routeGeometryMutationApplied = true",
    "trustedMetricsMutationApplied = true",
    "estimatedRouteDisplayEnabled = true",
    "showsUserLocation = true",
    "requestWhenInUseAuthorization",
    "CLLocationManager",
]


def fail(message: str) -> None:
    print(f"Task-030e-008-1 elevation profile check failed: {message}", file=sys.stderr)
    sys.exit(1)


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


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
        valid_headers = {
            "// [協作區] " + Path(rel).name,
            "// [協作區] " + rel,
            "// [自主區] " + Path(rel).name,
            "// [自主區] " + rel,
        }
        if not lines or lines[0] not in valid_headers:
            fail(f"{rel} missing collaboration/autonomous header on first line")
        if len(lines) > 500:
            fail(f"{rel} exceeds 500 lines: {len(lines)}")


def ensure_project_membership() -> None:
    project = read("SkateTrack.xcodeproj/project.pbxproj")
    require("project.pbxproj", project, [
        "MacElevationDisplayPipeline.swift",
        "MacElevationDisplayPipeline.swift in Sources",
    ])
    mac_sources = re.search(r"A2EF5573281ED5113A3645DD /\* Sources \*/ = \{.*?files = \((.*?)\);", project, re.S)
    if not mac_sources:
        fail("could not locate macOS Sources build phase")
    if "MacElevationDisplayPipeline.swift in Sources" not in mac_sources.group(1):
        fail("macOS Sources build phase missing MacElevationDisplayPipeline.swift")


def ensure_localization_key_reuse() -> None:
    for lang in ["en", "zh-Hant", "ja"]:
        text = read(f"Shared/Localization/{lang}.lproj/Localizable.strings")
        for key in LOCALIZATION_KEYS:
            if f'"{key}" = ' not in text:
                fail(f"missing localization key {key} in {lang}")


def main() -> int:
    ensure_files()
    detail = read("macOS/Features/SessionBrowser/MacSessionDetailView.swift")
    model = read("macOS/Features/SessionBrowser/MacSessionViewerModel.swift")
    chart = read("macOS/Features/SessionBrowser/MacSpeedSparklineView.swift")
    pipeline = read("macOS/Features/SessionBrowser/MacElevationDisplayPipeline.swift")

    require("MacSessionDetailView.swift", detail, DETAIL_TOKENS)
    require("MacSessionViewerModel.swift", model, MODEL_TOKENS)
    require("MacSpeedSparklineView.swift", chart, CHART_TOKENS)
    require("MacElevationDisplayPipeline.swift", pipeline, PIPELINE_TOKENS)
    ensure_project_membership()
    ensure_swift_headers_and_line_counts()
    ensure_localization_key_reuse()

    docs = "\n".join(read(path) for path in ["docs/history/DEV_LOG.md", "docs/reference/FILE_STRUCTURE.md"])
    require("docs", docs, DOC_TOKENS)

    for rel in CHECKED_SWIFT_FILES:
        reject(rel, read(rel), FORBIDDEN_TOKENS)

    project = read("SkateTrack.xcodeproj/project.pbxproj")
    reject("project.pbxproj", project, ["UTExportedTypeDeclarations", "CFBundleDocumentTypes", "LSSupportsOpeningDocumentsInPlace"])

    print("Task-030e-008-1 elevation profile check passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
