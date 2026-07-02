#!/usr/bin/env python3
"""Verify Task-030c-b15-B-3 total elevation gain terminology stays localization-only."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def require(path: str, token: str) -> None:
    text = read(path)
    if token not in text:
        raise AssertionError(f"Missing token in {path}: {token}")


def forbid(path: str, token: str) -> None:
    text = read(path)
    if token in text:
        raise AssertionError(f"Forbidden token in {path}: {token}")


def main() -> int:
    checks = [
        ("Shared/Models/SessionData.swift", 'static let currentDebugBuildTaskID = "Task-030c-b16-B"'),
        ("iOS/Features/Debug/DebugToolsPanelView.swift", 'Text("Task-030c-b16-B")'),
        ("Shared/Localization/zh-Hant.lproj/Localizable.strings", '"summary.metric.elevationGain" = "總爬升量";'),
        ("Shared/Localization/en.lproj/Localizable.strings", '"summary.metric.elevationGain" = "Total elevation gain";'),
        ("Shared/Localization/ja.lproj/Localizable.strings", '"summary.metric.elevationGain" = "総獲得標高";'),
        ("iOS/Features/SessionSummary/SessionSummaryView.swift", 'labelKey: "summary.metric.elevationGain"'),
        ("iOS/Hooks/useSessionShareCard.swift", 'labelLocalizationKey: "summary.metric.elevationGain"'),
        ("iOS/Core/SessionSharing/SessionShareExportService.swift", 'localized("summary.metric.elevationGain")'),
        ("scripts/verify_session_summary.py", '"summary.metric.elevationGain"'),
        ("docs/adr/ADR-INDEX.md", "Task-030c-b15-B-3 — Total Elevation Gain Terminology"),
        ("docs/history/DEV_LOG.md", "Task-030c-b15-B-3 — Total Elevation Gain Terminology"),
        ("docs/release/KNOWN_LIMITATIONS_PRE_ADP.md", "Task-030c-b15-B-3 — Total Elevation Gain Terminology"),
        ("docs/reference/FILE_STRUCTURE.md", "Task-030c-b15-B-3 total elevation gain terminology"),
    ]
    for path, token in checks:
        require(path, token)

    # This task renames user-facing terminology only. It must preserve the
    # b14-B-1 trusted altitude-source climb calculation and replay-only route guardrails.
    require("iOS/Hooks/useSessionSummary.swift", "displayDiagnosticElevationGainMeters")
    require("iOS/Hooks/useSessionSummary.swift", "elevationGainMeters: elevationGainMeters ?? persisted.elevationGainMeters")
    require("Shared/Models/MotionSample.swift", "DeadReckoningCandidateInterpolationAnalyzer")
    require("iOS/Core/SensorEngine/SensorFusionEngine.swift", "estimatedRouteActive: false")

    forbid("Shared/Localization/zh-Hant.lproj/Localizable.strings", '"summary.metric.elevationGain" = "爬升";')
    forbid("Shared/Localization/en.lproj/Localizable.strings", '"summary.metric.elevationGain" = "Elevation gain";')
    forbid("Shared/Localization/ja.lproj/Localizable.strings", '"summary.metric.elevationGain" = "獲得標高";')

    print("Task-030c-b15-B-3 total elevation gain terminology checks passed.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"Task-030c-b15-B-3 total elevation gain terminology check failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
