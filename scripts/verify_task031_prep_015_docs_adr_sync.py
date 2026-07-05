#!/usr/bin/env python3
# [協作區] scripts/verify_task031_prep_015_docs_adr_sync.py
# Purpose: Verify Task-031-prep ActivityViz-015 docs / ADR final sync boundaries.
# Scope: static documentation, ADR, limitation, source-untouched, and persistence/export safety checks only.

from pathlib import Path
import subprocess
import sys

REPO = Path.cwd()
failures = 0
warnings = 0

print("===== Task-031-prep ActivityViz-015 docs / ADR sync verifier =====")
print("Aligned Build Plan: Task-031-prep_Shared_Activity_Visualization_Pipeline_for_iOS_macOS_watchOS_EN_v1_1.md")
print("Aligned subtask: task-031-prep-ActivityViz-015 — Docs / ADR Final Sync")
print(f"REPO={REPO}")


def fail(message: str) -> None:
    global failures
    print(f"FAIL: {message}")
    failures += 1


def warn(message: str) -> None:
    global warnings
    print(f"WARN: {message}")
    warnings += 1


def pass_msg(message: str) -> None:
    print(f"PASS: {message}")


def read(path: str) -> str:
    p = REPO / path
    if not p.exists():
        fail(f"required path missing: {path}")
        return ""
    pass_msg(f"required path exists: {path}")
    try:
        return p.read_text()
    except UnicodeDecodeError:
        return p.read_text(encoding="utf-8", errors="replace")


def require_token(path: str, text: str, token: str) -> None:
    if token in text:
        pass_msg(f"{path} contains token: {token}")
    else:
        fail(f"{path} missing token: {token}")


def forbid_token(path: str, text: str, token: str) -> None:
    if token in text:
        fail(f"{path} contains forbidden token: {token}")
    else:
        pass_msg(f"{path} does not contain forbidden token: {token}")


def first_line_and_count(path: str) -> None:
    p = REPO / path
    if not p.exists():
        fail(f"line check path missing: {path}")
        return
    lines = p.read_text(encoding="utf-8", errors="replace").splitlines()
    first = lines[0] if lines else ""
    print(f"FIRST_LINE[{path}]={first}")
    print(f"LINE_COUNT[{path}]={len(lines)}")
    if path.endswith(".py"):
        if first.startswith("#!") and "[協作區]" in "\n".join(lines[:4]):
            pass_msg(f"{path} has collaboration/autonomous script header")
        else:
            fail(f"{path} missing collaboration/autonomous script header")
    if path.endswith(".swift"):
        if first.startswith("// [協作區]") or first.startswith("// [自主區]"):
            pass_msg(f"{path} has collaboration/autonomous header")
        else:
            fail(f"{path} missing collaboration/autonomous header")
        if len(lines) < 500:
            pass_msg(f"{path} stays under 500 lines")
        else:
            fail(f"{path} exceeds 500 lines")
    if path.endswith(".py"):
        if len(lines) < 500:
            pass_msg(f"{path} stays under 500 lines")
        else:
            fail(f"{path} exceeds 500 lines")


def git_status(path: str) -> str:
    result = subprocess.run(
        ["git", "status", "--short", "--", path],
        cwd=REPO,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode != 0:
        warn(f"git status failed for {path}: {result.stderr.strip()}")
        return ""
    status = result.stdout.strip()
    key = path.upper().replace("/", "_").replace(".", "_").replace("-", "_")
    print(f"{key}_STATUS={status or 'CLEAN'}")
    return status


def require_clean(path: str) -> None:
    status = git_status(path)
    if status:
        fail(f"untouched guard dirty: {path}")
    else:
        pass_msg(f"untouched guard clean: {path}")


required_paths = [
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/adr/ADR-INDEX.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "scripts/verify_task031_prep_014_cross_platform_visualization.py",
    "scripts/verify_task031_prep_015_docs_adr_sync.py",
    "Shared/ActivityVisualization/ActivityVisualizationPipeline.swift",
    "Shared/ActivityVisualization/Compact/CompactActivityVisualizationModels.swift",
    "Shared/ActivityVisualization/Route/RouteDisplayPipeline.swift",
    "Shared/ActivityVisualization/Speed/SpeedDisplayPipeline.swift",
    "Shared/ActivityVisualization/Elevation/ElevationDisplayPipeline.swift",
    "Tests/ActivityVisualizationTests/ActivityVisualizationPipelineTests.swift",
    "Tests/ActivityVisualizationTests/CompactActivityVisualizationTests.swift",
    "SkateTrack.xcodeproj/project.pbxproj",
]

texts = {path: read(path) for path in required_paths}
for path in [
    "scripts/verify_task031_prep_015_docs_adr_sync.py",
    "Shared/ActivityVisualization/ActivityVisualizationPipeline.swift",
    "Shared/ActivityVisualization/Compact/CompactActivityVisualizationModels.swift",
    "Shared/ActivityVisualization/Elevation/ElevationDisplayPipeline.swift",
    "Tests/ActivityVisualizationTests/ActivityVisualizationPipelineTests.swift",
    "Tests/ActivityVisualizationTests/CompactActivityVisualizationTests.swift",
]:
    first_line_and_count(path)

# Docs / ADR sync tokens.
common_tokens = [
    "Task-031-prep-ActivityViz-015 Docs / ADR Final Sync",
    "Shared decides visualization data semantics; platforms decide rendering",
    "ActivityVisualizationPipeline",
    "ActivityVisualizationCompactSummary",
    "CompactRouteDisplay",
    "CompactSpeedSparkline",
    "CompactElevationProfile",
    "Cross-platform Visualization Verifier",
    "ActivityViz-016",
    "no Watch UI",
    "no Watch recording",
    "no persistence/export/package schema change",
]
for token in common_tokens:
    require_token("docs/history/DEV_LOG.md", texts["docs/history/DEV_LOG.md"], token)

file_structure_tokens = [
    "Task-031-prep ActivityViz-015 Docs / ADR Final Sync",
    "Shared/ActivityVisualization/ActivityVisualizationPipeline.swift",
    "Shared/ActivityVisualization/Compact/CompactActivityVisualizationModels.swift",
    "Shared/ActivityVisualization/Elevation/ElevationDisplayPipeline.swift",
    "scripts/verify_task031_prep_015_docs_adr_sync.py",
    "docs/adr/ADR-INDEX.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "display-only compact summaries",
    "ActivityViz-016 remains responsible for the final parity gate",
]
for token in file_structure_tokens:
    require_token("docs/reference/FILE_STRUCTURE.md", texts["docs/reference/FILE_STRUCTURE.md"], token)

adr_tokens = [
    "Task-031-prep shared activity visualization ownership",
    "Shared decides visualization data semantics; platforms decide rendering",
    "display-only preparation layer",
    "ActivityVisualizationResult",
    "CompactRouteDisplay",
    "CompactSpeedSparkline",
    "CompactElevationProfile",
    "verify_task031_prep_014_cross_platform_visualization.py",
    "no Watch UI",
    "no Watch recording",
    "no persistence/export/package schema mutation",
]
for token in adr_tokens:
    require_token("docs/adr/ADR-INDEX.md", texts["docs/adr/ADR-INDEX.md"], token)

limitation_tokens = [
    "Task-031-prep Activity Visualization Display Boundary",
    "Shared decides visualization data semantics; platforms decide rendering",
    "display-only compact summaries",
    "ActivityVisualizationPipeline",
    "ActivityVisualizationResult",
    "ActivityVisualizationCompactSummary",
    "no Watch UI",
    "no Watch recording",
    "no persistence/export/package schema change",
    "no trusted metric mutation",
]
for token in limitation_tokens:
    require_token("docs/release/KNOWN_LIMITATIONS_PRE_ADP.md", texts["docs/release/KNOWN_LIMITATIONS_PRE_ADP.md"], token)

verifier_tokens = [
    "Task-031-prep ActivityViz-015 docs / ADR sync verifier",
    "docs/adr/ADR-INDEX.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "COMPACT_OR_DISPLAY_DERIVED_PERSISTENCE_EXPORT_COUNT",
    "WATCH_UI_RECORDING_COMPACT_USAGE_COUNT",
    "VERIFY_TASK031_PREP_015_DOCS_ADR_SYNC_RESULT",
]
for token in verifier_tokens:
    require_token("scripts/verify_task031_prep_015_docs_adr_sync.py", texts["scripts/verify_task031_prep_015_docs_adr_sync.py"], token)

# Production and project files must stay untouched in ActivityViz-015.
for path in [
    "Shared/ActivityVisualization",
    "Tests/ActivityVisualizationTests",
    "SkateTrack.xcodeproj/project.pbxproj",
    "iOS/Features/SessionSummary/SessionAdvancedChartsView.swift",
    "iOS/Features/SessionSummary/SessionRouteMapView.swift",
    "iOS/Features/SessionSummary/SpeedTimelineChartView.swift",
    "iOS/Features/SessionSummary/ElevationProfileChartView.swift",
    "macOS/Features/SessionBrowser/MacSessionViewerModel.swift",
    "macOS/Features/SessionBrowser/MacSessionDetailView.swift",
    "macOS/Features/SessionBrowser/MacRouteDisplayPipeline.swift",
    "macOS/Features/SessionBrowser/MacElevationDisplayPipeline.swift",
    "macOS/Features/SessionBrowser/MacSpeedSparklineView.swift",
    "watchOS",
]:
    if (REPO / path).exists():
        require_clean(path)

# Shared/test UI import boundary remains intact.
forbidden_imports = ["import SwiftUI", "import MapKit", "import UIKit", "import AppKit", "import WatchKit"]
for root in ["Shared/ActivityVisualization", "Tests/ActivityVisualizationTests"]:
    files = sorted((REPO / root).rglob("*.swift")) if (REPO / root).exists() else []
    for token in forbidden_imports:
        count = sum(1 for file in files if token in file.read_text(encoding="utf-8", errors="replace"))
        print(f"FORBIDDEN_UI_IMPORT_COUNT[{root}][{token}]={count}")
        if count == 0:
            pass_msg(f"{root} avoids forbidden token: {token}")
        else:
            fail(f"{root} contains forbidden token: {token}")

# Ensure persistence/export/package paths are not absorbing display-only compact/displayDerived concepts.
restricted_roots = [
    "Shared/Models",
    "Shared/Persistence",
    "Shared/Repositories",
    "Shared/Packages",
    "iOS/Core",
    "macOS/Core",
    "macOS/Persistence",
    "macOS/Repositories",
]
restricted_tokens = [
    "displayDerivedTotalAscentMeters",
    "displayDerivedTotalDescentMeters",
    "displayDerived",
    "CompactRouteDisplay",
    "CompactSpeedSparkline",
    "CompactElevationProfile",
]
restricted_hits = []
for root in restricted_roots:
    root_path = REPO / root
    if not root_path.exists():
        continue
    for file in root_path.rglob("*"):
        if not file.is_file() or file.suffix not in {".swift", ".json", ".md", ".txt"}:
            continue
        content = file.read_text(encoding="utf-8", errors="replace")
        for token in restricted_tokens:
            if token in content:
                restricted_hits.append((str(file.relative_to(REPO)), token))
print(f"COMPACT_OR_DISPLAY_DERIVED_PERSISTENCE_EXPORT_COUNT={len(restricted_hits)}")
if restricted_hits:
    for file, token in restricted_hits:
        print(f"FORBIDDEN_PERSISTENCE_EXPORT_TOKEN={file}::{token}")
    fail("compact/displayDerived tokens found in persistence/export/package restricted paths")
else:
    pass_msg("compact/displayDerived tokens absent from persistence/export/package paths")

# Watch must not start consuming compact visualization or add recording/UI behavior in this docs-only step.
watch_tokens = ["CompactRouteDisplay", "CompactSpeedSparkline", "CompactElevationProfile", "ActivityVisualizationPipeline", "startRecording", "recording"]
watch_hits = []
watch_root = REPO / "watchOS"
if watch_root.exists():
    for file in watch_root.rglob("*.swift"):
        content = file.read_text(encoding="utf-8", errors="replace")
        for token in watch_tokens:
            if token in content:
                watch_hits.append((str(file.relative_to(REPO)), token))
print(f"WATCH_UI_RECORDING_COMPACT_USAGE_COUNT={len(watch_hits)}")
if watch_hits:
    for file, token in watch_hits:
        print(f"WATCH_FORBIDDEN_TOKEN={file}::{token}")
    fail("watchOS changed to consume compact visualization or recording tokens")
else:
    pass_msg("watchOS has no Watch UI/recording/compact consumption changes for ActivityViz-015")

for path, text in [
    ("docs/history/DEV_LOG.md", texts["docs/history/DEV_LOG.md"]),
    ("docs/reference/FILE_STRUCTURE.md", texts["docs/reference/FILE_STRUCTURE.md"]),
    ("docs/adr/ADR-INDEX.md", texts["docs/adr/ADR-INDEX.md"]),
    ("docs/release/KNOWN_LIMITATIONS_PRE_ADP.md", texts["docs/release/KNOWN_LIMITATIONS_PRE_ADP.md"]),
]:
    forbid_token(path, text, "ActivityViz-015 implemented Watch UI")
    forbid_token(path, text, "ActivityViz-015 implemented Watch recording")
    forbid_token(path, text, "ActivityViz-015 changed persistence schema")

print("===== Summary =====")
print(f"WARNING_COUNT={warnings}")
print(f"FAILURE_COUNT={failures}")
if failures == 0:
    print("VERIFY_TASK031_PREP_015_DOCS_ADR_SYNC_RESULT=PASSED")
else:
    print("VERIFY_TASK031_PREP_015_DOCS_ADR_SYNC_RESULT=FAILED")
sys.exit(0 if failures == 0 else 1)
