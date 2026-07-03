#!/usr/bin/env python3
"""Verify Task-030c-b16-B barometric GPS outlier diagnostics and safety boundaries."""
from __future__ import annotations

from pathlib import Path
import re
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


def line_count(rel: str) -> int:
    return len(read(rel).splitlines())


def main() -> int:
    required_tokens = {
        "Shared/Models/BarometricGPSOutlierDiagnostics.swift": [
            "BarometricGPSOutlierDiagnosticReason",
            "BarometricGPSOutlierDiagnosticConfig",
            "BarometricGPSOutlierDecision",
            "productionRouteDecisionApplied",
            "wouldRejectIfGateWereEnabled",
            "barometricAltitudeConflict",
            "noAltitudeConflict",
            "self.productionRouteDecisionApplied = false",
        ],
        "Shared/Models/MotionSample.swift": [
            "barometricGPSOutlierDecision: BarometricGPSOutlierDecision?",
            "barometricGPSOutlierDecision ?? self.barometricGPSOutlierDecision",
        ],
        "iOS/Core/SensorEngine/BarometricGPSOutlierGuard.swift": [
            "BarometricGPSOutlierGuard",
            "previousAnchor: BarometricGPSOutlierAnchor?",
            "candidateBarometerAltitudeMeters",
            "minimumSuspiciousJumpMeters",
            "maxAltitudeDeltaDiscrepancyMeters",
            "wouldRejectIfGateWereEnabled",
            "BarometricGPSOutlierDecision(",
        ],
        "iOS/Core/SensorEngine/SensorFusionEngine+BarometricGPSOutlierDiagnostics.swift": [
            "makeBarometricGPSOutlierDecision",
            "BarometricGPSOutlierGuard.evaluate",
        ],
        "iOS/Core/SensorEngine/SensorFusionEngine.swift": [
            "latestBarometricGPSOutlierAnchor",
            "makeBarometricGPSOutlierDecision(",
            "barometricGPSOutlierDecision: barometricGPSOutlierDecision",
            "estimatedRouteActive: false",
        ],
        "Shared/Models/SessionData.swift": [
            'static let currentDebugBuildTaskID = "Task-030c-b18-A"',
        ],
        "iOS/Features/Debug/DebugToolsPanelView.swift": [
            'Text("debug.build.currentTaskID")',
        ],
        "Tests/iOSTests/BarometricGPSOutlierDiagnosticsTests.swift": [
            "testBarometricConflictIsDiagnosticsOnlyAndWouldRejectIfGateWereEnabled",
            "XCTAssertFalse(decision.productionRouteDecisionApplied)",
            "XCTAssertTrue(decision.wouldRejectIfGateWereEnabled)",
            "testLegacyLocationDiagnosticsDecodeWithoutBarometricDecision",
        ],
        "SkateTrack.xcodeproj/project.pbxproj": [
            "BarometricGPSOutlierDiagnostics.swift in Sources",
            "BarometricGPSOutlierGuard.swift in Sources",
            "SensorFusionEngine+BarometricGPSOutlierDiagnostics.swift in Sources",
            "BarometricGPSOutlierDiagnosticsTests.swift in Sources",
        ],
        "docs/adr/ADR-INDEX.md": [
            "Task-030c-b16-B — Barometric GPS Outlier Cross-Validation Diagnostics",
            "productionRouteDecisionApplied",
            "wouldRejectIfGateWereEnabled",
            "estimatedRouteActive remains false",
        ],
        "docs/history/DEV_LOG.md": [
            "Task-030c-b16-B — Barometric GPS Outlier Cross-Validation Diagnostics",
            "diagnostics-only",
            "productionRouteDecisionApplied false",
            "estimatedRouteActive remains false",
        ],
        "docs/reference/FILE_STRUCTURE.md": [
            "Task-030c-b16-B barometric GPS outlier diagnostics",
            "BarometricGPSOutlierDiagnostics.swift",
            "BarometricGPSOutlierGuard.swift",
            "SensorFusionEngine+BarometricGPSOutlierDiagnostics.swift",
        ],
        "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
            "Task-030c-b16-B — Barometric GPS Outlier Cross-Validation Diagnostics",
            "no production route rejection",
            "estimatedRouteActive remains false",
        ],
    }

    for rel, tokens in required_tokens.items():
        for token in tokens:
            require(rel, token)

    forbidden_tokens = {
        "iOS/Core/SensorEngine/SensorFusionEngine.swift": [
            "productionRouteDecisionApplied: true",
            "estimatedRouteActive: true",
            "emitDeadReckonedSample",
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
        "Shared/Models/SessionData.swift": [
            'static let currentDebugBuildTaskID = "Task-030c-b16-A"',
        ],
        "iOS/Features/Debug/DebugToolsPanelView.swift": [
            'Text("Task-030c-b16-A")',
        ],
    }

    for rel, tokens in forbidden_tokens.items():
        for token in tokens:
            forbid(rel, token)

    model_text = read("Shared/Models/BarometricGPSOutlierDiagnostics.swift")
    if re.search(r"let\s+productionRouteDecisionApplied\s*=\s*true", model_text):
        raise AssertionError("BarometricGPSOutlierDecision must not allow productionRouteDecisionApplied true")

    for rel in [
        "Shared/Models/BarometricGPSOutlierDiagnostics.swift",
        "iOS/Core/SensorEngine/BarometricGPSOutlierGuard.swift",
        "iOS/Core/SensorEngine/SensorFusionEngine+BarometricGPSOutlierDiagnostics.swift",
        "Tests/iOSTests/BarometricGPSOutlierDiagnosticsTests.swift",
        "scripts/verify_task030c_b16b_barometric_gps_outlier_diagnostics.py",
    ]:
        count = line_count(rel)
        if count > 500:
            raise AssertionError(f"{rel} exceeds 500 lines: {count}")

    for rel in [
        "Shared/Models/SessionData.swift",
        "Shared/Models/MotionSample.swift",
        "Shared/Models/BarometricGPSOutlierDiagnostics.swift",
        "iOS/Core/SensorEngine/SensorFusionEngine.swift",
        "iOS/Core/SensorEngine/BarometricGPSOutlierGuard.swift",
        "iOS/Core/SensorEngine/SensorFusionEngine+BarometricGPSOutlierDiagnostics.swift",
        "iOS/Core/SensorEngine/GPSProvider.swift",
        "iOS/Core/SensorEngine/BarometerProvider.swift",
        "iOS/Core/SensorEngine/IMUProvider.swift",
        "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift",
    ]:
        text = read(rel)
        for token in ["SkateTrack-SnowPrototype", "prototype/snow-mode-ui-mock"]:
            if token in text:
                raise AssertionError(f"{rel}: forbidden prototype dependency token {token!r}")

    print("Task-030c-b16-B barometric GPS outlier diagnostics checks passed.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"Task-030c-b16-B check failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
