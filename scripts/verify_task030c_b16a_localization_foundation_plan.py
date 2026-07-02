#!/usr/bin/env python3
"""Verify Task-030c-b16-A localization foundation plan and safety boundaries."""
from __future__ import annotations

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]


def read(rel: str) -> str:
    path = ROOT / rel
    if not path.exists():
        raise AssertionError(f"Missing file: {rel}")
    return path.read_text(encoding="utf-8")


def require(rel: str, token: str) -> None:
    text = read(rel)
    if token not in text:
        raise AssertionError(f"{rel}: missing token {token!r}")


def forbid(rel: str, token: str) -> None:
    text = read(rel)
    if token in text:
        raise AssertionError(f"{rel}: forbidden token {token!r}")


def main() -> int:
    required_tokens = {
        "docs/planning/Task-030c-b16_Localization_Foundation_Plan.md": [
            "Task-030c-b16-A",
            "Task-030c-b16-B",
            "Task-030c-b16-C",
            "Task-030c-b16-D",
            "barometric GPS cross-validation",
            "Wi-Fi RTT diagnostics",
            "magnetometer heading quality",
            "IMU replay-only gap interpolation",
            "indoor mode detector",
            "Task-031",
            "No camera localization",
            "No camera-based visual localization",
            "No road snapping",
            "No fake GPS",
            "No RTK GPS dependency",
            "No UWB anchor dependency",
            "No SnowPrototype contamination",
            "estimatedRouteActive remains false",
            "productionRouteDecisionApplied",
            "wouldRejectIfGateWereEnabled",
            "LocationAccuracySourceClass",
            "HeadingReliability",
            "product decision checkpoint",
            "Small-area raw GPS geometry cannot be perfectly reconstructed from GPS alone",
        ],
        "docs/adr/ADR-INDEX.md": [
            "Task-030c-b16-A — Localization Foundation Audit",
            "barometric GPS cross-validation",
            "passive Wi-Fi RTT diagnostics",
            "magnetometer heading quality",
            "IMU replay-only gap interpolation",
            "Task-031 owns indoor localization",
            "estimatedRouteActive remains false",
        ],
        "docs/history/DEV_LOG.md": [
            "Task-030c-b16-A — Localization Foundation Audit and Sensor-Fusion Plan",
            "b16-B as diagnostics-only barometric GPS cross-validation",
            "b16-C as passive Wi-Fi RTT / accuracy-source diagnostics",
            "b16-D as magnetometer heading quality consolidation",
            "indoor localization is deferred to Task-031",
            "estimatedRouteActive remains false",
        ],
        "docs/reference/FILE_STRUCTURE.md": [
            "Task-030c-b16-A localization foundation audit",
            "docs/planning/Task-030c-b16_Localization_Foundation_Plan.md",
            "verify_task030c_b16a_localization_foundation_plan.py",
            "estimatedRouteActive remains false",
        ],
        "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
            "Task-030c-b16-A — Localization Foundation Audit and Sensor-Fusion Plan",
            "indoor mode detector deferred to Task-031",
            "no camera localization",
            "no road snapping",
            "no fake GPS",
            "no RTK GPS dependency",
            "no UWB anchor dependency",
            "estimatedRouteActive remains false",
        ],
        "Shared/Models/SessionData.swift": [
            'static let currentDebugBuildTaskID = "Task-030c-b16-A"',
        ],
        "iOS/Features/Debug/DebugToolsPanelView.swift": [
            'Text("Task-030c-b16-A")',
            "debugBuildSignatureCard",
        ],
        "iOS/Core/SensorEngine/SensorFusionEngine.swift": [
            "estimatedRouteActive: false",
        ],
    }

    for rel, tokens in required_tokens.items():
        for token in tokens:
            require(rel, token)

    forbidden_tokens = {
        "Shared/Models/SessionData.swift": [
            'static let currentDebugBuildTaskID = "Task-030c-b15-B-3"',
        ],
        "iOS/Features/Debug/DebugToolsPanelView.swift": [
            'Text("Task-030c-b15-B-3")',
        ],
        "iOS/Core/SensorEngine/SensorFusionEngine.swift": [
            "estimatedRouteActive: true",
            "emitDeadReckonedSample",
            "estimatedCoordinate",
            "roadSnapping",
            "mapMatching",
        ],
        "iOS/Core/SensorEngine/GPSProvider.swift": [
            "BarometricGPSOutlierGuard(",
            "productionRouteDecisionApplied: true",
            "estimatedRouteActive: true",
            "roadSnapping",
            "mapMatching",
        ],
        "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift": [
            "productionRouteDecisionApplied: true",
            "estimatedRouteActive: true",
            "emitDeadReckonedSample",
        ],
    }

    for rel, tokens in forbidden_tokens.items():
        for token in tokens:
            forbid(rel, token)

    # Guard against accidental hard dependency on the prototype path in production source.
    production_files = [
        "Shared/Models/SessionData.swift",
        "Shared/Models/MotionSample.swift",
        "iOS/Core/SensorEngine/SensorFusionEngine.swift",
        "iOS/Core/SensorEngine/GPSProvider.swift",
        "iOS/Core/SensorEngine/BarometerProvider.swift",
        "iOS/Core/SensorEngine/IMUProvider.swift",
        "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift",
        "iOS/Features/Debug/DebugToolsPanelView.swift",
    ]
    for rel in production_files:
        text = read(rel)
        for token in ["SkateTrack-SnowPrototype", "prototype/snow-mode-ui-mock"]:
            if token in text:
                raise AssertionError(f"{rel}: forbidden prototype dependency token {token!r}")

    print("Task-030c-b16-A localization foundation plan checks passed.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"Task-030c-b16-A localization foundation plan check failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
