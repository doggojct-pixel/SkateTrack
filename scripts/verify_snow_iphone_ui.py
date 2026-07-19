#!/usr/bin/env python3
"""Snow-Task-005 iPhone Snow UI boundary verifier.

This v0 verifier covers the Snow-Task-005b-1 data-boundary slice:
- Snow live config exists.
- lowConfidence threshold is config-driven and references SnowClassifierConfig.
- HUD mapper exposes four states without hardcoded confidence literals.
- New production files do not introduce prototype / WatchBridge scope creep.
- Snow-Task-003/004 and Snow-Task-002 value types remain untouched in the current git diff.
"""

from __future__ import annotations

import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
A005_INTEGRATION_MODE = os.environ.get("SNOW_INTEGRATION_A005") == "1"
A010R5R2_INTEGRATION_MODE = os.environ.get("SNOW_INTEGRATION_A010R5R2") == "1"


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def exists(path: str) -> bool:
    return (ROOT / path).exists()


def git_diff_names() -> list[str]:
    try:
        result = subprocess.run(
            ["git", "diff", "--name-only", "HEAD"],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=True,
        )
    except Exception as error:
        fail(f"unable to inspect git diff against HEAD: {error}")
    return [line.strip() for line in result.stdout.splitlines() if line.strip()]


def fail(message: str) -> None:
    print(f"[snow-task-005] FAIL: {message}")
    sys.exit(1)


def require(condition: bool, message: str) -> None:
    if not condition:
        fail(message)


def main() -> None:
    required_files = [
        "iOS/Core/SnowEngine/SnowLiveSessionConfig.swift",
        "iOS/Core/SnowEngine/SnowClassificationWindowBuffer.swift",
        "iOS/Core/SnowEngine/SnowLiveSessionState.swift",
        "iOS/Core/SnowEngine/SnowLiveHUDState.swift",
        "iOS/Core/SnowEngine/SnowLiveHUDStateMapper.swift",
        "iOS/Core/SnowEngine/SnowLiveSessionCoordinator.swift",
        "iOS/Hooks/useSnowLiveSession.swift",
        "iOS/Features/SessionRecording/SnowHUDView.swift",
        "iOS/Features/SessionRecording/SnowHUDDownhillView.swift",
        "iOS/Features/SessionRecording/SnowHUDLiftView.swift",
        "iOS/Features/SessionRecording/SnowHUDWaitingView.swift",
        "iOS/Features/SessionRecording/SnowHUDLowConfidenceView.swift",
        "iOS/Features/SessionSummary/SnowDaySummaryView.swift",
        "iOS/Features/SessionSummary/SnowSegmentTimelineView.swift",
        "iOS/Features/SessionSummary/SnowDistanceInspectorView.swift",
        "Tests/iOSTests/SnowLiveSessionConfigTests.swift",
        "Tests/iOSTests/SnowLiveHUDStateMapperTests.swift",
    ]
    for path in required_files:
        require(exists(path), f"missing required file: {path}")

    config = read("iOS/Core/SnowEngine/SnowLiveSessionConfig.swift")
    mapper = read("iOS/Core/SnowEngine/SnowLiveHUDStateMapper.swift")
    hud_state = read("iOS/Core/SnowEngine/SnowLiveHUDState.swift")
    coordinator = read("iOS/Core/SnowEngine/SnowLiveSessionCoordinator.swift")
    session_coordinator = read("iOS/Core/SessionRecording/SessionRecordingCoordinator.swift")
    session_hook = read("iOS/Hooks/useSessionRecording.swift")
    session_tests = read("Tests/iOSTests/SessionRecordingCoordinatorTests.swift")
    live_hud = read("iOS/Features/SessionRecording/LiveHUDView.swift")
    snow_hud = read("iOS/Features/SessionRecording/SnowHUDView.swift")
    snow_downhill = read("iOS/Features/SessionRecording/SnowHUDDownhillView.swift")
    snow_lift = read("iOS/Features/SessionRecording/SnowHUDLiftView.swift")
    snow_waiting = read("iOS/Features/SessionRecording/SnowHUDWaitingView.swift")
    snow_low_confidence = read("iOS/Features/SessionRecording/SnowHUDLowConfidenceView.swift")
    snow_day_summary = read("iOS/Features/SessionSummary/SnowDaySummaryView.swift")
    snow_timeline = read("iOS/Features/SessionSummary/SnowSegmentTimelineView.swift")
    snow_inspector = read("iOS/Features/SessionSummary/SnowDistanceInspectorView.swift")
    session_summary_view = read("iOS/Features/SessionSummary/SessionSummaryView.swift")
    localizations = [
        read("Shared/Localization/en.lproj/Localizable.strings"),
        read("Shared/Localization/zh-Hant.lproj/Localizable.strings"),
        read("Shared/Localization/ja.lproj/Localizable.strings"),
    ]
    project = read("SkateTrack.xcodeproj/project.pbxproj")

    require("struct SnowLiveSessionConfig" in config, "SnowLiveSessionConfig type is missing")
    require("let lowConfidenceThreshold" in config, "lowConfidenceThreshold must be defined in SnowLiveSessionConfig")
    require(
        "lowConfidenceThreshold: SnowClassifierConfig.productionV0.mediumConfidenceThreshold" in config,
        "lowConfidenceThreshold must reference SnowClassifierConfig.productionV0.mediumConfidenceThreshold",
    )

    require("enum SnowLiveHUDState" in hud_state, "SnowLiveHUDState enum is missing")
    for case in ["case downhill", "case lift", "case waiting", "case lowConfidence"]:
        require(case in hud_state, f"SnowLiveHUDState missing {case}")

    require("SnowLiveHUDStateMapper" in mapper, "SnowLiveHUDStateMapper is missing")
    require("config: SnowLiveSessionConfig" in mapper, "mapper must accept SnowLiveSessionConfig")
    require("config.lowConfidenceThreshold" in mapper, "mapper must read config.lowConfidenceThreshold")
    require("currentConfidence < config.lowConfidenceThreshold" in mapper, "low confidence comparison must use config")
    require("lowConfidenceReasonCodes" in mapper, "mapper must support config-driven reason codes")

    require("private let snowLiveCoordinator: SnowLiveSessionCoordinating" in session_coordinator, "SessionRecordingCoordinator must own an injected Snow live coordinator")
    require("snowLiveStatePublisher" in session_coordinator, "SessionRecordingCoordinator must expose Snow live state publisher")
    require("startSnowLiveSessionIfNeeded" in session_coordinator, "SessionRecordingCoordinator must start Snow live coordinator for snow mode")
    require("ingestSnowLiveSampleIfNeeded" in session_coordinator, "SessionRecordingCoordinator must forward snow MotionSample data")
    require("finishSnowLiveSessionIfNeeded" in session_coordinator, "SessionRecordingCoordinator must finish/reset Snow live coordinator with session lifecycle")
    require("activeSessionID" in session_coordinator, "SessionRecordingCoordinator must keep a stable active session ID for Snow persistence alignment")
    require("case .snow = selectedSportMode" in session_coordinator, "Snow sample forwarding must be gated to snow mode")

    require("snowLiveState: SnowLiveSessionState" in session_hook, "SessionRecordingState must expose Snow live state")
    require("snowLiveHUDState: SnowLiveHUDState" in session_hook, "SessionRecordingState must expose Snow HUD state")
    require("coordinator.snowLiveStatePublisher" in session_hook, "useSessionRecording must bind Snow live state publisher")
    require("SnowLiveHUDStateMapper.map" in session_hook, "useSessionRecording must map Snow live state to HUD state")

    require("testSnowSessionStartsLiveCoordinatorAndForwardsSamples" in session_tests, "SessionRecordingCoordinatorTests must cover snow live start/sample forwarding")
    require("testNonSnowSessionDoesNotForwardSamplesToSnowLiveCoordinator" in session_tests, "SessionRecordingCoordinatorTests must cover non-snow isolation")
    require("MockSnowLiveSessionCoordinator" in session_tests, "SessionRecordingCoordinatorTests must use an injected mock Snow live coordinator")

    require("SnowHUDView(" in live_hud, "LiveHUDView must route snow mode to SnowHUDView")
    require("if isSnowMode" in live_hud, "LiveHUDView must gate SnowHUDView behind snow mode")
    require("speedHero" in live_hud and "metricGrid" in live_hud, "existing non-snow Live HUD sections must remain present")
    require("struct SnowHUDView" in snow_hud, "SnowHUDView must exist")
    require("switch hudState" in snow_hud, "SnowHUDView must switch on SnowLiveHUDState only")
    for symbol, content in [
        ("SnowHUDDownhillView", snow_downhill),
        ("SnowHUDLiftView", snow_lift),
        ("SnowHUDWaitingView", snow_waiting),
        ("SnowHUDLowConfidenceView", snow_low_confidence),
    ]:
        require(f"struct {symbol}" in content, f"{symbol} must exist")
    require("SnowHUDPlaceholderButton" in snow_hud, "manual marking placeholders must be visible but disabled")
    require(".disabled(true)" in snow_hud, "manual marking placeholders must not mutate production data in Step 3")
    require("config.lowConfidenceThreshold" in mapper, "lowConfidence mapping must remain config-driven after UI wiring")
    require("SnowLiveSessionConfig.productionV0.mediumConfidenceThreshold" not in snow_low_confidence, "SnowHUDLowConfidenceView must not read classifier thresholds directly")

    require("struct SnowDaySummaryView" in snow_day_summary, "SnowDaySummaryView must exist")
    require("struct SnowSegmentTimelineView" in snow_timeline, "SnowSegmentTimelineView must exist")
    require("struct SnowDistanceInspectorView" in snow_inspector, "SnowDistanceInspectorView must exist")
    require("SnowDaySummaryView(state: snowSession.state)" in session_summary_view, "SessionSummaryView must show SnowDaySummaryView for snow sessions")
    require("SnowDistanceInspectorView(" in session_summary_view and "SnowSummarySelectionModel.inspectorSnapshot(" in session_summary_view, "SessionSummaryView must show selection-backed SnowDistanceInspectorView for snow sessions")
    require("SnowSegmentTimelineView(" in session_summary_view and "segments: snowSession.state.segments" in session_summary_view, "SessionSummaryView must show SnowSegmentTimelineView for snow sessions")
    require("if case .snow = session.sportMode" in session_summary_view, "Snow summary stack must be gated to snow sessions")
    require("maximumFractionDigits: 2" in snow_day_summary, "Snow route distance must allow the same two-decimal precision as the general summary")
    require("meters >= 1_000 ? 2 : 0" not in snow_day_summary, "stale zero-decimal Snow distance formatting must be rejected")
    require("SnowSummaryFormatters.distance(segment.distanceMeters)" in snow_timeline, "timeline segment distance must use the shared Snow distance formatter")
    require("SnowSummaryFormatters.distance(breakdown.routeDistanceMeters)" in snow_inspector, "Distance Inspector route must use the shared Snow distance formatter")
    require("maximumFractionDigits: 2" in session_summary_view, "general summary must retain two-decimal-capable distance formatting")
    for token in [
        "enum SnowDaySummaryPresentation: Equatable",
        "case unknownOnly",
        "state.runs.isEmpty",
        "state.distanceBreakdown.unknownDistanceMeters > 0",
        "state.distanceBreakdown.skiDistanceMeters == 0",
        "state.distanceBreakdown.liftDistanceMeters == 0",
        ".accessibilityElement(children: .combine)",
        'accessibilityIdentifier("snow-summary-unknown-only-status")',
    ]:
        require(token in snow_day_summary, f"unknown-only Snow summary contract missing: {token}")

    required_l10n_keys = [
        "snow.hud.title",
        "snow.hud.downhill.status",
        "snow.hud.lift.notCounting",
        "snow.hud.waiting.title",
        "snow.hud.lowConfidence",
        "snow.hud.markSkiing.placeholder",
        "snow.hud.markLift.placeholder",
        "snow.summary.title",
        "snow.summary.subtitle",
        "snow.summary.unknownOnly.title",
        "snow.summary.unknownOnly.detail",
        "snow.summary.skiDistance",
        "snow.timeline.title",
        "snow.timeline.counted",
        "snow.inspector.title",
        "snow.inspector.skiDistance",
        "snow.inspector.liftDistance",
        "snow.inspector.routeDistance",
    ]
    for localization in localizations:
        for key in required_l10n_keys:
            require(f'"{key}"' in localization, f"missing localization key: {key}")

    exact_copy = [
        (
            localizations[0],
            '"snow.summary.title" = "Downhill information";',
            '"snow.summary.subtitle" = "Runs, vertical drop, riding distance, and top speed from segments classified as downhill.";',
            '"snow.summary.unknownOnly.title" = "No classified downhill data yet";',
        ),
        (
            localizations[1],
            '"snow.summary.title" = "滑降資訊";',
            '"snow.summary.subtitle" = "依已分類為滑降的區段，顯示趟次、垂直落差、滑行距離與最高速度。";',
            '"snow.summary.unknownOnly.title" = "尚無已分類的滑降資料";',
        ),
        (
            localizations[2],
            '"snow.summary.title" = "滑降情報";',
            '"snow.summary.subtitle" = "滑降と分類された区間のラン数、標高差、滑走距離、最高速度を表示します。";',
            '"snow.summary.unknownOnly.title" = "分類済みの滑降データはまだありません";',
        ),
    ]
    for localization, title, subtitle, unknown_heading in exact_copy:
        for expected_line in (title, subtitle, unknown_heading):
            require(expected_line in localization, f"A010R5R2 localization copy mismatch: {expected_line}")

    production_files_to_scan = [
        config,
        mapper,
        hud_state,
        coordinator,
        session_coordinator,
        session_hook,
        read("iOS/Hooks/useSnowLiveSession.swift"),
        snow_hud,
        snow_downhill,
        snow_lift,
        snow_waiting,
        snow_low_confidence,
    ]
    hardcoded_confidence_pattern = re.compile(r"(?<![A-Za-z0-9_])(0\.62|0\.78|0\.70|0\.5|0\.50|0\.55)(?![A-Za-z0-9_])")
    for content in production_files_to_scan:
        require(
            not hardcoded_confidence_pattern.search(content),
            "production Snow live UI boundary must not hardcode confidence literals",
        )

    for symbol in ["SnowPrototype", "MockSnowSessionProvider", "SnowPrototypeSession"]:
        for path in required_files[:7]:
            require(symbol not in read(path), f"prototype symbol {symbol} leaked into production file {path}")

    require("Shared/WatchBridge" not in "\n".join(required_files), "verify script internal error: WatchBridge path included")
    for path in required_files[:7]:
        require("WatchBridge" not in read(path), f"WatchBridge reference found in {path}")
        require("WatchConnectivity" not in read(path), f"WatchConnectivity reference found in {path}")

    for path in required_files:
        require(path.split("/")[-1] in project, f"project.pbxproj does not reference {path.split('/')[-1]}")

    diff_names = git_diff_names()
    if A010R5R2_INTEGRATION_MODE:
        require(
            not any(name.endswith(".skatetrack") for name in diff_names),
            "A010R5R2 must not add binary package samples",
        )
    elif A005_INTEGRATION_MODE:
        require(
            not any(name.startswith("Shared/WatchBridge/") for name in diff_names),
            "A005 integration must not modify Shared/WatchBridge before A006",
        )
        require(
            not any(name.endswith(".skatetrack") for name in diff_names),
            "A005 integration must not add binary package samples",
        )
        require(
            not list(ROOT.rglob("WatchBridgeSnowSessionProvider.swift")),
            "A006 WatchBridgeSnowSessionProvider must not exist during A005",
        )
    else:
        forbidden_modified = [
            "Shared/Models/RunBoundaryDetector.swift",
            "Shared/Models/SnowSegmentClassifier.swift",
            "Shared/Models/SnowClassifierConfig.swift",
            "Shared/Models/MotionSample.swift",
            "Shared/Models/SnowSegment.swift",
            "Shared/Models/SnowRun.swift",
            "Shared/Models/SnowDistanceBreakdown.swift",
            "Shared/Models/SnowVerticalMetrics.swift",
            "Shared/Models/SnowSessionState.swift",
        ]
        for path in forbidden_modified:
            require(path not in diff_names, f"forbidden Snow-Task-005 modification detected: {path}")

        require(not any(name.startswith("Shared/WatchBridge/") for name in diff_names), "Shared/WatchBridge must not be modified in Snow-Task-005")
        require(not any(name.endswith(".skatetrack") for name in diff_names), ".skatetrack sample files must not be added in Snow-Task-005")

    print("[snow-task-005] PASS: iPhone Snow live data boundary, session lifecycle wiring, SnowHUDView four-state UI, two-decimal-capable Snow distance presentation, localized downhill-information copy, unknown-only semantic status, selection-backed timeline/inspector, config-driven lowConfidence policy, mapper tests, and scope guardrails are present.")


if __name__ == "__main__":
    main()
