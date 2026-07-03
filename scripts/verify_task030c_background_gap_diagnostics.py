#!/usr/bin/env python3
"""Verify Task-030c-b7 DEBUG-only background recording gap diagnostics."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "Shared/Models/SessionData.swift",
    "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift",
    "iOS/Core/SensorEngine/GPSProvider.swift",
    "iOS/Core/Export/SkateTrackPackageExportProvider.swift",
    "iOS/Hooks/useSessionRecording.swift",
    "iOS/Features/Debug/DebugFeatureFlag.swift",
    "iOS/Features/Debug/DebugToolsPanelView.swift",
    "Shared/Localization/en.lproj/Localizable.strings",
    "Shared/Localization/zh-Hant.lproj/Localizable.strings",
    "Shared/Localization/ja.lproj/Localizable.strings",
    "scripts/verify_task030c_background_gap_diagnostics.py",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/adr/ADR-INDEX.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
]

MODEL_TOKENS = [
    "struct RecordingDebugDiagnostics",
    "struct RecordingDebugBuildIdentity",
    "struct RecordingDebugRuntimeSnapshot",
    "struct RecordingDebugLifecycleEvent",
    "struct RecordingDebugHeartbeat",
    "struct RecordingDebugLocationManagerSnapshot",
    "struct RecordingDebugAuthorizationSnapshot",
    "struct RecordingDebugLocationCallbackEvent",
    "struct RecordingDebugGapEvent",
    "struct RecordingDebugFilterDecisionSummary",
    "struct RecordingDebugAltitudeDiagnostics",
    "enum DebugRecordingTestContextLabel",
    "let debugRecordingDiagnostics: RecordingDebugDiagnostics?",
    "decodeIfPresent(RecordingDebugDiagnostics.self",
]

COORDINATOR_TOKENS = [
    "RecordingDebugDiagnosticsCollector",
    "beginSession(",
    "recordMotionSample(",
    "appDidEnterBackground",
    "protectedDataWillBecomeUnavailable",
    "protectedDataDidBecomeAvailable",
    "finishSession(endDate:",
    "debugRecordingDiagnostics: debugRecordingDiagnostics",
    "RecordingDebugBuildIdentity.currentDebugBuildTaskID",
    "diagnosticsStatus:",
]

GPS_TOKENS = [
    "recordLocationManagerSnapshot(reason:",
    "recordAuthorizationSnapshot(reason:",
    "recordLocationCallback(eventType:",
    "didUpdateLocations",
    "didPauseLocationUpdates",
    "didResumeLocationUpdates",
    "recordFilterDecision(accepted: false, reason: \"horizontalAccuracyTooPoor\")",
    "startMonitoringSignificantLocationChangesCalled",
]

DEBUG_UI_TOKENS = [
    "recordingDiagnosticsContextSection",
    "debug-recording-context-picker",
    "DebugRecordingTestContextLabel.allCases",
    "debug-build-signature-card",
]

PACKAGE_TOKENS = [
    "debug-recording-diagnostics-v1",
    "background-gap-diagnostics-v1",
    "debug-build-identity-v1",
    "diagnostics-export-status-v1",
]

DOC_TOKENS = [
    "Task-030c-b7",
    "Background Recording Gap Diagnostics",
    "debug-recording-diagnostics-v1",
    "background-gap-diagnostics-v1",
    "DEBUG-only",
    "protected data",
]

FORBIDDEN_TOKENS = [
    "MKDirections",
    "MKRoute",
    "GoogleMaps",
    "GIDSignIn",
    "CloudKit",
    "NSUbiquitousContainers",
    "StoreKit",
    "HealthKit",
]


def fail(message: str) -> None:
    print(f"Task-030c-b7 background gap diagnostics check failed: {message}", file=sys.stderr)
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
    require_tokens("Shared/Models/SessionData.swift", MODEL_TOKENS, "debug diagnostics schema")
    require_tokens("iOS/Core/SessionRecording/SessionRecordingCoordinator.swift", COORDINATOR_TOKENS, "coordinator diagnostics collector")
    require_tokens("iOS/Core/SensorEngine/GPSProvider.swift", GPS_TOKENS, "location manager diagnostics")
    require_tokens("iOS/Core/Export/SkateTrackPackageExportProvider.swift", PACKAGE_TOKENS, "package debug capabilities")
    require_tokens("iOS/Hooks/useSessionRecording.swift", ["debugRecordingTestContext", "setDebugRecordingTestContext"], "debug test context hook")
    require_tokens("iOS/Features/Debug/DebugToolsPanelView.swift", DEBUG_UI_TOKENS, "debug test context UI")


def ensure_localization() -> None:
    for path in [
        "Shared/Localization/en.lproj/Localizable.strings",
        "Shared/Localization/zh-Hant.lproj/Localizable.strings",
        "Shared/Localization/ja.lproj/Localizable.strings",
    ]:
        require_tokens(
            path,
            [
                "debug.tools.recordingContext.title",
                "debug.tools.recordingContext.hint",
                "debug.recordingContext.lockedPocketWalk",
                "debug.recordingContext.windshieldDrive",
            ],
            "recording context localization",
        )


def ensure_no_scope_creep() -> None:
    for path in REQUIRED_FILES:
        if not path.endswith(".swift"):
            continue
        text = read(path)
        for token in FORBIDDEN_TOKENS:
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
    ensure_localization()
    ensure_no_scope_creep()
    ensure_docs()
    print("Task-030c-b7 background recording gap diagnostics check passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
