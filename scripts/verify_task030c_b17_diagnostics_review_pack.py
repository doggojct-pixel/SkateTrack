#!/usr/bin/env python3
"""Verify Task-030c-b17-0 localization diagnostics review pack foundation safety boundaries."""
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
        "Shared/Models/LocalizationDiagnosticsReviewPack.swift": [
            "LocalizationDiagnosticsReviewPack",
            "LocalizationDiagnosticsReviewSummary",
            "LocalizationDiagnosticsReviewSample",
            "diagnosticsOnly",
            "replayReviewOnly",
            "productionRouteMutationApplied",
            "self.productionRouteMutationApplied = false",
        ],
        "iOS/Core/SensorEngine/LocalizationDiagnosticsReviewBuilder.swift": [
            "LocalizationDiagnosticsReviewBuilder",
            "makeReviewPack(",
            "HeadingQualityClassifier.classify(",
            "barometricGPSOutlierDecision?.wouldRejectIfGateWereEnabled",
            "locationAccuracySourceDiagnostics?.sourceClass",
        ],
        "Tests/iOSTests/LocalizationDiagnosticsReviewPackTests.swift": [
            "testReviewPackSummarizesB16DiagnosticsWithoutProductionMutation",
            "testReviewPackStaysNominalForEmptyDiagnostics",
            "testReviewPackForcesSerializedSafetyFlags",
            "XCTAssertFalse(pack.productionRouteMutationApplied)",
        ],
        "SkateTrack.xcodeproj/project.pbxproj": [
            "LocalizationDiagnosticsReviewPack.swift in Sources",
            "LocalizationDiagnosticsReviewBuilder.swift in Sources",
            "LocalizationDiagnosticsReviewPackTests.swift in Sources",
        ],
        "Shared/Models/SessionData.swift": [
            'static let currentDebugBuildTaskID = "Task-030c-b17-B"',
        ],
        "iOS/Features/Debug/DebugToolsPanelView.swift": [
            'Text("debug.build.currentTaskID")',
            'Text("debug.build.badge")',
        ],
        "Shared/Localization/en.lproj/Localizable.strings": [
            '"debug.build.currentTaskID" = "Task-030c-b17-B";',
            '"debug.build.badge" = "DEBUG";',
        ],
        "Shared/Localization/zh-Hant.lproj/Localizable.strings": [
            '"debug.build.currentTaskID" = "Task-030c-b17-B";',
            '"debug.build.badge" = "DEBUG";',
        ],
        "Shared/Localization/ja.lproj/Localizable.strings": [
            '"debug.build.currentTaskID" = "Task-030c-b17-B";',
            '"debug.build.badge" = "DEBUG";',
        ],
        "iOS/Core/SensorEngine/SensorFusionEngine.swift": [
            "estimatedRouteActive: false",
        ],
        "docs/adr/ADR-INDEX.md": [
            "Task-030c-b17-0 — Localization Diagnostics Review Pack Foundation",
            "diagnostics-only and replay-review-only",
            "estimatedRouteActive remains false",
        ],
        "docs/history/DEV_LOG.md": [
            "Task-030c-b17-0 — Localization Diagnostics Review Pack Foundation",
            "localized DEBUG build signature",
            "estimatedRouteActive remains false",
        ],
        "docs/reference/FILE_STRUCTURE.md": [
            "Task-030c-b17-0 localization diagnostics review pack foundation",
            "LocalizationDiagnosticsReviewPack.swift",
            "LocalizationDiagnosticsReviewBuilder.swift",
            "LocalizationDiagnosticsReviewPackTests.swift",
        ],
        "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
            "Task-030c-b17-0 — Localization Diagnostics Review Pack Foundation",
            "Production boundary",
            "estimatedRouteActive remains false",
        ],
        "docs/planning/Task-030c-b16_Localization_Foundation_Plan.md": [
            "Task-030c-b17-0 Implementation Note",
            "LocalizationDiagnosticsReviewPack",
            "localized through `debug.build.currentTaskID`",
        ],
    }

    for rel, tokens in required_tokens.items():
        for token in tokens:
            require(rel, token)

    require_first_line_marker("Shared/Models/LocalizationDiagnosticsReviewPack.swift", "// [協作區]")
    require_first_line_marker("iOS/Core/SensorEngine/LocalizationDiagnosticsReviewBuilder.swift", "// [自主區]")
    require_first_line_marker("Tests/iOSTests/LocalizationDiagnosticsReviewPackTests.swift", "// [自主區]")

    for rel in [
        "Shared/Models/LocalizationDiagnosticsReviewPack.swift",
        "iOS/Core/SensorEngine/LocalizationDiagnosticsReviewBuilder.swift",
        "Tests/iOSTests/LocalizationDiagnosticsReviewPackTests.swift",
        "scripts/verify_task030c_b17_diagnostics_review_pack.py",
    ]:
        count = line_count(rel)
        if count > 500:
            raise AssertionError(f"{rel} exceeds 500 lines: {count}")

    forbidden_tokens = [
        "estimatedRouteActive: true",
        "productionRouteDecisionApplied: true",
        "productionRouteMutationApplied = true",
        "emitDeadReckonedSample",
        "roadSnapping",
        "mapMatching",
        "rewriteRouteGeometry",
        "trustedDistanceOverride",
        "CNCopyCurrentNetworkInfo",
        "NEHotspot",
        "CoreWLAN",
        "NetworkExtension",
        "CaptiveNetwork",
        "com.apple.developer.networking.wifi-info",
    ]
    for rel in [
        "Shared/Models/LocalizationDiagnosticsReviewPack.swift",
        "iOS/Core/SensorEngine/LocalizationDiagnosticsReviewBuilder.swift",
        "iOS/Core/SensorEngine/SensorFusionEngine.swift",
        "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift",
        "Shared/Models/MotionSample.swift",
        "SkateTrack.xcodeproj/project.pbxproj",
    ]:
        for token in forbidden_tokens:
            forbid(rel, token)

    panel_text = read("iOS/Features/Debug/DebugToolsPanelView.swift")
    if 'Text("Task-030c-b17-0")' in panel_text:
        raise AssertionError("DebugToolsPanelView must use Localizable.strings key for the visible task ID")
    if 'Text("DEBUG")' in panel_text:
        raise AssertionError("DebugToolsPanelView must use Localizable.strings key for the visible DEBUG badge")

    model_text = read("Shared/Models/LocalizationDiagnosticsReviewPack.swift")
    if re.search(r"let\s+productionRouteMutationApplied\s*=\s*true", model_text):
        raise AssertionError("LocalizationDiagnosticsReviewPack must not allow productionRouteMutationApplied true")

    print("Task-030c-b17-0 localization diagnostics review pack foundation checks passed.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"Task-030c-b17-0 check failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
