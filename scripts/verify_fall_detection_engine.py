#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
ENGINE = ROOT / "iOS/Core/SensorEngine/FallDetectionEngine.swift"
PROJECT = ROOT / "SkateTrack.xcodeproj/project.pbxproj"

REQUIRED_SNIPPETS = [
    "// [自主區]",
    "final class FallDetectionEngine",
    "impactThresholdG: 4",
    "stationaryDurationSeconds: 3",
    "sosCountdownSeconds: 15",
    "#if DEBUG",
    "impactThresholdG: 1.8",
    "func startMonitoring(",
    "func cancelFallAlert()",
    "AnyPublisher<FallEvent, Never>",
    "sosTriggerPublisher",
    "countdownPublisher",
    "FallEvent(",
    "DispatchSource.makeTimerSource",
]

FORBIDDEN_IMPORTS = ["import SwiftUI", "import UIKit", "import AppKit", "import WatchKit"]


def fail(message: str) -> None:
    print(f"Fall detection check failed: {message}")
    sys.exit(1)


if not ENGINE.exists():
    fail("missing iOS/Core/SensorEngine/FallDetectionEngine.swift")
text = ENGINE.read_text()
project_text = PROJECT.read_text()

for snippet in REQUIRED_SNIPPETS:
    if snippet not in text:
        fail(f"FallDetectionEngine.swift missing snippet: {snippet}")

for forbidden in FORBIDDEN_IMPORTS:
    if forbidden in text:
        fail(f"FallDetectionEngine.swift must not contain {forbidden}")

line_count = len(text.splitlines())
if line_count > 350:
    fail(f"FallDetectionEngine.swift has {line_count} lines, expected <= 350")

if "/* FallDetectionEngine.swift */" not in project_text:
    fail("FallDetectionEngine.swift missing from Xcode file references")
if "/* FallDetectionEngine.swift in Sources */" not in project_text:
    fail("FallDetectionEngine.swift missing from iOS Sources build phase")

print("Fall detection check passed: 4g threshold, stationary confirmation, countdown, cancel, SOS publisher")
