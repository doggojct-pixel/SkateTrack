#!/usr/bin/env python3
"""Verify Task-030c-b11-r3-3 trusted chart metrics and display source alignment."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIREMENTS = {
    "Shared/Models/SessionData.swift": [
        'static let currentDebugBuildTaskID = "Task-030c-b13-B-1"',
    ],
    "iOS/Features/Debug/DebugToolsPanelView.swift": [
        "Task-030c-b13-B-1",
    ],
    "iOS/Features/SessionSummary/SessionAdvancedChartsView.swift": [
        "displaySpeedKilometersPerHour(for:",
        "smoothedSpeedPoints(",
        "preferredElevationDisplaySource(for:",
        "displayElevationMeters(for:",
        "absoluteElevationDisplayAnchor(for:",
        "sample.altitudeSource == .barometerRelative",
        "chart display falls back to metric-eligible diagnostics speed",
    ],
    "iOS/Features/SessionRecording/LiveHUDView.swift": [
        "smoothedDisplaySpeedKilometersPerHour(",
        "maximumDisplayStepKmh",
    ],
    "docs/history/DEV_LOG.md": [
        "Task-030c-b11-r3-3",
        "Trusted Chart Metrics + Display Source Alignment",
    ],
    "docs/reference/FILE_STRUCTURE.md": [
        "verify_task030c_trusted_chart_metrics.py",
    ],
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
        "Task-030c-b11-r3-3",
        "trusted chart metrics",
    ],
}


def read(path: str) -> str:
    full = ROOT / path
    try:
        return full.read_text()
    except FileNotFoundError:
        print(f"Missing required file: {path}", file=sys.stderr)
        sys.exit(1)


def main() -> int:
    missing = []
    for path, tokens in REQUIREMENTS.items():
        content = read(path)
        for token in tokens:
            if token not in content:
                missing.append((path, token))
    if missing:
        print("Task-030c-b11-r3-3 trusted chart metrics check failed:", file=sys.stderr)
        for path, token in missing:
            print(f"  {path}: missing {token!r}", file=sys.stderr)
        return 1
    print("Task-030c-b11-r3-3 trusted chart metrics checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
