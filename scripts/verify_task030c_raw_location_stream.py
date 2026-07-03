#!/usr/bin/env python3
"""Verify Task-030c-b4 raw CLLocation stream persistence safeguards."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "Shared/Models/MotionSample.swift",
    "iOS/Core/SensorEngine/SensorFusionEngine.swift",
    "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift",
    "iOS/Core/SessionRecording/SessionRecordingCoordinator+DebugMock.swift",
    "iOS/Core/Export/SkateTrackPackageExportProvider.swift",
    "iOS/Features/SessionSummary/SessionRouteMapView.swift",
    "scripts/verify_task030c_raw_location_stream.py",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/adr/ADR-INDEX.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
]

MODEL_TOKENS = [
    "enum MotionSampleSource",
    "case timerFusion",
    "case locationFix",
    "case debugSimulated",
    "let sampleSource: MotionSampleSource?",
    "sampleSource: MotionSampleSource? = .timerFusion",
    "uniqueLocationFixKeys",
    "locationFixKey(for:",
]

FUSION_TOKENS = [
    "publishRawLocationFixMotionSample(for: location, diagnostics: diagnostics)",
    "sampleSource: .locationFix",
    "sessionSamples.append(sample)",
    "motionSampleSubject.send(sample)",
    "timestamp: location.timestamp",
    "normalizedAltitude(from: location)",
]

COORDINATOR_TOKENS = [
    "trustedRouteDistanceKilometers(from: samples, policy:",
    "confidence != .low",
    "interval <= policy.maximumTrustedUpdateIntervalSeconds",
    "segmentDistanceMeters <= policy.maximumTrustedSegmentDistanceMeters",
    "impliedSpeedKmh <= policy.maximumTrustedImpliedSpeedKmh",
    "policy.maximumTrustedSegmentDistanceMeters",
]


DEBUG_TOKENS = [
    "sampleSource: .debugSimulated",
]

PACKAGE_TOKENS = [
    "raw-location-stream-v1",
    "altitude-source-stabilization-v1",
]


MAP_TOKENS = [
    'NSLocalizedString("summary.route.start"',
    'NSLocalizedString("summary.route.finish"',
]

DOC_TOKENS = [
    "Task-030c-b4",
    "Raw CLLocation Stream Persistence",
    "raw-location-stream-v1",
    "raw location fix stream",
    "road snapping deferred",
]

FORBIDDEN_SOURCE_TOKENS = [
    "MKDirections",
    "MKRoute",
    "GoogleMaps",
    "GIDSignIn",
    "GoogleSignIn",
    "CloudKit",
    "NSUbiquitousContainers",
    "StoreKit",
]


def fail(message: str) -> None:
    print(f"Task-030c-b4 raw location stream check failed: {message}", file=sys.stderr)
    sys.exit(1)


def read(path: str) -> str:
    file_path = ROOT / path
    if not file_path.exists():
        fail(f"missing required file: {path}")
    return file_path.read_text(encoding="utf-8")


def require_tokens(path: str, tokens: list[str], label: str) -> None:
    text = read(path)
    for token in tokens:
        if token not in text:
            fail(f"{label} missing token {token!r} in {path}")


def ensure_required_files() -> None:
    for path in REQUIRED_FILES:
        if not (ROOT / path).exists():
            fail(f"missing required file: {path}")


def ensure_source_contracts() -> None:
    require_tokens("Shared/Models/MotionSample.swift", MODEL_TOKENS, "MotionSample raw stream schema")
    require_tokens("iOS/Core/SensorEngine/SensorFusionEngine.swift", FUSION_TOKENS, "SensorFusion raw stream persistence")
    require_tokens("iOS/Core/SessionRecording/SessionRecordingCoordinator.swift", COORDINATOR_TOKENS, "summary trusted raw distance")
    require_tokens("iOS/Core/SessionRecording/SessionRecordingCoordinator+DebugMock.swift", DEBUG_TOKENS, "DEBUG route sample source")
    require_tokens("iOS/Core/Export/SkateTrackPackageExportProvider.swift", PACKAGE_TOKENS, "package raw stream capability")
    require_tokens("iOS/Features/SessionSummary/SessionRouteMapView.swift", MAP_TOKENS, "route annotation localization")


def ensure_no_scope_creep() -> None:
    for path in REQUIRED_FILES:
        if not path.endswith(".swift"):
            continue
        text = read(path)
        for token in FORBIDDEN_SOURCE_TOKENS:
            if token in text:
                fail(f"unexpected scope token {token!r} in {path}")


def ensure_docs() -> None:
    docs = "\n".join(
        read(path)
        for path in [
            "docs/history/DEV_LOG.md",
            "docs/reference/FILE_STRUCTURE.md",
            "docs/adr/ADR-INDEX.md",
            "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
        ]
    )
    for token in DOC_TOKENS:
        if token not in docs:
            fail(f"docs missing token {token!r}")


def main() -> int:
    ensure_required_files()
    ensure_source_contracts()
    ensure_no_scope_creep()
    ensure_docs()
    print("Task-030c-b4 raw CLLocation stream persistence check passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
