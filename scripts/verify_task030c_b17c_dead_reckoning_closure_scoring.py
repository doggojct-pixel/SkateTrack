#!/usr/bin/env python3
"""Verify Task-030c-b17-C anchor closure error and confidence scoring safety boundaries."""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]


def read(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


def require(relative_path: str, token: str) -> None:
    text = read(relative_path)
    if token not in text:
        raise AssertionError(f"Missing token in {relative_path}: {token}")


def require_absent(relative_path: str, token: str) -> None:
    text = read(relative_path)
    if token in text:
        raise AssertionError(f"Forbidden token in {relative_path}: {token}")


def require_first_line_marker(relative_path: str, marker: str) -> None:
    first_line = read(relative_path).splitlines()[0]
    if first_line != marker:
        raise AssertionError(f"{relative_path} first line must be {marker!r}, got {first_line!r}")


def require_swift_file_under_limit(relative_path: str, limit: int = 500) -> None:
    line_count = len(read(relative_path).splitlines())
    if line_count > limit:
        raise AssertionError(f"{relative_path} has {line_count} lines, limit is {limit}")


def main() -> int:
    required_tokens = {
        "Shared/Models/DeadReckoningClosureDiagnostics.swift": [
            "struct DeadReckoningClosureDiagnostics",
            "let gapDurationSeconds: TimeInterval",
            "let estimatedDistanceMeters: Double",
            "let closureErrorMeters: Double",
            "let closureErrorRatio: Double",
            "let headingReliability: HeadingReliability",
            "let imuSampleCoverageRatio: Double",
            "let eligibleForUserVisibleEstimatedRoute: Bool",
            "let blockingReasons: [String]",
        ],
        "Shared/Models/DeadReckoningReplayDiagnostics.swift": [
            "let closureDiagnostics: DeadReckoningClosureDiagnostics?",
            "closureDiagnostics: DeadReckoningClosureDiagnostics? = nil",
        ],
        "iOS/Core/SensorEngine/DeadReckoningClosureScorer.swift": [
            "struct DeadReckoningClosureScoringPolicy",
            "enum DeadReckoningClosureScorer",
            "shortGapEligibilitySeconds: TimeInterval = 30",
            "maximumOutdoorUserVisibleGapSeconds: TimeInterval = 60",
            "possibleClosureErrorAbsoluteMeters: Double = 8",
            "possibleClosureErrorDistanceRatio: Double = 0.25",
            "blockingClosureErrorAbsoluteMeters: Double = 15",
            "blockingClosureErrorDistanceRatio: Double = 0.5",
            "minimumIMUSampleCoverageRatio: Double = 0.7",
            "gapDurationExceededOutdoorLimit",
            "closureErrorExceededBlockingThreshold",
            "headingReliabilityInsufficient",
            "imuSampleCoverageInsufficient",
        ],
        "iOS/Core/SensorEngine/DeadReckoningEngine.swift": [
            "DeadReckoningClosureScorer.score(",
            "closureDiagnostics: closureDiagnostics",
            "imuSampleCoverageRatio(",
            "pathDistanceMeters(for: estimates)",
        ],
        "Tests/iOSTests/DeadReckoningClosureScoringTests.swift": [
            "testLowClosureErrorIsEligibleReplayCandidate",
            "testHighClosureErrorIsBlocked",
            "testMissingHeadingIsBlocked",
            "testLowIMUCoverageIsBlocked",
            "testVeryLongGapIsBlocked",
            "testReplayDiagnosticsReceivesClosureDiagnostics",
        ],
        "Shared/Models/SessionData.swift": [
            'static let currentDebugBuildTaskID = "Task-030c-b18-A"',
        ],
        "Shared/Localization/en.lproj/Localizable.strings": [
            '"debug.build.currentTaskID" = "Task-030c-b18-A";',
        ],
        "Shared/Localization/ja.lproj/Localizable.strings": [
            '"debug.build.currentTaskID" = "Task-030c-b18-A";',
        ],
        "Shared/Localization/zh-Hant.lproj/Localizable.strings": [
            '"debug.build.currentTaskID" = "Task-030c-b18-A";',
        ],
        "SkateTrack.xcodeproj/project.pbxproj": [
            "DeadReckoningClosureDiagnostics.swift in Sources",
            "DeadReckoningClosureScorer.swift in Sources",
            "DeadReckoningClosureScoringTests.swift in Sources",
        ],
        "docs/adr/ADR-INDEX.md": [
            "Task-030c-b17-C — Anchor Closure Error and Confidence Scoring",
            "DeadReckoningClosureDiagnostics",
            "No user-visible route display is enabled",
        ],
        "docs/history/DEV_LOG.md": [
            "Task-030c-b17-C — Anchor Closure Error and Confidence Scoring",
            "DeadReckoningClosureScorer",
            "Task-030c-b17-C verification token",
        ],
        "docs/reference/FILE_STRUCTURE.md": [
            "Task-030c-b17-C anchor closure error and confidence scoring",
            "DeadReckoningClosureDiagnostics.swift",
            "DeadReckoningClosureScorer.swift",
            "DeadReckoningClosureScoringTests.swift",
        ],
        "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
            "Task-030c-b17-C — Anchor Closure Error and Confidence Scoring",
            "No user-visible estimated route is enabled by this milestone",
        ],
        "docs/planning/Task-030c-b16_Localization_Foundation_Plan.md": [
            "Task-030c-b17-C Implementation Note",
            "Task-030c_Post-b15_Localization_Completion_Plan_EN_v1.2",
        ],
    }

    for relative_path, tokens in required_tokens.items():
        for token in tokens:
            require(relative_path, token)

    require_first_line_marker("Shared/Models/DeadReckoningClosureDiagnostics.swift", "// [協作區] Shared/Models/DeadReckoningClosureDiagnostics.swift")
    require_first_line_marker("iOS/Core/SensorEngine/DeadReckoningClosureScorer.swift", "// [自主區] iOS/Core/SensorEngine/DeadReckoningClosureScorer.swift")
    require_first_line_marker("Tests/iOSTests/DeadReckoningClosureScoringTests.swift", "// [自主區] Tests/iOSTests/DeadReckoningClosureScoringTests.swift")

    for relative_path in [
        "Shared/Models/DeadReckoningClosureDiagnostics.swift",
        "iOS/Core/SensorEngine/DeadReckoningClosureScorer.swift",
        "Tests/iOSTests/DeadReckoningClosureScoringTests.swift",
    ]:
        require_swift_file_under_limit(relative_path)

    for relative_path in [
        "Shared/Models/DeadReckoningClosureDiagnostics.swift",
        "Shared/Models/DeadReckoningReplayDiagnostics.swift",
        "iOS/Core/SensorEngine/DeadReckoningClosureScorer.swift",
        "iOS/Core/SensorEngine/DeadReckoningEngine.swift",
    ]:
        text = read(relative_path)
        if "estimatedRouteActive: true" in text:
            raise AssertionError(f"{relative_path} must not enable estimatedRouteActive")
        if "SessionData.summaryMetrics" in text or "summaryMetrics =" in text:
            raise AssertionError(f"{relative_path} must not mutate summary metrics")
        for token in ["CLLocationManager", "routeMap", "mapMatching", "roadSnapping", "trustedDistanceOverride"]:
            if token in text:
                raise AssertionError(f"{relative_path} contains forbidden production/display token: {token}")

    panel_text = read("iOS/Features/Debug/DebugToolsPanelView.swift")
    if 'Text("Task-030c-b17-D")' in panel_text or 'Text("DEBUG")' in panel_text:
        raise AssertionError("Debug visible build strings must stay localized, not hard-coded Text literals")

    sensor_fusion_text = read("iOS/Core/SensorEngine/SensorFusionEngine.swift")
    if "estimatedRouteActive: false" not in sensor_fusion_text:
        raise AssertionError("SensorFusionEngine must keep estimatedRouteActive false")
    if "estimatedRouteActive: true" in sensor_fusion_text:
        raise AssertionError("SensorFusionEngine must not enable estimatedRouteActive true")

    scorer_text = read("iOS/Core/SensorEngine/DeadReckoningClosureScorer.swift")
    if re.search(r"possibleClosureErrorAbsoluteMeters\s*:\s*Double\s*=\s*8", scorer_text) is None:
        raise AssertionError("b17-C must keep the named 8m possible closure threshold")
    if re.search(r"blockingClosureErrorDistanceRatio\s*:\s*Double\s*=\s*0\.5", scorer_text) is None:
        raise AssertionError("b17-C must keep the named 0.5 blocking closure ratio threshold")

    print("Task-030c-b17-C dead reckoning closure scoring checks passed.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"Task-030c-b17-C check failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
