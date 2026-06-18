#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
FUSION = ROOT / "iOS/Core/SensorEngine/SensorFusionEngine.swift"
CALIBRATION = ROOT / "iOS/Core/SensorEngine/SensorCalibrationEngine.swift"
PROJECT = ROOT / "SkateTrack.xcodeproj/project.pbxproj"

REQUIRED_FUSION_SNIPPETS = [
    "// [自主區]",
    "final class SensorFusionEngine: SensorProvider",
    "static let sampleFrequencyHz: Double = 10",
    "static let sampleIntervalSeconds: TimeInterval = 1 / sampleFrequencyHz",
    "AnyPublisher<MotionSample, Never>",
    "func startSession(",
    "powerType: PowerType = .humanPowered",
    "fidelityProfile: ActivityFidelityProfile? = nil",
    "func stopSession() async -> SessionData",
    "func startRecording(",
    "func stopRecording() async -> SessionData",
    "GPSProvider",
    "IMUProvider",
    "BarometerProvider",
    "DispatchSource.makeTimerSource",
]

REQUIRED_CALIBRATION_SNIPPETS = [
    "// [自主區]",
    "final class SensorCalibrationEngine",
    "func priorityPlan(for mode: SportMode)",
    "SensorFusionPriorityPlan",
    "case gps",
    "case imu",
    "case barometer",
]

FORBIDDEN_IMPORTS = ["import SwiftUI", "import UIKit", "import AppKit", "import WatchKit"]


def fail(message: str) -> None:
    print(f"Sensor fusion check failed: {message}")
    sys.exit(1)


def require_file(path: Path) -> str:
    if not path.exists():
        fail(f"missing {path.relative_to(ROOT)}")
    return path.read_text()


def require_snippets(text: str, snippets: list[str], filename: str) -> None:
    for snippet in snippets:
        if snippet not in text:
            fail(f"{filename} missing snippet: {snippet}")


def require_line_limit(text: str, filename: str, limit: int) -> None:
    count = len(text.splitlines())
    if count > limit:
        fail(f"{filename} has {count} lines, expected <= {limit}")


def require_no_ui_imports(text: str, filename: str) -> None:
    for forbidden in FORBIDDEN_IMPORTS:
        if forbidden in text:
            fail(f"{filename} must not contain {forbidden}")


def require_project_membership(project_text: str) -> None:
    for name in ["SensorFusionEngine.swift", "SensorCalibrationEngine.swift"]:
        if f"/* {name} */" not in project_text:
            fail(f"{name} missing from Xcode file references")
        if f"/* {name} in Sources */" not in project_text:
            fail(f"{name} missing from iOS Sources build phase")


fusion_text = require_file(FUSION)
calibration_text = require_file(CALIBRATION)
project_text = require_file(PROJECT)

require_snippets(fusion_text, REQUIRED_FUSION_SNIPPETS, "SensorFusionEngine.swift")
require_snippets(calibration_text, REQUIRED_CALIBRATION_SNIPPETS, "SensorCalibrationEngine.swift")
require_line_limit(fusion_text, "SensorFusionEngine.swift", 640)
require_line_limit(calibration_text, "SensorCalibrationEngine.swift", 250)
require_no_ui_imports(fusion_text, "SensorFusionEngine.swift")
require_no_ui_imports(calibration_text, "SensorCalibrationEngine.swift")
require_project_membership(project_text)

print("Sensor fusion check passed: 10Hz MotionSample engine and calibration priority plan")
