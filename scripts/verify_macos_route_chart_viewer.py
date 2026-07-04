#!/usr/bin/env python3
"""Verify Task-028b/030e macOS route / chart visualization guardrails."""
from __future__ import annotations
import re, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
def fail(m): print(f"Task-028b/030e macOS route/chart viewer check failed: {m}", file=sys.stderr); sys.exit(1)
def read(p): return (ROOT/p).read_text(encoding="utf-8")
REQUIRED_FILES=["macOS/Features/SessionBrowser/MacSessionBrowserView.swift","macOS/Features/SessionBrowser/MacSessionDetailView.swift","macOS/Features/SessionBrowser/MacSessionViewerModel.swift","macOS/Features/SessionBrowser/MacSpeedSparklineView.swift","macOS/Features/SessionBrowser/MacRoutePreviewView.swift","macOS/Features/SessionBrowser/MacRouteMapContextView.swift","macOS/Features/SessionBrowser/MacRouteDisplayPipeline.swift","scripts/verify_macos_route_chart_viewer.py","docs/adr/ADR-INDEX.md"]
LOCALIZATION_KEYS=["mac.viewer.chart.speed.title","mac.viewer.route.data.title","mac.viewer.route.unique_points","mac.viewer.route.preview.title","mac.viewer.route.preview.empty","mac.viewer.route.preview.not_mapmatched","mac.viewer.route.preview.readonly_mapkit","mac.viewer.route.quality.unavailable","mac.viewer.route.quality.limited","mac.viewer.route.quality.usable"]
FORBIDDEN_VIEWER_TOKENS=["Charts","Chart(","FileDocument","SessionRepository","PersistenceController","GoogleSignIn","GIDSignIn","CloudKit","StoreKit"]
FORBIDDEN_PROJECT_TOKENS=["UTExportedTypeDeclarations","CFBundleDocumentTypes","LSSupportsOpeningDocumentsInPlace","com.apple.developer.icloud-container-identifiers","com.apple.developer.ubiquity-container-identifiers"]
FORBIDDEN_ROUTE_MUTATION_TOKENS=["snapToRoad","roadMatch","mapMatch","reconstructRoute","mutateRouteGeometry","routeGeometryMutationApplied = true","trustedMetricsMutationApplied = true","estimatedRouteDisplayEnabled = true","showsUserLocation = true","requestWhenInUseAuthorization","CLLocationManager"]
def ensure_files():
    missing=[p for p in REQUIRED_FILES if not (ROOT/p).exists()]
    if missing: fail("missing required files: "+", ".join(missing))
def ensure_project_membership():
    project=read("SkateTrack.xcodeproj/project.pbxproj")
    for t in ["MacRoutePreviewView.swift","MacRouteMapContextView.swift","MacRouteDisplayPipeline.swift","MacSpeedSparklineView.swift","MacSessionViewerModel.swift"]:
        if t not in project: fail(f"missing project membership token: {t}")
    m=re.search(r"A2EF5573281ED5113A3645DD /\* Sources \*/ = \{.*?files = \((.*?)\);", project, re.S)
    if not m: fail("could not locate macOS sources build phase")
    for t in ["MacRoutePreviewView.swift in Sources","MacRouteMapContextView.swift in Sources","MacRouteDisplayPipeline.swift in Sources","MacSpeedSparklineView.swift in Sources"]:
        if t not in m.group(1): fail(f"macOS sources phase missing {t}")
def ensure_route_foundation():
    detail=read("macOS/Features/SessionBrowser/MacSessionDetailView.swift"); model=read("macOS/Features/SessionBrowser/MacSessionViewerModel.swift"); route_preview=read("macOS/Features/SessionBrowser/MacRoutePreviewView.swift"); route_map=read("macOS/Features/SessionBrowser/MacRouteMapContextView.swift"); speed=read("macOS/Features/SessionBrowser/MacSpeedSparklineView.swift")
    for t in ["visualizationSection","ViewThatFits(in: .horizontal)","routeColumn","sessionSideColumn","MacRoutePreviewView(points: model.routePoints, summary: model.routeSummary)","MacSpeedSparklineView(points: model.speedPoints)","mac.viewer.route.data.title","mac.viewer.route.unique_points"]:
        if t not in detail: fail(f"MacSessionDetailView missing visualization token: {t}")
    pipeline=read("macOS/Features/SessionBrowser/MacRouteDisplayPipeline.swift")
    for t in ["MacRoutePoint","MacRouteVisualizationQuality","routePoints","uniqueRoutePointCount"]:
        if t not in model: fail(f"MacSessionViewerModel missing route derivation token: {t}")
    for t in ["enum MacSessionMetricsDeriver","routeQuality(","distanceMetersBetween","downsample(routePoints:"]:
        if t not in pipeline: fail(f"MacRouteDisplayPipeline missing route derivation token: {t}")
    for t in ["struct MacRoutePreviewView","MacRouteMapContextView(points: points, summary: summary)","mac.viewer.route.preview.readonly_mapkit","mac.viewer.route.preview.not_mapmatched","MacRoutePreviewPill","MacRouteVisualizationQuality"]:
        if t not in route_preview: fail(f"MacRoutePreviewView missing token: {t}")
    for t in ["import MapKit","struct MacRouteMapContextView: NSViewRepresentable","MKMapView","showsUserLocation = false","MKPolyline(coordinates:","MKPolylineRenderer","setVisibleMapRect","MacRouteEndpointAnnotation"]:
        if t not in route_map: fail(f"MacRouteMapContextView missing MapKit token: {t}")
    for t in ["mac.viewer.chart.speed.title","speedPath(in:",".frame(height: 132)"]:
        if t not in speed: fail(f"MacSpeedSparklineView missing Task-028b chart token: {t}")
def ensure_boundaries():
    project=read("SkateTrack.xcodeproj/project.pbxproj")
    for t in FORBIDDEN_PROJECT_TOKENS:
        if t in project: fail(f"project contains deferred document/capability token: {t}")
    for p in ["macOS/Features/SessionBrowser/MacSessionBrowserView.swift","macOS/Features/SessionBrowser/MacSessionDetailView.swift","macOS/Features/SessionBrowser/MacSessionViewerModel.swift","macOS/Features/SessionBrowser/MacSpeedSparklineView.swift","macOS/Features/SessionBrowser/MacRoutePreviewView.swift","macOS/Features/SessionBrowser/MacRouteMapContextView.swift","macOS/Features/SessionBrowser/MacRouteDisplayPipeline.swift"]:
        txt=read(p)
        for t in FORBIDDEN_VIEWER_TOKENS+FORBIDDEN_ROUTE_MUTATION_TOKENS:
            if t in txt: fail(f"forbidden token {t!r} found in {p}")
def ensure_localization():
    for lang in ["en.lproj","zh-Hant.lproj","ja.lproj"]:
        txt=read(f"Shared/Localization/{lang}/Localizable.strings")
        for k in LOCALIZATION_KEYS:
            if f'"{k}"' not in txt: fail(f"missing localization key {k} in {lang}")
def ensure_docs():
    docs="\n".join(read(p) for p in ["docs/history/DEV_LOG.md","docs/reference/FILE_STRUCTURE.md","docs/release/KNOWN_LIMITATIONS_PRE_ADP.md","docs/adr/ADR-INDEX.md"])
    for t in ["Task-028b","Task-030e-MacViewer-007A","Route / Chart Visualization Foundation","MacRoutePreviewView","MacRouteMapContextView","Read-Only MapKit Route Context","read-only","MapKit","Charts"]:
        if t not in docs: fail(f"documentation missing token: {t}")
def main():
    ensure_files(); ensure_project_membership(); ensure_route_foundation(); ensure_boundaries(); ensure_localization(); ensure_docs(); print("Task-028b/030e macOS route/chart viewer check passed"); return 0
if __name__ == "__main__": sys.exit(main())
