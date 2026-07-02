#!/usr/bin/env python3
"""Verify Task-030c-b6/b7 Debug panel polish and task-build signature."""

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

debug_panel = ROOT / "iOS/Features/Debug/DebugToolsPanelView.swift"
session_hook = ROOT / "iOS/Hooks/useSessionRecording.swift"
localizations = [
    ROOT / "Shared/Localization/en.lproj/Localizable.strings",
    ROOT / "Shared/Localization/zh-Hant.lproj/Localizable.strings",
    ROOT / "Shared/Localization/ja.lproj/Localizable.strings",
]

for path in [debug_panel, session_hook, *localizations]:
    if not path.exists():
        sys.exit(f"Missing expected file: {path.relative_to(ROOT)}")

panel_text = debug_panel.read_text(encoding="utf-8")
for token in [
    "debugBuildSignatureCard",
    "Task-030c-b15-A",
    "debug-build-signature-card",
    "debug.build.title",
    "debug.build.subtitle",
]:
    if token not in panel_text:
        sys.exit(f"DebugToolsPanelView.swift missing current b12 build signature token: {token}")

hook_text = session_hook.read_text(encoding="utf-8")
for token in [
    "SessionRecordingPreviewPanel",
    "debug.status.title",
    "metricTile(",
    "diagnosticRow(",
    "latestSampleSourceLabel",
    "latestAccuracyText",
    "session-recording-preview-source-chip",
]:
    if token not in hook_text:
        sys.exit(f"useSessionRecording.swift missing polished diagnostics token: {token}")

# Guard against reverting to the old unlabeled grey debug box.
for legacy_token in [
    'Text("\\(sessionRecording.state.currentSpeedKilometersPerHour',
    'Text("samples \\(sessionRecording.state.motionSampleCount) / gps',
    ".background(.thinMaterial)",
]:
    if legacy_token in hook_text:
        sys.exit(f"SessionRecordingPreviewPanel still contains legacy unlabeled debug UI token: {legacy_token}")

required_keys = [
    "debug.status.title",
    "debug.status.speed",
    "debug.status.distance",
    "debug.status.elapsed",
    "debug.status.gps",
    "debug.status.samples",
    "debug.status.latestAccuracy",
    "debug.status.latestFreshness",
    "debug.status.source.locationFix",
    "debug.status.source.timerFusion",
    "debug.status.source.debugSimulated",
    "debug.status.source.none",
    "debug.status.freshness.fresh",
    "debug.status.freshness.recent",
    "debug.status.freshness.stale",
    "debug.status.freshness.unavailable",
    "debug.status.freshness.none",
    "debug.build.title",
    "debug.build.subtitle",
]

for loc in localizations:
    text = loc.read_text(encoding="utf-8")
    for key in required_keys:
        if f'"{key}"' not in text:
            sys.exit(f"{loc.relative_to(ROOT)} missing b6 localization key: {key}")

print("Task-030c-b6/b7 check passed: polished debug status panel and current Task-030c-b15-A build signature are present.")
