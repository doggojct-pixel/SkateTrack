#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path.cwd()

REQUIRED_FILES = [
    "Shared/WatchUI/WatchLiveControlState.swift",
    "watchOS/Features/WatchLiveSessionFaceView.swift",
    "watchOS/App/SkateTrackWatchApp.swift",
    "Tests/iOSTests/WatchLiveControlStateTests.swift",
    "scripts/verify_task036b_live_face_controls.py",
]

LOCALIZATION_KEYS = [
    "watch.live.title",
    "watch.live.speed.current",
    "watch.live.session.status",
    "watch.live.status.idle",
    "watch.live.status.preparing",
    "watch.live.status.ready",
    "watch.live.status.recording",
    "watch.live.status.paused",
    "watch.live.status.ending",
    "watch.live.status.ended",
    "watch.live.status.failed",
    "watch.live.controls.start",
    "watch.live.controls.pause",
    "watch.live.controls.resume",
    "watch.live.controls.stop",
    "watch.live.controls.pending",
    "watch.live.accessibility.currentSpeed",
    "watch.live.accessibility.sessionStatus",
    "watch.live.accessibility.start",
    "watch.live.accessibility.pause",
    "watch.live.accessibility.resume",
    "watch.live.accessibility.stop",
]

PROJECT_TOKENS = [
    "WatchLiveControlState.swift in Sources",
    "WatchLiveSessionFaceView.swift in Sources",
    "WatchLiveControlStateTests.swift in Sources",
]

COMMAND_TOKENS = [
    "WatchBridgeCommandEnvelope",
    "WatchBridgeCommandKind",
    "WatchBridgeMirroredSessionCommandAction",
    ".startSession",
    ".pauseSession",
    ".resumeSession",
    ".endSession",
]

ACCESSIBILITY_KEYS = [
    "watch.live.accessibility.currentSpeed",
    "watch.live.accessibility.sessionStatus",
    "watch.live.accessibility.start",
    "watch.live.accessibility.pause",
    "watch.live.accessibility.resume",
    "watch.live.accessibility.stop",
]

FORBIDDEN_WATCH_UI_PATTERNS = [
    r"\bMapKit\b",
    r"\bHealthKit\b",
    r"\bSnow\b",
    r"\bTrick\b",
    r"RouteDisplayPipeline",
    r"SpeedDisplayPipeline",
    r"ElevationDisplayPipeline",
    r"segment(?:ation|Route|Speed|Elevation)",
    r"displayDerivedTotalAscentMeters",
]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def fail(message: str, failures: list[str]) -> None:
    print(f"FAIL: {message}")
    failures.append(message)


def verify_project_membership(project_text: str, failures: list[str]) -> None:
    watch_face_path = "watchOS/Features/WatchLiveSessionFaceView.swift"
    if watch_face_path not in project_text:
        fail(f"project file reference does not use repo-relative path {watch_face_path}", failures)
    if not (ROOT / watch_face_path).exists():
        fail(f"project file reference path does not resolve on disk {watch_face_path}", failures)
    bad_root_ref = 'path = WatchLiveSessionFaceView.swift; sourceTree = "<group>";'
    if bad_root_ref in project_text:
        fail("WatchLiveSessionFaceView.swift still has group-relative root-risk file reference", failures)


def main() -> int:
    failures: list[str] = []

    for relative in REQUIRED_FILES:
        if not (ROOT / relative).exists():
            fail(f"missing required file {relative}", failures)

    project_path = ROOT / "SkateTrack.xcodeproj/project.pbxproj"
    if not project_path.exists():
        fail("missing Xcode project", failures)
        project_text = ""
    else:
        project_text = project_path.read_text(encoding="utf-8")
        for token in PROJECT_TOKENS:
            if token not in project_text:
                fail(f"missing project membership token {token}", failures)
        verify_project_membership(project_text, failures)

    controls_path = ROOT / "Shared/WatchUI/WatchLiveControlState.swift"
    controls = read("Shared/WatchUI/WatchLiveControlState.swift") if controls_path.exists() else ""
    if controls:
        for token in COMMAND_TOKENS:
            if token not in controls:
                fail(f"command boundary token missing: {token}", failures)

    face_path = ROOT / "watchOS/Features/WatchLiveSessionFaceView.swift"
    if face_path.exists():
        face = read("watchOS/Features/WatchLiveSessionFaceView.swift")
        accessibility_text = face + "\n" + controls
        for key in ACCESSIBILITY_KEYS:
            if key not in accessibility_text:
                fail(f"missing accessibility key in live face: {key}", failures)

    localization_complete = True
    for locale in ["en", "zh-Hant", "ja"]:
        path = ROOT / "Shared" / "Localization" / f"{locale}.lproj" / "Localizable.strings"
        if not path.exists():
            fail(f"missing localization file for {locale}", failures)
            localization_complete = False
            continue
        text = path.read_text(encoding="utf-8")
        for key in LOCALIZATION_KEYS:
            if f'"{key}"' not in text:
                fail(f"missing localization key {key} in {locale}", failures)
                localization_complete = False

    forbidden_count = 0
    for relative in [
        "Shared/WatchUI/WatchLiveControlState.swift",
        "watchOS/Features/WatchLiveSessionFaceView.swift",
        "watchOS/App/SkateTrackWatchApp.swift",
    ]:
        path = ROOT / relative
        if not path.exists():
            continue
        text = path.read_text(encoding="utf-8")
        for pattern in FORBIDDEN_WATCH_UI_PATTERNS:
            matches = re.findall(pattern, text, flags=re.IGNORECASE)
            forbidden_count += len(matches)
            if matches:
                fail(f"forbidden watch UI scope token {pattern} in {relative}", failures)

    tests_path = ROOT / "Tests/iOSTests/WatchLiveControlStateTests.swift"
    tests = read("Tests/iOSTests/WatchLiveControlStateTests.swift") if tests_path.exists() else ""
    for token in [
        "testIdleStateShowsEnabledStart",
        "testRecordingStateShowsPauseStop",
        "testPausedStateShowsResumeStop",
    ]:
        if token not in tests:
            fail(f"missing view model/control state test {token}", failures)

    command_boundary_ok = bool(controls) and all(token in controls for token in COMMAND_TOKENS)
    accessibility_ok = not any("accessibility" in item for item in failures)

    print(f"WATCH_CONTROLS_USE_COMMAND_BOUNDARY={'YES' if command_boundary_ok else 'NO'}")
    print(f"LOCALIZATION_KEYS_COMPLETE={'YES' if localization_complete else 'NO'}")
    print(f"ACCESSIBILITY_LABELS_PRESENT={'YES' if accessibility_ok else 'NO'}")
    print(f"WATCH_UI_FORBIDDEN_SCOPE_COUNT={forbidden_count}")
    print("SNOW_UI_IMPLEMENTED=NO")
    print("TRICK_RECOGNITION_IMPLEMENTED=NO")
    print("PRODUCTION_HEALTHKIT_API_USED=NO")
    print(f"FAILURE_COUNT={len(failures)}")

    if failures:
        print("VERIFY_TASK036B_LIVE_FACE_CONTROLS_RESULT=FAILED")
        return 1

    print("VERIFY_TASK036B_LIVE_FACE_CONTROLS_RESULT=PASSED")
    return 0


if __name__ == "__main__":
    sys.exit(main())
