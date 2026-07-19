#!/usr/bin/env python3
from pathlib import Path
import os
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "SkateTrack.xcodeproj/project.pbxproj"

REQUIRED_FILES = [
    ROOT / "iOS/Core/SessionRecording/SessionStateMachine.swift",
    ROOT / "iOS/Core/SessionRecording/SessionMetricsAccumulator.swift",
    ROOT / "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift",
    ROOT / "iOS/Core/SessionRecording/SessionRecordingCoordinator+DebugMock.swift",
    ROOT / "iOS/Hooks/useSessionRecording.swift",
    ROOT / "Shared/Models/SessionSummaryMetrics.swift",
    ROOT / "Tests/iOSTests/SessionRecordingCoordinatorTests.swift",
]

REQUIRED_SNIPPETS = {
    "SessionStateMachine.swift": [
        "// [自主區]",
        "enum SessionRecordingStatus",
        "func canTransition(from current:",
        "case .idle:",
    ],
    "SessionMetricsAccumulator.swift": [
        "// [自主區]",
        "struct SessionMetricsAccumulator",
        "makeSummaryMetrics()",
        "makeLiveMetrics()",
    ],
    "SessionRecordingCoordinator.swift": [
        "// [自主區]",
        "final class SessionRecordingCoordinator",
        "let sessionRepository: SessionRepositoryProtocol",
        "func startSession(",
        "func pauseSession()",
        "func resumeSession()",
        "func requestEndSession()",
        "sessionRepository.saveCompletedSession",
        "equipmentMileageTracker",
        "func discardCurrentSession()",
        "FallDetectionEngine",
        "SensorFusionEngine",
    ],
    "SessionRecordingCoordinator+DebugMock.swift": [
        "// [自主區]",
        "#if DEBUG",
        "func startMockSampleFeed",
        "func stopMockSampleFeed",
        "func makeMockSample",
    ],
    "useSessionRecording.swift": [
        "// [協作區",
        "final class SessionRecordingViewModel",
        "func useSessionRecording(",
        "SessionRecordingActions",
    ],
    "SessionSummaryMetrics.swift": [
        "// [協作區]",
        "struct SessionSummaryMetrics",
        "struct LiveSessionMetrics",
    ],
}

LOCALIZATION_KEYS = [
    "session.status.idle",
    "session.status.preparing",
    "session.status.recording",
    "session.status.paused",
    "session.status.saving",
    "session.error.invalidPowerType",
    "session.error.sensorUnavailable",
]

FORBIDDEN_IMPORTS = ["import SwiftUI", "import UIKit", "import AppKit", "import WatchKit"]
LINE_LIMITS = {
    "SessionStateMachine.swift": 250,
    "SessionMetricsAccumulator.swift": 350,
    "SessionRecordingCoordinator.swift": 450,
    "SessionRecordingCoordinator+DebugMock.swift": 180,
    "useSessionRecording.swift": 350,
}
A005_INTEGRATION_MODE = os.environ.get("SNOW_INTEGRATION_A005") == "1"
A005_OVERSIZED_BASELINES = {
    "SessionRecordingCoordinator.swift": 55,
    "SessionRecordingCoordinator+DebugMock.swift": 5,
    "useSessionRecording.swift": 28,
}


def fail(message: str) -> None:
    print(f"Session recording check failed: {message}")
    sys.exit(1)


def verify_a005_oversized_baseline(file_path: Path, final_line_count: int) -> None:
    expected_growth = A005_OVERSIZED_BASELINES.get(file_path.name)
    if not A005_INTEGRATION_MODE or expected_growth is None:
        fail(f"{file_path.name} has {final_line_count} lines, expected <= {LINE_LIMITS[file_path.name]}")

    rel_path = str(file_path.relative_to(ROOT))
    result = subprocess.run(
        ["git", "-C", str(ROOT), "show", f"HEAD:{rel_path}"],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        fail(f"unable to read HEAD baseline for {rel_path}")
    head_line_count = len(result.stdout.splitlines())
    if head_line_count <= LINE_LIMITS[file_path.name]:
        fail(f"A005 oversized baseline was not already oversized in HEAD: {rel_path}")
    if final_line_count - head_line_count != expected_growth:
        fail(
            f"unexpected A005 line growth for {rel_path}: "
            f"HEAD={head_line_count}, final={final_line_count}, expected_growth={expected_growth}"
        )


for file_path in REQUIRED_FILES:
    if not file_path.exists():
        fail(f"missing required file: {file_path.relative_to(ROOT)}")

project_text = PROJECT.read_text()

for file_path in REQUIRED_FILES:
    text = file_path.read_text()
    name = file_path.name

    if name in REQUIRED_SNIPPETS:
        for snippet in REQUIRED_SNIPPETS[name]:
            if snippet not in text:
                fail(f"{name} missing snippet: {snippet}")

    if file_path.parent.name == "SessionRecording":
        for forbidden in FORBIDDEN_IMPORTS:
            if forbidden in text:
                fail(f"{name} must not contain {forbidden}")

    if name in LINE_LIMITS:
        line_count = len(text.splitlines())
        if line_count > LINE_LIMITS[name]:
            verify_a005_oversized_baseline(file_path, line_count)

    if f"/* {name} */" not in project_text and f"/* {name} in Sources */" not in project_text:
        if name != "SessionRecordingCoordinatorTests.swift":
            fail(f"{name} missing from Xcode project references")

if "SkateTrack-iOSTests" not in project_text:
    fail("SkateTrack-iOSTests target missing from Xcode project")

for key in LOCALIZATION_KEYS:
    for language in ("en", "zh-Hant"):
        strings_path = ROOT / f"Shared/Localization/{language}.lproj/Localizable.strings"
        if f"\"{key}\"" not in strings_path.read_text():
            fail(f"missing localization key {key} in {language}")

print(
    "Session recording check passed: coordinator, hook, metrics, state machine, tests, localization keys"
)
