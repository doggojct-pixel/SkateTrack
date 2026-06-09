#!/usr/bin/env python3
"""Validate Task-008 Barometer Provider implementation."""

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
BAROMETER_FILE = ROOT / "iOS/Core/SensorEngine/BarometerProvider.swift"
PROJECT_FILE = ROOT / "SkateTrack.xcodeproj/project.pbxproj"

REQUIRED_SNIPPETS = [
    "// [自主區]",
    "import CoreMotion",
    "import Combine",
    "CMAltimeter",
    "CMAltitudeData",
    "isRelativeAltitudeAvailable",
    "startRelativeAltitudeUpdates",
    "stopRelativeAltitudeUpdates",
    "AnyPublisher<CMAltitudeData, Never>",
    "relativeAltitude.doubleValue",
    "pressure.doubleValue",
]

FORBIDDEN_IMPORTS = ["import SwiftUI", "import UIKit"]


def fail(message: str) -> None:
    print(f"Barometer provider check failed: {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    if not BAROMETER_FILE.exists():
        fail("missing iOS/Core/SensorEngine/BarometerProvider.swift")

    text = BAROMETER_FILE.read_text()

    for snippet in REQUIRED_SNIPPETS:
        if snippet not in text:
            fail(f"missing required snippet in BarometerProvider.swift: {snippet}")

    for forbidden in FORBIDDEN_IMPORTS:
        if forbidden in text:
            fail(f"forbidden UI import found: {forbidden}")

    line_count = len(text.splitlines())
    if line_count > 200:
        fail(f"BarometerProvider.swift exceeds 200 lines: {line_count}")

    project = PROJECT_FILE.read_text()
    if "BarometerProvider.swift in Sources" not in project:
        fail("BarometerProvider.swift is not in the iOS target Sources build phase")

    print("Barometer provider check passed: relative altitude provider")


if __name__ == "__main__":
    main()
