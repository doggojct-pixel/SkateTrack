#!/usr/bin/env python3
"""Verify Task-030c-b15-B-3 Summary elevation-gain source guard remains display-only."""
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
        ("Shared/Models/SessionData.swift", 'static let currentDebugBuildTaskID = "Task-030c-b19"'),
        ("iOS/Features/Debug/DebugToolsPanelView.swift", 'Text("debug.build.currentTaskID")'),
        ("iOS/Hooks/useSessionSummary.swift", "Task-030c-b15-B-3: Summary climb must use the same trusted altitude-source"),
        ("iOS/Hooks/useSessionSummary.swift", "elevationGainMeters: elevationGainMeters ?? persisted.elevationGainMeters"),
        ("iOS/Hooks/useSessionSummary.swift", "displayDiagnosticElevationGainMeters"),
        ("iOS/Hooks/useSessionSummary.swift", "hasTrustedBarometer"),
        ("iOS/Hooks/useSessionSummary.swift", "? [.barometerRelative]"),
        ("iOS/Hooks/useSessionSummary.swift", "displayLegacySourceElevationGainMeters"),
        ("iOS/Hooks/useSessionSummary.swift", "sample.locationDiagnostics?.verticalAccuracyMeters"),
        ("Tests/iOSTests/SessionRepositoryTests.swift", "testB14B1DisplayElevationGainPrefersTrustedBarometerOverCoreLocationJitter"),
        ("Tests/iOSTests/SessionRepositoryTests.swift", "testB14B1DisplayElevationGainCanReturnZeroInsteadOfPersistedInflatedFallback"),
        ("scripts/verify_task030c_b14b1_summary_elevation_gain_source_guard.py", "Task-030c-b15-B-3 Summary elevation-gain source guard"),
        ("docs/adr/ADR-INDEX.md", "Task-030c-b15-B-3 — Summary Elevation Gain Source Guard"),
        ("docs/history/DEV_LOG.md", "Task-030c-b15-B-3 — Summary Elevation Gain Source Guard"),
        ("docs/release/KNOWN_LIMITATIONS_PRE_ADP.md", "Task-030c-b15-B-3 — Summary Elevation Gain Source Guard"),
        ("docs/reference/FILE_STRUCTURE.md", "Task-030c-b15-B-3 summary elevation gain source guard"),
    ]
    for path, token in checks:
        require(path, token)

    # The Summary display layer may calculate trusted display metrics, but this
    # hotfix must not activate production route reconstruction or mutate stored samples.
    require("iOS/Core/SensorEngine/SensorFusionEngine.swift", "estimatedRouteActive: false")
    require("iOS/Features/SessionSummary/SessionRouteMapView.swift", "solid fluorescent-pink context with full route-line weight")
    require("iOS/Features/SessionSummary/SessionAdvancedChartsView.swift", "altitudeMicroDipDisplayGuardedPoints")
    require("Shared/Models/MotionSample.swift", "DeadReckoningCandidateInterpolationAnalyzer")
    forbid("iOS/Hooks/useSessionSummary.swift", "elevationGainMeters > 0 ? elevationGainMeters : persisted.elevationGainMeters")

    print("Task-030c-b15-B-3 summary elevation gain source guard checks passed.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"Task-030c-b15-B-3 summary elevation gain source guard check failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
