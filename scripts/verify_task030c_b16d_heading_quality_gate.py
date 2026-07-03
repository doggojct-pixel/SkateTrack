#!/usr/bin/env python3
"""Verify Task-030c-b16-D heading quality consolidation safety boundaries."""
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
        "Shared/Models/HeadingQualityDiagnostics.swift": [
            "HeadingReliability",
            "case high",
            "case moderate",
            "case poor",
            "case invalid",
            "case tooOld",
            "case unavailable",
            "HeadingQualityConfig",
            "HeadingQualityAssessment",
            "replayReadinessEligible",
        ],
        "iOS/Core/SensorEngine/HeadingQualityClassifier.swift": [
            "HeadingQualityClassifier",
            "HeadingDiagnostics",
            "HeadingQualityAssessment",
            "maxReplayReadinessAgeSeconds",
            "courseDeviceHeadingAgreement != false",
            "diagnostics.hasReliableHeadingForRouteContinuity",
        ],
        "Tests/iOSTests/HeadingQualityClassifierTests.swift": [
            "testHighAccuracyDeviceHeadingIsReplayReady",
            "testModerateCourseHeadingCanRemainReplayReady",
            "testOldDeviceHeadingIsNotReplayReady",
            "testInvalidAccuracyIsNotReplayReady",
            "testUnavailableHeadingRemainsDiagnosticsOnly",
            "testHeadingQualityAssessmentCodableRoundTrip",
        ],
        "SkateTrack.xcodeproj/project.pbxproj": [
            "HeadingQualityDiagnostics.swift in Sources",
            "HeadingQualityClassifier.swift in Sources",
            "HeadingQualityClassifierTests.swift in Sources",
        ],
        "Shared/Models/SessionData.swift": [
            'static let currentDebugBuildTaskID = "Task-030c-b19"',
        ],
        "iOS/Features/Debug/DebugToolsPanelView.swift": [
            'Text("debug.build.currentTaskID")',
        ],
        "iOS/Core/SensorEngine/SensorFusionEngine.swift": [
            "estimatedRouteActive: false",
        ],
        "docs/adr/ADR-INDEX.md": [
            "Task-030c-b16-D — Magnetometer Heading Quality Consolidation",
            "HeadingReliability",
            "replay-readiness only",
            "estimatedRouteActive remains false",
        ],
        "docs/history/DEV_LOG.md": [
            "Task-030c-b16-D — Magnetometer Heading Quality Consolidation",
            "HeadingQualityClassifier",
            "no production estimated route geometry",
            "estimatedRouteActive remains false",
        ],
        "docs/reference/FILE_STRUCTURE.md": [
            "Task-030c-b16-D heading quality consolidation",
            "HeadingQualityDiagnostics.swift",
            "HeadingQualityClassifier.swift",
            "HeadingQualityClassifierTests.swift",
        ],
        "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
            "Task-030c-b16-D — Magnetometer Heading Quality Consolidation",
            "replay-readiness only",
            "no production estimated route geometry",
            "estimatedRouteActive remains false",
        ],
        "docs/planning/Task-030c-b16_Localization_Foundation_Plan.md": [
            "Task-030c-b16-D Implementation Note",
            "HeadingReliability",
            "HeadingQualityAssessment",
            "estimatedRouteActive remains false",
        ],
    }

    for rel, tokens in required_tokens.items():
        for token in tokens:
            require(rel, token)

    require_first_line_marker("Shared/Models/HeadingQualityDiagnostics.swift", "// [協作區]")
    require_first_line_marker("iOS/Core/SensorEngine/HeadingQualityClassifier.swift", "// [自主區]")
    require_first_line_marker("Tests/iOSTests/HeadingQualityClassifierTests.swift", "// [自主區]")

    for rel in [
        "Shared/Models/HeadingQualityDiagnostics.swift",
        "iOS/Core/SensorEngine/HeadingQualityClassifier.swift",
        "Tests/iOSTests/HeadingQualityClassifierTests.swift",
        "scripts/verify_task030c_b16d_heading_quality_gate.py",
    ]:
        count = line_count(rel)
        if count > 500:
            raise AssertionError(f"{rel} exceeds 500 lines: {count}")

    forbidden_tokens = [
        "estimatedRouteActive: true",
        "productionRouteDecisionApplied: true",
        "emitDeadReckonedSample",
        "roadSnapping",
        "mapMatching",
        "rewriteRouteGeometry",
        "trustedDistanceOverride",
        "confirmedHeadingRoute",
    ]
    for rel in [
        "Shared/Models/HeadingQualityDiagnostics.swift",
        "iOS/Core/SensorEngine/HeadingQualityClassifier.swift",
        "iOS/Core/SensorEngine/SensorFusionEngine.swift",
        "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift",
        "Shared/Models/MotionSample.swift",
    ]:
        for token in forbidden_tokens:
            forbid(rel, token)

    classifier_text = read("iOS/Core/SensorEngine/HeadingQualityClassifier.swift")
    if re.search(r"estimatedRouteActive\s*=\s*true", classifier_text):
        raise AssertionError("HeadingQualityClassifier must not activate estimated routes")

    print("Task-030c-b16-D heading quality consolidation checks passed.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"Task-030c-b16-D check failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
