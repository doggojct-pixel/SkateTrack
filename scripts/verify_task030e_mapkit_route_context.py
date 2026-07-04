#!/usr/bin/env python3
"""Verify Task-030e-MacViewer-007A read-only MapKit route context."""
from __future__ import annotations
import re, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def fail(m): print(f"Task-030e 007A MapKit route context check failed: {m}", file=sys.stderr); sys.exit(1)
def read(rel):
    p=ROOT/rel
    if not p.exists(): fail(f"missing required file: {rel}")
    return p.read_text(encoding="utf-8")
def require(name, text, tokens):
    missing=[t for t in tokens if t not in text]
    if missing: fail(f"{name} missing token(s): "+", ".join(missing))
def reject(name, text, tokens):
    present=[t for t in tokens if t in text]
    if present: fail(f"{name} contains forbidden token(s): "+", ".join(present))
REQUIRED=["macOS/Features/SessionBrowser/MacRouteMapContextView.swift","macOS/Features/SessionBrowser/MacRoutePreviewView.swift","SkateTrack.xcodeproj/project.pbxproj","Shared/Localization/en.lproj/Localizable.strings","Shared/Localization/zh-Hant.lproj/Localizable.strings","Shared/Localization/ja.lproj/Localizable.strings","scripts/verify_macos_route_chart_viewer.py","docs/history/DEV_LOG.md","docs/reference/FILE_STRUCTURE.md","docs/release/KNOWN_LIMITATIONS_PRE_ADP.md"]
MAP_TOKENS=["// [協作區] macOS/Features/SessionBrowser/MacRouteMapContextView.swift","import MapKit","struct MacRouteMapContextView: NSViewRepresentable","MKMapView","showsUserLocation = false","MKPolyline(coordinates:","MKPolylineRenderer","setVisibleMapRect","NSEdgeInsets","MacRouteEndpointAnnotation"]
PREVIEW_TOKENS=["MacRouteMapContextView(points: points, summary: summary)","mac.viewer.route.preview.readonly_mapkit","mac.viewer.route.preview.not_mapmatched","readOnlyMapBadge"]
PROJECT_TOKENS=["30E800000000000000000001 /* MacRouteMapContextView.swift */ = {isa = PBXFileReference;","30E800000000000000000101 /* MacRouteMapContextView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 30E800000000000000000001","30E800000000000000000001 /* MacRouteMapContextView.swift */,","30E800000000000000000101 /* MacRouteMapContextView.swift in Sources },"]
LOCALIZATION_KEYS=["mac.viewer.route.map_deferred","mac.viewer.route.preview.not_mapmatched","mac.viewer.route.preview.readonly_mapkit","mac.accessibility.route_preview.hint"]
DOC_TOKENS=["Task-030e-MacViewer-007A","Read-Only MapKit Route Context","MacRouteMapContextView","no road matching","no route geometry mutation","no trusted metrics mutation"]
FORBIDDEN=["showsUserLocation = true","CLLocationManager","requestWhenInUseAuthorization","requestAlwaysAuthorization","snapToRoad","mapMatch","roadMatch","reconstructRoute","mutateRouteGeometry","routeGeometryMutationApplied = true","trustedMetricsMutationApplied = true","estimatedRouteDisplayEnabled = true","UTExportedTypeDeclarations","CFBundleDocumentTypes","LSSupportsOpeningDocumentsInPlace"]
def main():
    for rel in REQUIRED:
        if not (ROOT/rel).exists(): fail(f"missing required file: {rel}")
    map_view=read("macOS/Features/SessionBrowser/MacRouteMapContextView.swift"); preview=read("macOS/Features/SessionBrowser/MacRoutePreviewView.swift")
    require("MacRouteMapContextView.swift", map_view, MAP_TOKENS); require("MacRoutePreviewView.swift", preview, PREVIEW_TOKENS)
    reject("MacRouteMapContextView.swift", map_view, FORBIDDEN); reject("MacRoutePreviewView.swift", preview, FORBIDDEN)
    if len(map_view.splitlines())>500: fail("MacRouteMapContextView.swift exceeds 500 lines")
    if len(preview.splitlines())>500: fail("MacRoutePreviewView.swift exceeds 500 lines")
    project=read("SkateTrack.xcodeproj/project.pbxproj")
    require("project.pbxproj", project, PROJECT_TOKENS[:3])
    if "30E800000000000000000101 /* MacRouteMapContextView.swift in Sources */" not in project: fail("project missing MacRouteMapContextView sources token")
    reject("project.pbxproj", project, FORBIDDEN)
    m=re.search(r"A2EF5573281ED5113A3645DD /\* Sources \*/ = \{.*?files = \((.*?)\);", project, re.S)
    if not m or "MacRouteMapContextView.swift in Sources" not in m.group(1): fail("macOS sources phase missing MacRouteMapContextView.swift")
    for lang in ["en","zh-Hant","ja"]:
        txt=read(f"Shared/Localization/{lang}.lproj/Localizable.strings")
        for k in LOCALIZATION_KEYS:
            if f'"{k}" = ' not in txt: fail(f"missing localization key {k} in {lang}")
    docs="\n".join(read(p) for p in ["docs/history/DEV_LOG.md","docs/reference/FILE_STRUCTURE.md","docs/release/KNOWN_LIMITATIONS_PRE_ADP.md"])
    require("docs", docs, DOC_TOKENS)
    print("Task-030e 007A MapKit route context check passed"); return 0
if __name__ == "__main__": sys.exit(main())
