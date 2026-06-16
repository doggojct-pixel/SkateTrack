#!/usr/bin/env python3
"""Verify Task-013 Live HUD + Slide-to-End implementation."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "iOS/Features/SessionRecording/LiveHUDView.swift",
    "iOS/Features/SessionRecording/LiveHUDMetricCardView.swift",
    "iOS/Features/SessionRecording/LiveSpeedDisplayView.swift",
    "iOS/Features/SessionRecording/LiveSpeedTraceView.swift",
    "iOS/Features/SessionRecording/TiltIndicatorView.swift",
    "iOS/Features/SessionRecording/MiniRouteMapView.swift",
    "iOS/Features/SessionRecording/SlideToEndSessionControl.swift",
    "iOS/Features/SessionRecording/InlineLiveMetricsView.swift",
]

REQUIRED_KEYS = [
    "session.hud.maxSpeed",
    "session.hud.distance",
    "session.hud.time",
    "session.hud.tilt",
    "session.hud.heartRate",
    "session.hud.tricks",
    "session.hud.slideToEnd",
    "session.hud.sos",
    "session.hud.inline.cadence",
    "session.hud.inline.rhythm",
    "session.hud.inline.placeholder",
    "session.hud.routeWaiting",
    "session.hud.noMode",
    "unit.speed.kmh",
    "unit.speed.kmh.short",
]


def fail(message: str) -> None:
    print(f"Live HUD check failed: {message}")
    sys.exit(1)


def read(path: str) -> str:
    file_path = ROOT / path
    if not file_path.exists():
        fail(f"missing {path}")
    return file_path.read_text(encoding="utf-8")


def localization_keys(path: str) -> set[str]:
    return set(re.findall(r'^"([^"]+)"\s*=', read(path), flags=re.MULTILINE))


for path in REQUIRED_FILES:
    text = read(path)
    if not text.startswith("// [協作區]"):
        fail(f"{path} must start with collaboration-zone header")
    if "import CoreMotion" in text or "import CoreLocation" in text:
        fail(f"{path} must not import raw sensor frameworks")
    line_limit = 560 if path.endswith("LiveHUDView.swift") else 500
    if path.endswith("LiveSpeedTraceView.swift"):
        line_limit = 120
    if len(text.splitlines()) > line_limit:
        fail(f"{path} exceeds {line_limit} lines")

live_hud = read("iOS/Features/SessionRecording/LiveHUDView.swift")
for snippet in [
    "LiveSpeedDisplayView",
    "LiveSpeedTraceView",
    "appendSpeedTraceSampleIfNeeded",
    "onChange(of: sessionRecording.state.elapsedTime)",
    "onChange(of: sessionRecording.state.currentSpeedKilometersPerHour)",
    "SlideToEndSessionControl",
    "InlineLiveMetricsView",
    "sessionRecording.actions.requestEndSession",
    "sessionRecording.actions.pauseSession",
    "sessionRecording.actions.resumeSession",
    "preferredColorScheme(.dark)",
]:
    if snippet not in live_hud:
        fail(f"LiveHUDView missing {snippet}")

for required_layout_token in [
    "GeometryReader",
    "ZStack(alignment: .bottom)",
    "ScrollView(showsIndicators: false)",
    "ScrollViewReader",
    ".frame(minHeight: proxy.size.height",
    "controlDock(bottomPadding:",
    "live-hud-control-dock",
    "speedHero",
]:
    if required_layout_token not in live_hud:
        fail(f"LiveHUDView missing true full-screen scroll layout token {required_layout_token}")
if "mapHUDSection(height:" in live_hud:
    fail("LiveHUDView must not use the old fixed-height map HUD container")

slide = read("iOS/Features/SessionRecording/SlideToEndSessionControl.swift")
if "dragProgress >= 0.85" not in slide:
    fail("SlideToEndSessionControl must require 85 percent drag threshold")
if "frame(height: 62)" not in slide:
    fail("SlideToEndSessionControl must keep a touch-safe height")

root = read("iOS/App/RootNavigationView.swift")
if "LiveHUDView" not in root or "shouldShowLiveHUD" not in root:
    fail("RootNavigationView must route active session states to LiveHUDView")

hook = read("iOS/Hooks/useSessionRecording.swift")
if "recentRouteCoordinates" not in hook:
    fail("SessionRecordingState must expose recentRouteCoordinates for MiniRouteMapView")

pbx = read("SkateTrack.xcodeproj/project.pbxproj")
for path in REQUIRED_FILES:
    name = Path(path).name
    if f"{name} in Sources" not in pbx:
        fail(f"{name} is not included in iOS Sources build phase")

localized_en = localization_keys("Shared/Localization/en.lproj/Localizable.strings")
localized_zh = localization_keys("Shared/Localization/zh-Hant.lproj/Localizable.strings")
for key in REQUIRED_KEYS:
    if key not in localized_en:
        fail(f"missing English localization key {key}")
    if key not in localized_zh:
        fail(f"missing Traditional Chinese localization key {key}")

speed_trace = read("iOS/Features/SessionRecording/LiveSpeedTraceView.swift")
for snippet in [
    "drawWaitingTrace",
    "traceSamples.count >= 2",
    "accessibilityIdentifier(\"live-hud-speed-trace\")",
]:
    if snippet not in speed_trace:
        fail(f"LiveSpeedTraceView missing robust trace token {snippet}")

print("Live HUD check passed: speed trace, HUD routing, bottom controls, slide-to-end")
