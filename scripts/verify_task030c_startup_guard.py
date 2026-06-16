#!/usr/bin/env python3
"""Verify Task-030c-b10-r5 startup speed spike and fall handling guards."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "Shared/Models/SessionData.swift",
    "iOS/Core/SensorEngine/SensorFusionEngine.swift",
    "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift",
    "iOS/Features/Debug/DebugToolsPanelView.swift",
    "scripts/verify_task030c_startup_guard.py",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/adr/ADR-INDEX.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
]

REQUIRED_TOKENS = {
    "Shared/Models/SessionData.swift": [
        'static let currentDebugBuildTaskID = "Task-030c-b10-r5"',
    ],
    "iOS/Core/SensorEngine/SensorFusionEngine.swift": [
        "startupStabilizationSeconds",
        "startupCoordinateDerivedSpeedSpikeKmh",
        "isStartupCoordinateDerivedSpeedSpike(",
        "let rawCoordinateDerivedSpeedKmh = makeCoordinateDerivedSpeedKmh(",
        "let coordinateDerivedSpeedKmh = (isStartupSpeedSpike || isLowSpeedLocalJump) ? nil : rawCoordinateDerivedSpeedKmh",
        "let confidence = (isStartupSpeedSpike || isLowSpeedLocalJump)",
        "? RouteSegmentConfidence.low",
        "coordinateDerivedSpeedKmh: coordinateDerivedSpeedKmh",
    ],
    "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift": [
        "startupFallHandlingSuppressionSeconds",
        "fallDetectionEngine.cancelFallAlert()",
        "fallCountdownSubject.send(nil)",
        "elapsedAfterStart >= Self.startupFallHandlingSuppressionSeconds",
    ],
    "iOS/Features/Debug/DebugToolsPanelView.swift": [
        "Task-030c-b10-r5",
    ],
    "docs/history/DEV_LOG.md": [
        "Task-030c-b10-r5",
        "Startup Speed Spike + Fall Handling Guard",
        "coordinate-derived GPS speed spikes",
    ],
    "docs/reference/FILE_STRUCTURE.md": [
        "Task-030c-b10-r5",
        "verify_task030c_startup_guard.py",
    ],
    "docs/adr/ADR-INDEX.md": [
        "Task-030c-b10-r5",
        "startup guard",
    ],
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
        "Task-030c-b10-r5",
        "Startup speed spike",
    ],
}

FORBIDDEN_TOKENS = [
    "MKDirections",
    "MKRoute",
    "road snapping",
    "map matching",
]


def fail(message: str) -> None:
    print(f"Task-030c-b10-r5 startup guard check failed: {message}", file=sys.stderr)
    sys.exit(1)


def read(path: str) -> str:
    file_path = ROOT / path
    if not file_path.exists():
        fail(f"missing required file: {path}")
    return file_path.read_text(encoding="utf-8")


def main() -> None:
    for path in REQUIRED_FILES:
        read(path)

    for path, tokens in REQUIRED_TOKENS.items():
        text = read(path)
        for token in tokens:
            if token not in text:
                fail(f"missing token {token!r} in {path}")

    fusion = read("iOS/Core/SensorEngine/SensorFusionEngine.swift")
    if fusion.find("isStartupCoordinateDerivedSpeedSpike(") > fusion.find("routeSegmentConfidence("):
        fail("startup spike check must run before route segment confidence is finalized")
    if fusion.find("let coordinateDerivedSpeedKmh = (isStartupSpeedSpike || isLowSpeedLocalJump) ? nil") > fusion.find("locationSpeedSource("):
        fail("startup spike must remove coordinate-derived speed before assigning speed source")

    coordinator = read("iOS/Core/SessionRecording/SessionRecordingCoordinator.swift")
    if coordinator.find("fallDetectionEngine.cancelFallAlert()") > coordinator.find("activeFallEvent = fallEvent"):
        fail("fall alert cancellation guard must run before activating a fall event")
    if coordinator.find("return fallEvents.filter") > coordinator.find("elapsedAfterStart >= Self.startupFallHandlingSuppressionSeconds"):
        fail("persisted fallEvents must apply startup fall handling suppression")

    combined = "\n".join(
        read(path)
        for path in REQUIRED_FILES
        if path != "scripts/verify_task030c_startup_guard.py"
    )
    for token in FORBIDDEN_TOKENS:
        if token in combined and token not in read("docs/release/KNOWN_LIMITATIONS_PRE_ADP.md"):
            fail(f"unexpected route geometry token found: {token}")

    print("Task-030c-b10-r5 startup guard checks passed.")


if __name__ == "__main__":
    main()
