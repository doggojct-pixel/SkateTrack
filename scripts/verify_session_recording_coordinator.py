#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "SkateTrack.xcodeproj/project.pbxproj"

REQUIRED_FILES = [
    ROOT / "iOS/Core/SessionRecording/SessionStateMachine.swift",
    ROOT / "iOS/Core/SessionRecording/SessionMetricsAccumulator.swift",
    ROOT / "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift",
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
        "func startSession(mode:",
        "func pauseSession()",
        "func resumeSession()",
        "func requestEndSession()",
        "func discardCurrentSession()",
        "FallDetectionEngine",
        "SensorFusionEngine",
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
    "useSessionRecording.swift": 350,
}


def fail(message: str) -> None:
    print(f"Session recording check failed: {message}")
    sys.exit(1)


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
            fail(f"{name} has {line_count} lines, expected <= {LINE_LIMITS[name]}")

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
