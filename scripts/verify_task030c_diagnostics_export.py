#!/usr/bin/env python3
"""Verify Task-030c-b10-r5 diagnostics export identity and package capability guard."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "Shared/Models/SessionData.swift",
    "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift",
    "iOS/Core/Export/SkateTrackPackageExportProvider.swift",
    "iOS/Features/Debug/DebugToolsPanelView.swift",
    "scripts/verify_task030c_diagnostics_export.py",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/adr/ADR-INDEX.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
]

REQUIRED_TOKENS = {
    "Shared/Models/SessionData.swift": [
        "static let currentDebugBuildTaskID = \"Task-030c-b10-r5\"",
        "let diagnosticsStatus: String?",
        "diagnosticsStatus: String? = nil",
    ],
    "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift": [
        "RecordingDebugDiagnosticsCollector.shared.finishSession",
        "enabledButNoEventsRecorded",
        "disabledByBuildConfiguration",
        "makeDiagnosticsDisabledByBuildConfiguration",
        "RecordingDebugBuildIdentity(",
        "filterDecisionSummary: RecordingDebugFilterDecisionSummary()",
        "altitudeDiagnostics: RecordingDebugAltitudeDiagnostics()",
    ],
    "iOS/Core/Export/SkateTrackPackageExportProvider.swift": [
        "debug-build-identity-v1",
        "debug-recording-diagnostics-v1",
        "background-gap-diagnostics-v1",
        "diagnostics-export-status-v1",
        "if session.debugRecordingDiagnostics != nil",
    ],
    "iOS/Features/Debug/DebugToolsPanelView.swift": [
        "Task-030c-b10-r5",
        "debug-build-signature-card",
    ],
    "docs/history/DEV_LOG.md": [
        "Task-030c-b10-r5",
        "Ensure Background Diagnostics Export",
        "debug-build-identity-v1",
        "diagnostics-export-status-v1",
    ],
    "docs/reference/FILE_STRUCTURE.md": [
        "Task-030c-b10-r5",
        "diagnostics export",
    ],
    "docs/adr/ADR-INDEX.md": [
        "Task-030c-b10-r5",
        "diagnostics export",
    ],
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
        "Task-030c-b10-r5",
        "diagnostics export",
    ],
}

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
    print(f"Task-030c-b10-r5 diagnostics export check failed: {message}", file=sys.stderr)
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
    combined = "\n".join(
        read(path)
        for path in [
            "Shared/Models/SessionData.swift",
            "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift",
            "iOS/Core/Export/SkateTrackPackageExportProvider.swift",
            "iOS/Features/Debug/DebugToolsPanelView.swift",
        ]
    )
    for token in FORBIDDEN_TOKENS:
        if token in combined:
            fail(f"unexpected production integration token found: {token}")
    print("Task-030c-b10-r5 diagnostics export checks passed.")


if __name__ == "__main__":
    main()
