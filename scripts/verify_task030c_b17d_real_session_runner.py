#!/usr/bin/env python3
"""Verify Task-030c-b17-D real-session runner / export glue safety boundaries."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def require(path: str, tokens: list[str]) -> None:
    text = read(path)
    for token in tokens:
        if token not in text:
            raise AssertionError(f"Missing token in {path}: {token}")


def require_under_limit(path: str, limit: int = 500) -> None:
    count = len(read(path).splitlines())
    if count > limit:
        raise AssertionError(f"{path} has {count} lines; limit is {limit}")


def require_absent(path: str, forbidden: list[str]) -> None:
    text = read(path)
    for token in forbidden:
        if token in text:
            raise AssertionError(f"Forbidden token in {path}: {token}")


def main() -> None:
    require("scripts/generate_task030c_b17d_real_session_review_pack.py", [
        "Task030c_b17D_ReplayReviewPack.zip",
        "collect_session_files",
        "--session-notes-json",
        "estimatedRouteDisplayEnabled",
        "productionRouteMutationApplied",
        "trustedMetricsMutationApplied",
        "make_markdown",
        "make_csv",
    ])
    require("scripts/task030c_b17d_real_session_metrics.py", [
        "analyze_skatetrack_file",
        "make_gap_record",
        "gapDurationSeconds",
        "imuSampleCoverageRatio",
        "headingReliability",
        "estimatedDisplacementMeters",
        "anchorClosureErrorMeters",
        "closureErrorRatio",
        "eligibleForUserVisibleEstimatedRoute",
        "replayGapExceedsB17BEngineLimit",
        "closureErrorExceededBlockingThreshold",
        "headingReliabilityInsufficient",
        "imuSampleCoverageInsufficient",
    ])
    for path in [
        "scripts/generate_task030c_b17d_real_session_review_pack.py",
        "scripts/task030c_b17d_real_session_metrics.py",
        "scripts/verify_task030c_b17d_real_session_runner.py",
    ]:
        require_under_limit(path)
        require_absent(path, [
            "estimatedRouteActive" + ": true",
            "estimatedRouteDisplayEnabled" + " = true",
            "productionRouteMutationApplied" + " = true",
            "trustedMetricsMutationApplied" + " = true",
            "summaryM" + "etrics =",
            "rewriteRou" + "teGeometry",
            "roadSn" + "apping",
            "mapMa" + "tching",
            "CLLocati" + "onManager",
        ])
    require("docs/adr/ADR-INDEX.md", [
        "Task-030c-b17-D-3 — Real-Session Review Runner / Export Glue",
        "scripts/generate_task030c_b17d_real_session_review_pack.py",
        "Task030c_b17D_ReplayReviewPack.zip",
    ])
    require("docs/history/DEV_LOG.md", [
        "Task-030c-b17-D-3 — Real-Session Review Runner / Export Glue",
        "real `.skatetrack` session exports",
    ])
    require("docs/planning/Task-030c-b16_Localization_Foundation_Plan.md", [
        "Task-030c-b17-D-3 Implementation Note",
        "real-session review runner / export glue",
    ])
    require("docs/reference/FILE_STRUCTURE.md", [
        "Task-030c-b17-D-3 real-session review runner / export glue",
        "scripts/generate_task030c_b17d_real_session_review_pack.py",
        "scripts/task030c_b17d_real_session_metrics.py",
    ])
    require("docs/release/KNOWN_LIMITATIONS_PRE_ADP.md", [
        "Task-030c-b17-D-3 — Real-Session Review Runner / Export Glue",
        "does not enable user-visible estimated route display",
    ])
    print("Task-030c-b17-D-3 real-session runner checks passed.")


if __name__ == "__main__":
    main()
