#!/usr/bin/env python3
"""Verify Task-030c-b17-B replay-only DeadReckoningEngine safety boundaries."""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]


def read(relative_path: str) -> str:
    path = ROOT / relative_path
    if not path.exists():
        raise AssertionError(f"Missing required file: {relative_path}")
    return path.read_text()


def require(relative_path: str, token: str) -> None:
    text = read(relative_path)
    if token not in text:
        raise AssertionError(f"Missing token in {relative_path}: {token}")


def forbid(relative_path: str, token: str) -> None:
    text = read(relative_path)
    if token in text:
        raise AssertionError(f"Forbidden token in {relative_path}: {token}")


def require_first_line_marker(relative_path: str, marker: str) -> None:
    first_line = read(relative_path).splitlines()[0]
    if not first_line.startswith(marker):
        raise AssertionError(f"{relative_path} must start with {marker}")


def require_line_count_at_most(relative_path: str, limit: int) -> None:
    count = len(read(relative_path).splitlines())
    if count > limit:
        raise AssertionError(f"{relative_path} has {count} lines; limit is {limit}")


def main() -> None:
    required_tokens = {
        "Shared/Models/DeadReckoningReplayDiagnostics.swift": [
            "enum DeadReckoningEstimateSource",
            "enum DeadReckoningConfidence",
            "struct DeadReckoningReplayEstimate",
            "struct DeadReckoningReplayDiagnostics",
            "productionRouteMutationApplied = false",
            "trustedMetricsMutationApplied = false",
        ],
        "iOS/Core/SensorEngine/DeadReckoningEngine.swift": [
            "enum DeadReckoningEngine",
            "private static let estimatedPositionDriftRateMetersPerSecond: Double = 0.5",
            "LocalTangentPlane",
            "IMUBiasEstimator.estimateAccelerometerBias",
            "GravityCompensatedMotionSample",
            "DeadReckoningReplayEstimate",
            "DeadReckoningReplayDiagnostics",
            "maximumReplayGapSeconds",
        ],
        "Tests/iOSTests/DeadReckoningEngineReplayTests.swift": [
            "testStraightLineSyntheticAccelerationProducesPlausibleDisplacement",
            "testConstantHeadingAndKnownVelocityApproximateExpectedRoute",
            "testMissingHeadingDowngradesConfidence",
            "testGapLongerThanPolicyLimitIsBlocked",
            "testAnchorClosureErrorIsRecorded",
            "testDriftRateProducesNamedAccuracyGrowth",
        ],
        "Shared/Models/SessionData.swift": [
            'static let currentDebugBuildTaskID = "Task-030c-b18-B"',
        ],
        "Shared/Localization/en.lproj/Localizable.strings": [
            '"debug.build.currentTaskID" = "Task-030c-b18-B";',
        ],
        "Shared/Localization/zh-Hant.lproj/Localizable.strings": [
            '"debug.build.currentTaskID" = "Task-030c-b18-B";',
        ],
        "Shared/Localization/ja.lproj/Localizable.strings": [
            '"debug.build.currentTaskID" = "Task-030c-b18-B";',
        ],
        "SkateTrack.xcodeproj/project.pbxproj": [
            "DeadReckoningReplayDiagnostics.swift in Sources",
            "DeadReckoningEngine.swift in Sources",
            "DeadReckoningEngineReplayTests.swift in Sources",
        ],
        "docs/adr/ADR-INDEX.md": [
            "Task-030c-b17-B — Replay-Only Dead Reckoning Engine v1",
            "estimatedPositionDriftRateMetersPerSecond",
            "No production route geometry",
        ],
        "docs/history/DEV_LOG.md": [
            "Task-030c-b17-B — Replay-Only Dead Reckoning Engine v1",
            "DeadReckoningReplayEstimate",
            "anchor closure error",
        ],
        "docs/reference/FILE_STRUCTURE.md": [
            "Task-030c-b17-B replay-only dead reckoning engine",
            "DeadReckoningReplayDiagnostics.swift",
            "DeadReckoningEngine.swift",
            "DeadReckoningEngineReplayTests.swift",
        ],
        "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
            "Task-030c-b17-B — Replay-Only Dead Reckoning Engine v1",
            "replay-only",
            "trusted metrics",
        ],
        "docs/planning/Task-030c-b16_Localization_Foundation_Plan.md": [
            "Task-030c-b17-B Implementation Note",
            "Replay-Only Dead Reckoning Engine v1",
            "Task-030c_Post-b15_Localization_Completion_Plan_EN_v1.2",
        ],
    }

    for relative_path, tokens in required_tokens.items():
        for token in tokens:
            require(relative_path, token)

    for relative_path in [
        "Shared/Models/DeadReckoningReplayDiagnostics.swift",
        "iOS/Core/SensorEngine/DeadReckoningEngine.swift",
        "Tests/iOSTests/DeadReckoningEngineReplayTests.swift",
    ]:
        require_first_line_marker(relative_path, "// [協作區]" if relative_path.startswith("Shared/") else "// [自主區]")
        require_line_count_at_most(relative_path, 500)

    for relative_path in [
        "Shared/Models/MotionSample.swift",
        "Shared/Models/SessionData.swift",
        "iOS/Core/SensorEngine/SensorFusionEngine.swift",
    ]:
        text = read(relative_path)
        if "estimatedRouteActive: true" in text:
            raise AssertionError(f"{relative_path} must not activate estimatedRouteActive")

    for relative_path in [
        "Shared/Models/DeadReckoningReplayDiagnostics.swift",
        "iOS/Core/SensorEngine/DeadReckoningEngine.swift",
    ]:
        text = read(relative_path)
        forbidden = [
            "summaryMetrics =",
            "trustedDistanceOverride",
            "rewriteRouteGeometry",
            "roadSnapping",
            "mapMatching",
            "CLLocationManager",
        ]
        for token in forbidden:
            if token in text:
                raise AssertionError(f"Forbidden production mutation token in {relative_path}: {token}")

    panel_text = read("iOS/Features/Debug/DebugToolsPanelView.swift")
    if 'Text("Task-030c-b17-D")' in panel_text or 'Text("DEBUG")' in panel_text:
        raise AssertionError("Debug panel visible task/badge strings must stay localized")

    engine_text = read("iOS/Core/SensorEngine/DeadReckoningEngine.swift")
    if re.search(r"estimatedPositionDriftRateMetersPerSecond\s*\*\s*0\.5", engine_text):
        raise AssertionError("Drift rate must be the named constant, not an inline literal")

    print("Task-030c-b17-B replay-only dead reckoning engine checks passed.")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"Task-030c-b17-B check failed: {exc}", file=sys.stderr)
        sys.exit(1)
