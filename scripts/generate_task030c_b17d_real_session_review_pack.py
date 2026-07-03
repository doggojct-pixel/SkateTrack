#!/usr/bin/env python3
"""Generate Task-030c-b17-D real-session replay review artifacts from .skatetrack files."""

from __future__ import annotations

import argparse
import csv
import json
import tempfile
import zipfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable

from task030c_b17d_real_session_metrics import analyze_skatetrack_file

TASK_IDENTIFIER = "Task-030c-b17-D"
ARCHIVE_FILE_NAME = "Task030c_b17D_ReplayReviewPack.zip"
MINIMUM_GAP_SECONDS = 1.5


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate a b17-D replay review pack from real .skatetrack sessions.")
    parser.add_argument("inputs", nargs="+", help=".skatetrack files, directories, or zip files containing .skatetrack files.")
    parser.add_argument("--output-dir", default=".", help="Directory where the review pack is written.")
    parser.add_argument("--session-notes-json", default=None, help="Optional JSON map from filename token to reviewRole/operatorNote metadata.")
    parser.add_argument("--minimum-gap-seconds", type=float, default=MINIMUM_GAP_SECONDS, help="Minimum location-fix interval considered a review gap.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    output_dir = Path(args.output_dir).expanduser().resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    notes = load_notes(Path(args.session_notes_json)) if args.session_notes_json else {}
    with tempfile.TemporaryDirectory(prefix="task030c_b17d_sessions_") as temp_dir:
        session_files = collect_session_files([Path(value).expanduser() for value in args.inputs], Path(temp_dir))
        if not session_files:
            raise SystemExit("No .skatetrack files found for b17-D real-session review.")
        summaries: list[dict[str, Any]] = []
        gap_records: list[dict[str, Any]] = []
        for session_file in sorted(session_files):
            result = analyze_skatetrack_file(session_file, context_for(session_file.name, notes), max(0.1, args.minimum_gap_seconds))
            summaries.append(result["summary"])
            gap_records.extend(result["gapRecords"])
    pack = make_pack(summaries, gap_records)
    write_artifacts(pack, output_dir)
    print("Task-030c-b17-D real-session review pack generated.")
    print(f"Archive: {output_dir / ARCHIVE_FILE_NAME}")
    return 0


def load_notes(path: Path) -> dict[str, dict[str, str]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise SystemExit("--session-notes-json must be a JSON object.")
    return data


def collect_session_files(inputs: Iterable[Path], temp_dir: Path) -> list[Path]:
    files: list[Path] = []
    for input_path in inputs:
        if input_path.is_dir():
            files.extend(path for path in input_path.rglob("*.skatetrack") if not is_macos_resource_file(path))
        elif input_path.suffix.lower() == ".zip":
            extract_dir = temp_dir / input_path.stem
            extract_dir.mkdir(parents=True, exist_ok=True)
            with zipfile.ZipFile(input_path) as archive:
                archive.extractall(extract_dir)
            files.extend(path for path in extract_dir.rglob("*.skatetrack") if not is_macos_resource_file(path))
        elif input_path.suffix.lower() == ".skatetrack" and input_path.exists() and not is_macos_resource_file(input_path):
            files.append(input_path)
    return sorted(set(files))


def is_macos_resource_file(path: Path) -> bool:
    return "__MACOSX" in path.parts or path.name.startswith("._")


def context_for(file_name: str, notes: dict[str, dict[str, str]]) -> dict[str, str]:
    for token, value in notes.items():
        if token in file_name and isinstance(value, dict):
            return {str(k): str(v) for k, v in value.items()}
    return {}


def make_pack(summaries: list[dict[str, Any]], gap_records: list[dict[str, Any]]) -> dict[str, Any]:
    return {
        "schemaVersion": 1,
        "taskIdentifier": TASK_IDENTIFIER,
        "archiveFileName": ARCHIVE_FILE_NAME,
        "createdAt": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "replayReviewOnly": True,
        "productionRouteMutationApplied": False,
        "trustedMetricsMutationApplied": False,
        "estimatedRouteDisplayEnabled": False,
        "productDecisionCheckpointRequired": True,
        "b18DisplayWorkBlockedUntilProductDecision": True,
        "sessionSummaries": summaries,
        "gapRecords": gap_records,
    }


def write_artifacts(pack: dict[str, Any], output_dir: Path) -> None:
    base_name = "Task030c_b17D_real_sessions_ReplayReviewPack"
    json_path = output_dir / f"{base_name}.json"
    md_path = output_dir / f"{base_name}.md"
    csv_path = output_dir / f"{base_name}.csv"
    archive_path = output_dir / ARCHIVE_FILE_NAME
    json_path.write_text(json.dumps(pack, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    md_path.write_text(make_markdown(pack), encoding="utf-8")
    csv_path.write_text(make_csv(pack), encoding="utf-8")
    with zipfile.ZipFile(archive_path, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for artifact in (json_path, md_path, csv_path):
            archive.write(artifact, artifact.name)


def make_markdown(pack: dict[str, Any]) -> str:
    lines = [
        "# Task-030c-b17-D Real-Session Replay Review Pack", "",
        f"Archive: `{pack['archiveFileName']}`", f"Task: `{pack['taskIdentifier']}`",
        f"Replay review only: `{pack['replayReviewOnly']}`", f"Production route mutation applied: `{pack['productionRouteMutationApplied']}`",
        f"Trusted metrics mutation applied: `{pack['trustedMetricsMutationApplied']}`", f"Estimated route display enabled: `{pack['estimatedRouteDisplayEnabled']}`",
        f"Product decision checkpoint required: `{pack['productDecisionCheckpointRequired']}`", f"b18 display work blocked until product decision: `{pack['b18DisplayWorkBlockedUntilProductDecision']}`",
        "", "## Session summaries", "", "| Session | Role | Gaps | Replay OK | Blocked | Eligible | Longest gap | Max closure error |", "|---|---|---:|---:|---:|---:|---:|---:|",
    ]
    for summary in pack["sessionSummaries"]:
        lines.append(f"| {summary['sessionIdentifier']} | {summary['reviewRole']} | {summary['totalGapCount']} | {summary['replaySucceededGapCount']} | {summary['blockedGapCount']} | {summary['userVisibleEligibleGapCount']} | {summary['longestGapSeconds']} | {summary['maximumClosureErrorMeters'] or ''} |")
    lines.extend(["", "## Gap records", "", "| Session | Gap | Duration | IMU coverage | Heading | Estimated displacement | Closure error | Eligible | Blocking reasons |", "|---|---:|---:|---:|---|---:|---:|---|---|"])
    for record in pack["gapRecords"]:
        lines.append(f"| {record['sessionIdentifier']} | {record['gapIndex']} | {record['gapDurationSeconds']} | {record['imuSampleCoverageRatio']} | {record['headingReliability']} | {record['estimatedDisplacementMeters']} | {record['anchorClosureErrorMeters']} | {record['eligibleForUserVisibleEstimatedRoute']} | {';'.join(record['blockingReasons'])} |")
    return "\n".join(lines) + "\n"


def make_csv(pack: dict[str, Any]) -> str:
    import io
    output = io.StringIO()
    fieldnames = ["sessionIdentifier", "reviewRole", "gapIndex", "gapDurationSeconds", "imuSampleCoverageRatio", "headingReliability", "estimatedDisplacementMeters", "anchorDistanceMeters", "anchorClosureErrorMeters", "closureErrorRatio", "eligibleForUserVisibleEstimatedRoute", "replayBlockingReason", "blockingReasons"]
    writer = csv.DictWriter(output, fieldnames=fieldnames, extrasaction="ignore")
    writer.writeheader()
    for record in pack["gapRecords"]:
        row = dict(record)
        row["blockingReasons"] = ";".join(record["blockingReasons"])
        writer.writerow(row)
    return output.getvalue()


if __name__ == "__main__":
    raise SystemExit(main())
