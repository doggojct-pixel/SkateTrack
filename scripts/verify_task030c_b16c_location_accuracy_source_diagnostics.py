#!/usr/bin/env python3
"""Verify Task-030c-b16-C passive Wi-Fi RTT / accuracy-source diagnostics safety boundaries."""
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


def require_first_line_marker(rel: str, marker: str) -> None:
    first_line = read(rel).splitlines()[0]
    if not first_line.startswith(marker):
        raise AssertionError(f"{rel}: first line must start with {marker!r}")


def line_count(rel: str) -> int:
    return len(read(rel).splitlines())


def main() -> int:
    required_tokens = {
        "Shared/Models/LocationAccuracySourceDiagnostics.swift": [
            "LocationAccuracySourceClass",
            "likelyHighPrecisionGPSOrWiFiRTT",
            "possibleGoodGPSOrWiFiRTT",
            "cellOrCachedPosition",
            "LocationAccuracySourceDiagnostics",
            "passiveInferenceOnly",
            "explicitWiFiAPIUsed",
            "wifiRTTConfirmed",
            "self.passiveInferenceOnly = true",
            "self.explicitWiFiAPIUsed = false",
            "self.wifiRTTConfirmed = false",
        ],
        "Shared/Models/MotionSample.swift": [
            "locationAccuracySourceDiagnostics: LocationAccuracySourceDiagnostics?",
            "locationAccuracySourceDiagnostics ?? self.locationAccuracySourceDiagnostics",
        ],
        "iOS/Core/SensorEngine/LocationAccuracySourceClassifier.swift": [
            "LocationAccuracySourceClassifier",
            "horizontalAccuracyMeters < 3",
            "horizontalAccuracyMeters <= 8",
            "horizontalAccuracyMeters <= 20",
            "horizontalAccuracyMeters <= 50",
            "passive CoreLocation accuracy-source",
        ],
        "iOS/Core/SensorEngine/SensorFusionEngine.swift": [
            "LocationAccuracySourceClassifier.classify(",
            "locationAccuracySourceDiagnostics: locationAccuracySourceDiagnostics",
            "estimatedRouteActive: false",
        ],
        "Shared/Models/SessionData.swift": [
            'static let currentDebugBuildTaskID = "Task-030c-b19"',
        ],
        "iOS/Features/Debug/DebugToolsPanelView.swift": [
            'Text("debug.build.currentTaskID")',
        ],
        "Tests/iOSTests/LocationAccuracySourceDiagnosticsTests.swift": [
            "testHighPrecisionAccuracyIsPassiveAndNotConfirmedWiFiRTT",
            "XCTAssertFalse(diagnostics.explicitWiFiAPIUsed)",
            "XCTAssertFalse(diagnostics.wifiRTTConfirmed)",
            "testLegacyLocationDiagnosticsDecodeWithoutAccuracySourceDiagnostics",
        ],
        "SkateTrack.xcodeproj/project.pbxproj": [
            "LocationAccuracySourceDiagnostics.swift in Sources",
            "LocationAccuracySourceClassifier.swift in Sources",
            "LocationAccuracySourceDiagnosticsTests.swift in Sources",
        ],
        "docs/adr/ADR-INDEX.md": [
            "Task-030c-b16-C — Passive Wi-Fi RTT / Accuracy Source Diagnostics",
            "passiveInferenceOnly",
            "explicitWiFiAPIUsed false",
            "wifiRTTConfirmed false",
            "estimatedRouteActive remains false",
        ],
        "docs/history/DEV_LOG.md": [
            "Task-030c-b16-C — Passive Wi-Fi RTT / Accuracy Source Diagnostics",
            "passive accuracy-source diagnostics",
            "no Wi-Fi entitlement",
            "estimatedRouteActive remains false",
        ],
        "docs/reference/FILE_STRUCTURE.md": [
            "Task-030c-b16-C passive accuracy-source diagnostics",
            "LocationAccuracySourceDiagnostics.swift",
            "LocationAccuracySourceClassifier.swift",
            "LocationAccuracySourceDiagnosticsTests.swift",
        ],
        "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
            "Task-030c-b16-C — Passive Wi-Fi RTT / Accuracy Source Diagnostics",
            "does not confirm Wi-Fi RTT",
            "no Wi-Fi scanning",
            "estimatedRouteActive remains false",
        ],
    }

    for rel, tokens in required_tokens.items():
        for token in tokens:
            require(rel, token)

    require_first_line_marker("Shared/Models/LocationAccuracySourceDiagnostics.swift", "// [協作區]")
    require_first_line_marker("iOS/Core/SensorEngine/LocationAccuracySourceClassifier.swift", "// [自主區]")
    require_first_line_marker("Tests/iOSTests/LocationAccuracySourceDiagnosticsTests.swift", "// [自主區]")

    for rel in [
        "Shared/Models/LocationAccuracySourceDiagnostics.swift",
        "iOS/Core/SensorEngine/LocationAccuracySourceClassifier.swift",
        "Tests/iOSTests/LocationAccuracySourceDiagnosticsTests.swift",
        "scripts/verify_task030c_b16c_location_accuracy_source_diagnostics.py",
    ]:
        count = line_count(rel)
        if count > 500:
            raise AssertionError(f"{rel} exceeds 500 lines: {count}")

    forbidden_production_tokens = [
        "CNCopyCurrentNetworkInfo",
        "NEHotspot",
        "CoreWLAN",
        "NetworkExtension",
        "CaptiveNetwork",
        "com.apple.developer.networking.wifi-info",
        "explicitWiFiAPIUsed = true",
        "wifiRTTConfirmed = true",
        "passiveInferenceOnly = false",
        "estimatedRouteActive: true",
        "productionRouteDecisionApplied: true",
        "roadSnapping",
        "mapMatching",
    ]
    for rel in [
        "Shared/Models/LocationAccuracySourceDiagnostics.swift",
        "Shared/Models/MotionSample.swift",
        "iOS/Core/SensorEngine/LocationAccuracySourceClassifier.swift",
        "iOS/Core/SensorEngine/SensorFusionEngine.swift",
        "iOS/Core/SensorEngine/GPSProvider.swift",
        "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift",
    ]:
        for token in forbidden_production_tokens:
            forbid(rel, token)

    model_text = read("Shared/Models/LocationAccuracySourceDiagnostics.swift")
    if re.search(r"let\s+explicitWiFiAPIUsed\s*=\s*true", model_text):
        raise AssertionError("LocationAccuracySourceDiagnostics must not allow explicitWiFiAPIUsed true")
    if re.search(r"let\s+wifiRTTConfirmed\s*=\s*true", model_text):
        raise AssertionError("LocationAccuracySourceDiagnostics must not allow wifiRTTConfirmed true")

    print("Task-030c-b16-C passive accuracy-source diagnostics checks passed.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"Task-030c-b16-C check failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
