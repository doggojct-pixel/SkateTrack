#!/usr/bin/env python3
"""Verify Task-030c-b17-D real-session replay review pack safety boundaries."""

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]


def read(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


def require(relative_path: str, token: str) -> None:
    text = read(relative_path)
    if token not in text:
        raise AssertionError(f"Missing token in {relative_path}: {token}")


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
        "Shared/Models/DeadReckoningReplayReviewPack.swift": [
            "struct DeadReckoningReplayReviewPack",
            "struct DeadReckoningReplayReviewSessionSummary",
            "struct DeadReckoningReplayReviewGapRecord",
            "struct DeadReckoningReplayReviewArtifact",
            "Task030c_b17D_ReplayReviewPack.zip",
            "let productDecisionCheckpointRequired: Bool",
            "let b18DisplayWorkBlockedUntilProductDecision: Bool",
            "let estimatedRouteDisplayEnabled: Bool",
            "self.productionRouteMutationApplied = false",
            "self.trustedMetricsMutationApplied = false",
            "self.estimatedRouteDisplayEnabled = false",
        ],
        "iOS/Core/SensorEngine/DeadReckoningReplayReviewPackBuilder.swift": [
            "struct DeadReckoningReplayReviewSessionInput",
            "enum DeadReckoningReplayReviewPackBuilder",
            "static let archiveFileName = \"Task030c_b17D_ReplayReviewPack.zip\"",
            "makeReviewPack(",
            "makeArtifacts(for pack: DeadReckoningReplayReviewPack)",
            "makeMarkdown(for pack: DeadReckoningReplayReviewPack)",
            "makeCSV(for pack: DeadReckoningReplayReviewPack)",
            "gapDurationSeconds",
            "imuSampleCoverageRatio",
            "headingReliability",
            "estimatedDisplacementMeters",
            "anchorClosureErrorMeters",
            "eligibleForUserVisibleEstimatedRoute",
            "blockingReasons",
            "let blockingReasonsText = record.blockingReasons.joined(separator: \";\")",
        ],
        "Tests/iOSTests/DeadReckoningReplayReviewPackTests.swift": [
            "testReviewPackSummarizesEligibleAndBlockedRealSessionGaps",
            "testReviewPackArtifactsContainJsonMarkdownAndCSV",
            "testReviewPackPreservesReplayOnlySafetyFlags",
            "testCSVIncludesBlockingReasonsForReview",
            "Task030c_b17D_ReplayReviewPack.zip",
        ],
        "Shared/Models/SessionData.swift": [
            'static let currentDebugBuildTaskID = "Task-030c-b18-D"',
        ],
        "Shared/Localization/en.lproj/Localizable.strings": [
            '"debug.build.currentTaskID" = "Task-030c-b18-D";',
        ],
        "Shared/Localization/ja.lproj/Localizable.strings": [
            '"debug.build.currentTaskID" = "Task-030c-b18-D";',
        ],
        "Shared/Localization/zh-Hant.lproj/Localizable.strings": [
            '"debug.build.currentTaskID" = "Task-030c-b18-D";',
        ],
        "SkateTrack.xcodeproj/project.pbxproj": [
            "DeadReckoningReplayReviewPack.swift in Sources",
            "DeadReckoningReplayReviewPackBuilder.swift in Sources",
            "DeadReckoningReplayReviewPackTests.swift in Sources",
        ],
        "docs/adr/ADR-INDEX.md": [
            "Task-030c-b17-D — Real-Session Replay Review Pack",
            "Task030c_b17D_ReplayReviewPack.zip",
            "product decision checkpoint",
            "no user-visible route display",
        ],
        "docs/history/DEV_LOG.md": [
            "Task-030c-b17-D — Real-Session Replay Review Pack",
            "DeadReckoningReplayReviewPackBuilder",
            "Task-030c-b17-D verification token",
        ],
        "docs/reference/FILE_STRUCTURE.md": [
            "Task-030c-b17-D real-session replay review pack",
            "DeadReckoningReplayReviewPack.swift",
            "DeadReckoningReplayReviewPackBuilder.swift",
            "DeadReckoningReplayReviewPackTests.swift",
            "verify_task030c_b17d_replay_review_pack.py",
        ],
        "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
            "Task-030c-b17-D — Real-Session Replay Review Pack",
            "JSON, Markdown, and CSV",
            "b18 display model work",
        ],
        "docs/planning/Task-030c-b16_Localization_Foundation_Plan.md": [
            "Task-030c-b17-D Implementation Note",
            "Task030c_b17D_ReplayReviewPack.zip",
            "non-code product decision checkpoint",
        ],
    }

    for relative_path, tokens in required_tokens.items():
        for token in tokens:
            require(relative_path, token)

    require_first_line_marker(
        "Shared/Models/DeadReckoningReplayReviewPack.swift",
        "// [協作區] Shared/Models/DeadReckoningReplayReviewPack.swift",
    )
    require_first_line_marker(
        "iOS/Core/SensorEngine/DeadReckoningReplayReviewPackBuilder.swift",
        "// [自主區] iOS/Core/SensorEngine/DeadReckoningReplayReviewPackBuilder.swift",
    )
    require_first_line_marker(
        "Tests/iOSTests/DeadReckoningReplayReviewPackTests.swift",
        "// [自主區] Tests/iOSTests/DeadReckoningReplayReviewPackTests.swift",
    )

    for relative_path in [
        "Shared/Models/DeadReckoningReplayReviewPack.swift",
        "iOS/Core/SensorEngine/DeadReckoningReplayReviewPackBuilder.swift",
        "Tests/iOSTests/DeadReckoningReplayReviewPackTests.swift",
    ]:
        require_swift_file_under_limit(relative_path)

    forbidden_tokens = [
        "estimatedRouteActive: true",
        "productionRouteDecisionApplied: true",
        "productionRouteMutationApplied = true",
        "trustedMetricsMutationApplied = true",
        "estimatedRouteDisplayEnabled = true",
        "SessionData.summaryMetrics",
        "summaryMetrics =",
        "routeMap",
        "mapMatching",
        "roadSnapping",
        "trustedDistanceOverride",
        "CLLocationManager",
    ]
    for relative_path in [
        "Shared/Models/DeadReckoningReplayReviewPack.swift",
        "iOS/Core/SensorEngine/DeadReckoningReplayReviewPackBuilder.swift",
    ]:
        text = read(relative_path)
        for token in forbidden_tokens:
            if token in text:
                raise AssertionError(f"{relative_path} contains forbidden production/display token: {token}")


    builder_text = read("iOS/Core/SensorEngine/DeadReckoningReplayReviewPackBuilder.swift")
    if r'joined(separator: \";\")' in builder_text:
        raise AssertionError("Markdown blocking reasons must be assigned before interpolation, not nested as an escaped separator inside a string interpolation")
    if 'let blockingReasonsText = record.blockingReasons.joined(separator: ";")' not in builder_text:
        raise AssertionError("Markdown blocking reasons must be assigned to blockingReasonsText before interpolation")

    panel_text = read("iOS/Features/Debug/DebugToolsPanelView.swift")
    if 'Text("Task-030c-b18-A")' in panel_text or 'Text("DEBUG")' in panel_text:
        raise AssertionError("Debug visible build strings must stay localized, not hard-coded Text literals")

    sensor_fusion_text = read("iOS/Core/SensorEngine/SensorFusionEngine.swift")
    if "estimatedRouteActive: false" not in sensor_fusion_text:
        raise AssertionError("SensorFusionEngine must keep estimatedRouteActive false")
    if "estimatedRouteActive: true" in sensor_fusion_text:
        raise AssertionError("SensorFusionEngine must not enable estimatedRouteActive true")

    print("Task-030c-b17-D real-session replay review pack checks passed.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"Task-030c-b17-D check failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
