#!/usr/bin/env python3
"""Verify Task-012 Session Start Flow + Sport Mode Selection scaffolding."""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "iOS/App/RootNavigationView.swift",
    "iOS/Features/SessionRecording/SessionStartView.swift",
    "iOS/Features/SessionRecording/SessionStartSupportTypes.swift",
    "iOS/Features/SessionRecording/SessionStartStickyRootNavigationView.swift",
    "iOS/Features/SessionRecording/SessionStartHeaderMetricsView.swift",
    "iOS/Features/SessionRecording/SportCategoryPickerView.swift",
    "iOS/Features/SessionRecording/BoardModeSelectorView.swift",
    "iOS/Features/SessionRecording/InlineModeSelectorView.swift",
    "iOS/Features/SessionRecording/PowerTypeToggleView.swift",
    "iOS/Features/SessionRecording/ModeSelectionCardView.swift",
    "iOS/Features/SessionRecording/StartSessionCTAView.swift",
]

REQUIRED_KEYS = [
    "home.greeting.morning",
    "home.readyToSkate",
    "session.start.selectSport",
    "session.start.skateboard.subtitle",
    "session.start.inline.subtitle",
    "session.start.cta",
    "session.start.unlockToStart",
    "mode.tag.speed",
    "mode.tag.pump",
    "mode.tag.carve",
    "mode.tag.cadence",
    "mode.tag.tricks",
    "mode.tag.rhythm",
    "mode.locked.subscriberOnly",
    "mode.description.streetpark",
    "mode.description.longboard",
    "mode.description.surfskate",
    "mode.description.freebord",
    "mode.description.inline.urban",
    "mode.description.inline.fitness",
    "mode.description.inline.aggressive",
    "mode.description.inline.slalom",
    "power.type.title",
]


def fail(message: str) -> None:
    print(f"Session start flow check failed: {message}")
    sys.exit(1)


def read(path: str) -> str:
    file_path = ROOT / path
    if not file_path.exists():
        fail(f"missing {path}")
    return file_path.read_text(encoding="utf-8")


def localization_keys(path: str) -> set[str]:
    text = read(path)
    return set(re.findall(r'^"([^"]+)"\s*=', text, flags=re.MULTILINE))


for path in REQUIRED_FILES:
    text = read(path)
    if not text.startswith("// [協作區]"):
        fail(f"{path} must start with a collaboration-zone header")
    if "import CoreLocation" in text or "import CoreMotion" in text:
        fail(f"{path} must not import sensor frameworks")

session_start = read("iOS/Features/SessionRecording/SessionStartView.swift")
if "sessionRecording.actions.startSession" not in session_start:
    fail("SessionStartView must call useSessionRecording actions.startSession")
session_support = read("iOS/Features/SessionRecording/SessionStartSupportTypes.swift")
for required_dark_token in ["navy2", "card"]:
    if required_dark_token not in session_start and required_dark_token not in session_support:
        fail(f"Session Start split files missing UI mockup dark-layout token {required_dark_token}")
for required_dark_token in ["preferredColorScheme(.dark)", "ignoresSafeArea"]:
    if required_dark_token not in session_start:
        fail(f"SessionStartView missing UI mockup dark-layout token {required_dark_token}")
for required_layout_token in [
    "ZStack(alignment: .bottom)",
    "SessionStartHeaderView(",
    "SessionStartPreviewMetricStripView()",
    "SessionStartStickyRootNavigationView(",
    "SessionStartScrollOffsetPreferenceKey.self",
    "SessionStartNavigationPositionPreferenceKey.self",
    "navigationRowMinY",
    "stickyTopInset",
    "minimumStickyNavigationTopInset",
    "shouldShowStickyRootNavigation(topInset:",
    "coordinateSpace(name: SessionStartScrollMetrics.coordinateSpaceName)",
    "frame(width: proxy.size.width, height: proxy.size.height)",
    "bottomDock(bottomPadding:",
    "session-start-bottom-dock",
    "frame(minHeight: proxy.size.height",
]:
    if required_layout_token not in session_start:
        fail(f"SessionStartView missing true full-screen layout token {required_layout_token}")
if "Color(.systemBackground)" in session_start or "secondarySystemBackground" in session_start:
    fail("SessionStartView must not use default white system backgrounds after ST-12 hotfix")
if "PowerType.humanPowered" not in session_start and ".humanPowered" not in session_start:
    fail("SessionStartView must reset inline sessions to humanPowered")


header_metrics = read("iOS/Features/SessionRecording/SessionStartHeaderMetricsView.swift")
for token in [
    "SessionStartHeaderView",
    "SessionStartPreviewMetricStripView",
    "session-start-header",
    "navigationPositionReader",
    "SessionStartNavigationPositionPreferenceKey",
    "session-start-preview-metrics",
]:
    if token not in header_metrics:
        fail(f"SessionStartHeaderMetricsView missing split header/metric token {token}")

sticky_nav = read("iOS/Features/SessionRecording/SessionStartStickyRootNavigationView.swift")
for token in [
    "SessionStartScrollMetrics",
    "stickyNavigationFallbackThreshold",
    "stickyNavigationActivationPadding",
    "minimumStickyNavigationTopInset",
    "stickyNavigationContentTopSpacing",
    "SessionStartScrollOffsetPreferenceKey",
    "SessionStartNavigationPositionPreferenceKey",
    "rootNavigationAccessory",
    "topInset",
    "session-start-sticky-root-navigation",
]:
    if token not in sticky_nav:
        fail(f"SessionStartStickyRootNavigationView missing sticky navigation token {token}")

inline_selector = read("iOS/Features/SessionRecording/InlineModeSelectorView.swift")
for feature_case in ["inlineFitnessMode", "inlineAggressiveMode", "inlineSlalomMode"]:
    if feature_case not in inline_selector:
        fail(f"InlineModeSelectorView missing gated feature {feature_case}")
if "subscriptionStatus.hasAccess" not in inline_selector:
    fail("InlineModeSelectorView must use subscriptionStatus.hasAccess")

pbx = read("SkateTrack.xcodeproj/project.pbxproj")
for filename in [Path(path).name for path in REQUIRED_FILES]:
    if f"{filename} in Sources" not in pbx:
        fail(f"{filename} is not included in iOS Sources build phase")

localized_en = localization_keys("Shared/Localization/en.lproj/Localizable.strings")
localized_zh = localization_keys("Shared/Localization/zh-Hant.lproj/Localizable.strings")
for key in REQUIRED_KEYS:
    if key not in localized_en:
        fail(f"missing English localization key {key}")
    if key not in localized_zh:
        fail(f"missing Traditional Chinese localization key {key}")

print("Session start flow check passed: sticky root navigation, split header/metrics, split support types, true full-screen dark start flow, gated inline modes")
