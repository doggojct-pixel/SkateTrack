#!/usr/bin/env python3
"""Verify Snow-Task-006a Watch Snow data boundary guardrails.

This script intentionally checks the production-safe 006a foundation only:
WatchSnowSessionSnapshot, WatchSnowSessionDataSource, DEBUG mock provider,
haptic transition mapper, project membership, and scope guardrails.
"""
from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "Shared/Models/WatchSnowSessionSnapshot.swift",
    "watchOS/Core/Snow/WatchSnowSessionDataSource.swift",
    "watchOS/Core/Snow/WatchSnowMockScenario.swift",
    "watchOS/Core/Snow/WatchSnowMockSessionProvider.swift",
    "watchOS/Core/Snow/WatchSnowHapticIntent.swift",
    "watchOS/Core/Snow/WatchSnowHapticIntentObserver.swift",
    "watchOS/Core/Snow/WatchSnowHapticEngine.swift",
    "watchOS/Features/Snow/WatchSnowRootView.swift",
    "watchOS/Features/Snow/WatchSnowMockGalleryView.swift",
    "watchOS/Features/Snow/WatchSnowUnavailableView.swift",
    "watchOS/Features/Snow/WatchSnowStyle.swift",
    "watchOS/Features/Snow/WatchSnowFormatters.swift",
    "watchOS/Features/Snow/WatchSnowMetricChipView.swift",
    "watchOS/Features/Snow/WatchSnowLiveView.swift",
    "watchOS/Features/Snow/WatchSnowCarouselView.swift",
    "watchOS/Features/Snow/WatchSnowLiftCardView.swift",
    "watchOS/Features/Snow/WatchSnowWaitingCardView.swift",
    "watchOS/Features/Snow/WatchSnowSummaryView.swift",
    "watchOS/Features/Snow/WatchSnowControlView.swift",
    "watchOS/Features/Snow/WatchSnowFallAlertView.swift",
    "watchOS/Features/Snow/WatchSnowLowConfidenceView.swift",
]

SNAPSHOT_FIELDS = [
    "currentSpeedKmh",
    "maxSpeedThisRunKmh",
    "snowRunNumber",
    "snowVerticalDropMeters",
    "snowTotalVerticalMeters",
    "snowSlopeAngleDegrees",
    "snowSegmentType",
    "snowSchemaVersion",
    "totalRunsToday",
    "totalSkiDistanceMeters",
    "totalLiftDistanceMeters",
    "averageRunDurationSeconds",
    "lastRunVerticalDropMeters",
    "lastRunTopSpeedKmh",
    "lastRunDurationSeconds",
    "heartRateBpm",
    "fallAlertActive",
    "fallAlertPeakGForce",
    "isSubscriber",
]

DATASOURCE_TOKENS = [
    "WatchSnowSessionDataSource",
    "currentSnapshot",
    "snapshotPublisher",
    "lastHapticIntent",
    "markManeuver",
    "endRun",
    "startRun",
    "pauseSession",
    "resumeSession",
    "WatchSnowMockScenarioControlling",
    "selectScenario",
    "toggleSubscriberGate",
]

MOCK_TOKENS = [
    "#if DEBUG",
    "WatchSnowMockSessionProvider",
    "WatchSnowMockScenario",
    "downhill",
    "liftOrGondola",
    "waiting",
    "lowConfidence",
    "fallAlert",
    "summary",
]

HAPTIC_TOKENS = [
    "WatchSnowHapticIntentObserver",
    "intent(",
    "runStarted",
    "liftDetected",
    "fallAlert",
    "lowConfidence",
]

VIEW_TOKENS = [
    "WatchSnowRootView",
    "WatchSnowMockGalleryView",
    "WatchSnowUnavailableView",
    "WatchSnowLiveView",
    "WatchSnowCarouselView",
    "WatchSnowLiftCardView",
    "WatchSnowWaitingCardView",
    "WatchSnowSummaryView",
    "WatchSnowControlView",
    "WatchSnowFallAlertView",
    "WatchSnowLowConfidenceView",
    "WatchSnowMetricChipView",
    "WatchSnowSessionSnapshot",
]

LOCALIZATION_KEYS = [
    "snow.watch.root.eyebrow",
    "snow.watch.root.title",
    "snow.watch.root.mockOnly",
    "snow.watch.scenario.downhill",
    "snow.watch.scenario.lift",
    "snow.watch.scenario.waiting",
    "snow.watch.scenario.lowConfidence",
    "snow.watch.scenario.fallAlert",
    "snow.watch.scenario.summary",
    "snow.watch.live.badge",
    "snow.watch.live.counting",
    "snow.watch.carousel.subscriber",
    "snow.watch.carousel.free",
    "snow.watch.carousel.runSuffix",
    "snow.watch.lift.title",
    "snow.watch.lift.notCounting",
    "snow.watch.waiting.badge",
    "snow.watch.waiting.title",
    "snow.watch.waiting.message",
    "snow.watch.summary.badge",
    "snow.watch.summary.mockOnly",
    "snow.watch.control.badge",
    "snow.watch.control.start",
    "snow.watch.control.pause",
    "snow.watch.control.resume",
    "snow.watch.control.mark",
    "snow.watch.control.end",
    "snow.watch.control.subscriber",
    "snow.watch.control.free",
    "snow.watch.control.mockOnly",
    "snow.watch.lowConfidence.badge",
    "snow.watch.lowConfidence.message",
    "snow.watch.fall.title",
    "snow.watch.fall.message",
    "snow.watch.unavailable.title",
    "snow.watch.unavailable.message",
    "snow.watch.metric.run",
    "snow.watch.metric.drop",
    "snow.watch.metric.thisRunDrop",
    "snow.watch.metric.maxSpeed",
    "snow.watch.metric.lift",
    "snow.watch.metric.altitude",
    "snow.watch.metric.lastRun",
    "snow.watch.metric.lastTop",
    "snow.watch.metric.runs",
    "snow.watch.metric.totalDrop",
    "snow.watch.metric.skiKm",
    "snow.watch.metric.top",
    "snow.watch.metric.confidence",
    "snow.watch.metric.impact",
    "snow.watch.metric.status",
    "snow.watch.haptic.runStarted",
    "snow.watch.haptic.liftDetected",
    "snow.watch.haptic.fallAlert",
    "snow.watch.haptic.lowConfidence",
    "snow.watch.haptic.paused",
    "snow.watch.haptic.resumed",
    "snow.watch.haptic.maneuverMarked",
    "snow.watch.haptic.sessionEnded",
]

PROJECT_TOKENS = [
    "WatchSnowSessionSnapshot.swift in Sources",
    "WatchSnowSessionDataSource.swift in Sources",
    "WatchSnowMockScenario.swift in Sources",
    "WatchSnowMockSessionProvider.swift in Sources",
    "WatchSnowHapticIntent.swift in Sources",
    "WatchSnowHapticIntentObserver.swift in Sources",
    "WatchSnowHapticEngine.swift in Sources",
    "WatchSnowRootView.swift in Sources",
    "WatchSnowMockGalleryView.swift in Sources",
    "WatchSnowUnavailableView.swift in Sources",
    "WatchSnowStyle.swift in Sources",
    "WatchSnowFormatters.swift in Sources",
    "WatchSnowMetricChipView.swift in Sources",
    "WatchSnowLiveView.swift in Sources",
    "WatchSnowCarouselView.swift in Sources",
    "WatchSnowLiftCardView.swift in Sources",
    "WatchSnowWaitingCardView.swift in Sources",
    "WatchSnowSummaryView.swift in Sources",
    "WatchSnowControlView.swift in Sources",
    "WatchSnowFallAlertView.swift in Sources",
    "WatchSnowLowConfidenceView.swift in Sources",
]

FORBIDDEN_TOKENS = [
    "SnowPrototype",
    "import WatchConnectivity",
    "WCSession",
    "WatchBridgeSnowSessionProvider",
    "WatchSessionCoordinator",
    "SessionRecordingCoordinator",
    "import CoreLocation",
    "CLLocation",
    "SensorFusionEngine",
    "SnowLiveSessionCoordinator",
    "SnowSessionRepository",
    "import HealthKit",
    "import CoreData",
    "Shared/WatchBridge",
]

FORBIDDEN_MODIFIED_PATTERNS = [
    r"^Shared/WatchBridge/",
    r"^Shared/Models/MotionSample\.swift$",
    r"^Shared/Models/SnowSegmentClassifier\.swift$",
    r"^Shared/Models/RunBoundaryDetector\.swift$",
    r"^Shared/Models/SnowSegment\.swift$",
    r"^Shared/Models/SnowRun\.swift$",
    r"^Shared/Models/SnowDistanceBreakdown\.swift$",
    r"^Shared/Models/SnowVerticalMetrics\.swift$",
    r"^Shared/Models/SnowSessionState\.swift$",
    r"^iOS/Core/SessionRecording/SessionRecordingCoordinator\.swift$",
    r"^iOS/Hooks/useSessionRecording\.swift$",
    r"^iOS/Hooks/useSnowLiveSession\.swift$",
    r"^iOS/Core/SnowEngine/SnowLiveSessionCoordinator\.swift$",
    r".*\.skatetrack$",
]


def fail(message: str) -> None:
    print(f"[snow-task-006a] FAIL: {message}", file=sys.stderr)
    sys.exit(1)


def read(path: str) -> str:
    full_path = ROOT / path
    if not full_path.exists():
        fail(f"missing required file: {path}")
    return full_path.read_text(encoding="utf-8")


def changed_files() -> list[str]:
    result = subprocess.run(
        ["git", "-C", str(ROOT), "diff", "--name-only", "HEAD"],
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        return []
    return [line.strip() for line in result.stdout.splitlines() if line.strip()]


def main() -> None:
    for required in REQUIRED_FILES:
        if not (ROOT / required).exists():
            fail(f"missing required file: {required}")

    snapshot = read("Shared/Models/WatchSnowSessionSnapshot.swift")
    for field in SNAPSHOT_FIELDS:
        if field not in snapshot:
            fail(f"WatchSnowSessionSnapshot missing field: {field}")
    if "SnowPrototype" in snapshot:
        fail("WatchSnowSessionSnapshot must not use SnowPrototype naming")

    datasource = read("watchOS/Core/Snow/WatchSnowSessionDataSource.swift")
    for token in DATASOURCE_TOKENS:
        if token not in datasource:
            fail(f"WatchSnowSessionDataSource missing token: {token}")
    if "WatchConnectivity" in datasource or "WCSession" in datasource:
        fail("WatchSnowSessionDataSource must not reference WatchConnectivity")

    mock = read("watchOS/Core/Snow/WatchSnowMockSessionProvider.swift")
    for token in MOCK_TOKENS:
        if token not in mock:
            fail(f"WatchSnowMockSessionProvider missing token: {token}")
    if not re.search(r"#if\s+DEBUG[\s\S]*final class WatchSnowMockSessionProvider", mock):
        fail("WatchSnowMockSessionProvider must be declared under #if DEBUG")

    haptic = read("watchOS/Core/Snow/WatchSnowHapticIntentObserver.swift")
    for token in HAPTIC_TOKENS:
        if token not in haptic:
            fail(f"WatchSnowHapticIntentObserver missing token: {token}")

    combined_views = "\n".join(read(path) for path in REQUIRED_FILES if path.startswith("watchOS/Features/Snow/"))
    for token in VIEW_TOKENS:
        if token not in combined_views:
            fail(f"Watch Snow UI missing token: {token}")

    root = read("watchOS/Features/Snow/WatchSnowRootView.swift")
    if "#if DEBUG" not in root or "WatchSnowMockGalleryView" not in root or "WatchSnowUnavailableView" not in root:
        fail("WatchSnowRootView must provide DEBUG mock gallery and Release fallback")

    gallery = read("watchOS/Features/Snow/WatchSnowMockGalleryView.swift")
    if "#if DEBUG" not in gallery or "WatchSnowMockSessionProvider" not in gallery:
        fail("WatchSnowMockGalleryView must be DEBUG-gated and use WatchSnowMockSessionProvider")

    app = read("watchOS/App/SkateTrackWatchApp.swift")
    if "WatchSnowRootView" not in app:
        fail("SkateTrackWatchApp must route to WatchSnowRootView")

    for language in ["en", "zh-Hant", "ja"]:
        localization = read(f"Shared/Localization/{language}.lproj/Localizable.strings")
        for key in LOCALIZATION_KEYS:
            if f'"{key}"' not in localization:
                fail(f"missing localization key in {language}: {key}")

    watch_sources = [
        ROOT / "watchOS/Core/Snow/WatchSnowSessionDataSource.swift",
        ROOT / "watchOS/Core/Snow/WatchSnowMockScenario.swift",
        ROOT / "watchOS/Core/Snow/WatchSnowMockSessionProvider.swift",
        ROOT / "watchOS/Core/Snow/WatchSnowHapticIntent.swift",
        ROOT / "watchOS/Core/Snow/WatchSnowHapticIntentObserver.swift",
        ROOT / "watchOS/Core/Snow/WatchSnowHapticEngine.swift",
    ] + list((ROOT / "watchOS/Features/Snow").glob("*.swift"))
    for source in watch_sources:
        content = source.read_text(encoding="utf-8")
        for forbidden in FORBIDDEN_TOKENS:
            if forbidden in content:
                fail(f"forbidden token '{forbidden}' found in {source.relative_to(ROOT)}")

    project = read("SkateTrack.xcodeproj/project.pbxproj")
    for token in PROJECT_TOKENS:
        if token not in project:
            fail(f"project missing source membership token: {token}")

    for changed in changed_files():
        for pattern in FORBIDDEN_MODIFIED_PATTERNS:
            if re.match(pattern, changed):
                fail(f"forbidden file modified in Snow-Task-006a: {changed}")

    print(
        "[snow-task-006a] PASS: Watch Snow session snapshot, data-source boundary, "
        "DEBUG mock provider, haptic transition mapper, mock-backed Watch Snow UI views, "
        "localization, project membership, Release fallback, and 006b deferral guardrails are present."
    )


if __name__ == "__main__":
    main()
