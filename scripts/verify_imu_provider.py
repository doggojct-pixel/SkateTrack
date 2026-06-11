#!/usr/bin/env python3
"""Validate Task-007 IMU Provider implementation."""

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
IMU_FILE = ROOT / "iOS/Core/SensorEngine/IMUProvider.swift"
PROJECT_FILE = ROOT / "SkateTrack.xcodeproj/project.pbxproj"
INFOPLIST_FILES = [
    ROOT / "Shared/Localization/en.lproj/InfoPlist.strings",
    ROOT / "Shared/Localization/zh-Hant.lproj/InfoPlist.strings",
]

REQUIRED_SNIPPETS = [
    "// [自主區]",
    "import CoreMotion",
    "import Combine",
    "CMMotionManager",
    "accelerometerUpdateInterval",
    "gyroUpdateInterval",
    "1 / targetFrequencyHz",
    "AnyPublisher<CMAccelerometerData, Never>",
    "AnyPublisher<CMGyroData, Never>",
    "startAccelerometerUpdates",
    "startGyroUpdates",
    "isAccelerometerAvailable",
    "isGyroAvailable",
    "static let zero",
]

FORBIDDEN_IMPORTS = ["import SwiftUI", "import UIKit"]


def fail(message: str) -> None:
    print(f"IMU provider check failed: {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    if not IMU_FILE.exists():
        fail("missing iOS/Core/SensorEngine/IMUProvider.swift")

    text = IMU_FILE.read_text()

    for snippet in REQUIRED_SNIPPETS:
        if snippet not in text:
            fail(f"missing required snippet in IMUProvider.swift: {snippet}")

    for forbidden in FORBIDDEN_IMPORTS:
        if forbidden in text:
            fail(f"forbidden UI import found: {forbidden}")

    line_count = len(text.splitlines())
    if line_count > 300:
        fail(f"IMUProvider.swift exceeds 300 lines: {line_count}")

    project = PROJECT_FILE.read_text()
    if "IMUProvider.swift in Sources" not in project:
        fail("IMUProvider.swift is not in the iOS target Sources build phase")
    if "INFOPLIST_KEY_NSMotionUsageDescription" not in project:
        fail("missing NSMotionUsageDescription generated Info.plist build setting")

    for infoplist_file in INFOPLIST_FILES:
        if not infoplist_file.exists():
            fail(f"missing localized InfoPlist.strings: {infoplist_file.relative_to(ROOT)}")
        infoplist = infoplist_file.read_text()
        if "NSMotionUsageDescription" not in infoplist:
            fail(f"missing NSMotionUsageDescription in {infoplist_file.relative_to(ROOT)}")

    print("IMU provider check passed: 50Hz accelerometer and gyroscope provider with motion privacy usage description")


if __name__ == "__main__":
    main()
