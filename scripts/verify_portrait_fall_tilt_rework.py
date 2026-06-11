#!/usr/bin/env python3
"""Verify portrait lock, conservative tilt display, and fall-alert surfacing gate."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]


def fail(message: str) -> None:
    print(f"Portrait fall/tilt rework check failed: {message}")
    sys.exit(1)


def read(path: str) -> str:
    file_path = ROOT / path
    if not file_path.exists():
        fail(f"missing {path}")
    return file_path.read_text(encoding="utf-8")

project = read("SkateTrack.xcodeproj/project.pbxproj")
for snippet in [
    "INFOPLIST_KEY_UIRequiresFullScreen = YES;",
    "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = UIInterfaceOrientationPortrait;",
    "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = UIInterfaceOrientationPortrait;",
]:
    if project.count(snippet) != 2:
        fail(f"expected 2 iOS build settings for {snippet}")

tilt = read("iOS/Features/SessionRecording/TiltIndicatorView.swift")
for snippet in [
    "Phase 1a 不將手機絕對角度視為滑板傾角",
    'Text("session.hud.tiltPending")',
    "session.hud.tiltPending",
    "session.hud.tiltUncalibrated",
    "live-hud-tilt-indicator",
]:
    if snippet not in tilt:
        fail(f"TiltIndicatorView missing {snippet}")
if "markerOffset" in tilt or "abs(tiltDegrees)" in tilt:
    fail("TiltIndicatorView must not render raw absolute phone angle as board tilt")

coordinator = read("iOS/Core/SessionRecording/SessionRecordingCoordinator.swift")
for snippet in [
    "metricsAccumulator.elapsedTime >= 10",
    "metricsAccumulator.currentSpeedKilometersPerHour >= 4",
    "metricsAccumulator.distanceKilometers >= 0.01",
    "activeFallEvent?.id == fallEvent.id",
]:
    if snippet not in coordinator:
        fail(f"SessionRecordingCoordinator missing fall surfacing gate: {snippet}")
if len(coordinator.splitlines()) > 450:
    fail("SessionRecordingCoordinator.swift exceeds 450 lines")

for loc_path in [
    "Shared/Localization/en.lproj/Localizable.strings",
    "Shared/Localization/zh-Hant.lproj/Localizable.strings",
]:
    keys = set(re.findall(r'^"([^"]+)"\s*=', read(loc_path), flags=re.MULTILINE))
    for key in ["session.hud.tilt", "session.hud.tiltPending", "session.hud.tiltUncalibrated"]:
        if key not in keys:
            fail(f"{loc_path} missing {key}")

print("Portrait fall/tilt rework check passed: portrait-only iOS, conservative tilt pending label, fall alert surfacing gate")
