#!/usr/bin/env python3
# [協作區] scripts/verify_task031_prep_016_final_parity_gate.py
# Purpose: Final parity gate for Task-031-prep Shared ActivityVisualization completion.
# Scope: static source/docs/membership/ownership and persistence/export safety checks only.

from pathlib import Path
import subprocess
import sys

REPO = Path.cwd()
failures = 0
warnings = 0

print("===== Task-031-prep ActivityViz-016 final parity gate verifier =====")
print("Aligned Build Plan: Task-031-prep_Shared_Activity_Visualization_Pipeline_for_iOS_macOS_watchOS_EN_v1_1.md")
print("Aligned subtask: task-031-prep-ActivityViz-016 — Final Parity Gate")
print(f"REPO={REPO}")


def fail(message: str) -> None:
    global failures
    failures += 1
    print(f"FAIL: {message}")


def warn(message: str) -> None:
    global warnings
    warnings += 1
    print(f"WARN: {message}")


def pass_msg(message: str) -> None:
    print(f"PASS: {message}")


def require_path(path: str) -> Path:
    p = REPO / path
    if p.exists():
        pass_msg(f"required path exists: {path}")
    else:
        fail(f"required path missing: {path}")
    return p


def read(path: str) -> str:
    p = require_path(path)
    if not p.exists():
        return ""
    return p.read_text(encoding="utf-8", errors="replace")


def require_token(label: str, text: str, token: str) -> None:
    if token in text:
        pass_msg(f"{label} contains token: {token}")
    else:
        fail(f"{label} missing token: {token}")


def forbid_token(label: str, text: str, token: str) -> None:
    if token in text:
        fail(f"{label} contains forbidden token: {token}")
    else:
        pass_msg(f"{label} does not contain forbidden token: {token}")


def line_check(path: str, max_lines: int = 500) -> None:
    p = require_path(path)
    if not p.exists():
        return
    lines = p.read_text(encoding="utf-8", errors="replace").splitlines()
    first = lines[0] if lines else ""
    print(f"FIRST_LINE[{path}]={first}")
    print(f"LINE_COUNT[{path}]={len(lines)}")
    if path.endswith(".swift"):
        if first.startswith("// [協作區]") or first.startswith("// [自主區]"):
            pass_msg(f"{path} has collaboration/autonomous header")
        else:
            fail(f"{path} missing collaboration/autonomous header")
    if path.endswith(".py"):
        if first.startswith("#!") and "[協作區]" in "\n".join(lines[:4]):
            pass_msg(f"{path} has collaboration/autonomous script header")
        else:
            fail(f"{path} missing collaboration/autonomous script header")
    if len(lines) <= max_lines:
        pass_msg(f"{path} stays under {max_lines} lines")
    else:
        fail(f"{path} exceeds {max_lines} lines")


def git_status(path: str) -> str:
    result = subprocess.run(
        ["git", "status", "--short", "--", path],
        cwd=REPO,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
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
        print(status)
        fail(f"untouched guard dirty: {path}")
    else:
        pass_msg(f"untouched guard clean: {path}")


def source_phase_count(pbxproj: str, filename: str) -> int:
    marker = f"/* {filename} in Sources */"
    return sum(1 for line in pbxproj.splitlines() if marker in line and line.strip().endswith(","))


def scan_tokens(root: str, tokens: list[str], suffixes: set[str]) -> list[tuple[str, str]]:
    hits = []
    root_path = REPO / root
    if not root_path.exists():
        return hits
    for file in root_path.rglob("*"):
        if not file.is_file() or file.suffix not in suffixes:
            continue
        text = file.read_text(encoding="utf-8", errors="replace")
        for token in tokens:
            relative = str(file.relative_to(REPO))
            if relative == "Shared/Models/SkateTrackPackageManifest.swift" and token == "displayDerived":
                safe_text = text.replace("displayDerivedOnly", "")
                if token not in safe_text:
                    continue
            if token in text:
                hits.append((relative, token))
    return hits


required_paths = [
    "Shared/ActivityVisualization",
    "Shared/ActivityVisualization/Route/RouteDisplayPipeline.swift",
    "Shared/ActivityVisualization/Speed/SpeedDisplayPipeline.swift",
    "Shared/ActivityVisualization/Elevation/ElevationDisplayPipeline.swift",
    "Shared/ActivityVisualization/ActivityVisualizationPipeline.swift",
    "Shared/ActivityVisualization/Compact/CompactActivityVisualizationModels.swift",
    "Tests/ActivityVisualizationTests",
    "iOS/Features/SessionSummary",
    "macOS/Features/SessionBrowser",
    "watchOS",
    "SkateTrack.xcodeproj/project.pbxproj",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/adr/ADR-INDEX.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "scripts/verify_task031_prep_003_route_pipeline.py",
    "scripts/verify_task031_prep_004_ios_route_migration.py",
    "scripts/verify_task031_prep_010_ios_elevation_migration.py",
    "scripts/verify_task031_prep_011_macos_elevation_migration.py",
    "scripts/verify_task031_prep_012_unified_pipeline.py",
    "scripts/verify_task031_prep_013_compact_adapter.py",
    "scripts/verify_task031_prep_014_cross_platform_visualization.py",
    "scripts/verify_task031_prep_015_docs_adr_sync.py",
    "scripts/verify_task031_prep_016_final_parity_gate.py",
]
for path in required_paths:
    require_path(path)

shared_swift = sorted((REPO / "Shared/ActivityVisualization").rglob("*.swift"))
test_swift = sorted((REPO / "Tests/ActivityVisualizationTests").rglob("*.swift"))
print(f"SHARED_ACTIVITYVIZ_SWIFT_FILE_COUNT={len(shared_swift)}")
print(f"ACTIVITYVIZ_TEST_SWIFT_FILE_COUNT={len(test_swift)}")
if len(shared_swift) < 15:
    fail("expected at least 15 Shared/ActivityVisualization Swift files")
if len(test_swift) < 5:
    fail("expected at least 5 ActivityVisualization test Swift files")
for path in shared_swift:
    line_check(str(path.relative_to(REPO)))
for path in test_swift:
    line_check(str(path.relative_to(REPO)))
line_check("scripts/verify_task031_prep_016_final_parity_gate.py")

configuration = read("Shared/ActivityVisualization/ActivityVisualizationConfiguration.swift")
pipeline = read("Shared/ActivityVisualization/ActivityVisualizationPipeline.swift")
compact = read("Shared/ActivityVisualization/Compact/CompactActivityVisualizationModels.swift")
route = read("Shared/ActivityVisualization/Route/RouteDisplayPipeline.swift")
speed = read("Shared/ActivityVisualization/Speed/SpeedDisplayPipeline.swift")
elevation = read("Shared/ActivityVisualization/Elevation/ElevationDisplayPipeline.swift")
pbxproj = read("SkateTrack.xcodeproj/project.pbxproj")
dev_log = read("docs/history/DEV_LOG.md")
file_structure = read("docs/reference/FILE_STRUCTURE.md")
adr_index = read("docs/adr/ADR-INDEX.md")
known_limitations = read("docs/release/KNOWN_LIMITATIONS_PRE_ADP.md")
verifier_text = read("scripts/verify_task031_prep_016_final_parity_gate.py")

for label, text, tokens in [
    ("ActivityVisualizationConfiguration.swift", configuration, [
        "struct ActivityVisualizationConfiguration", "struct ActivityVisualizationResult",
        "struct ActivityVisualizationCompactSummary", "CompactRouteDisplay(route: route)",
        "CompactSpeedSparkline(speed: speed)", "CompactElevationProfile(elevation: elevation)",
    ]),
    ("ActivityVisualizationPipeline.swift", pipeline, [
        "struct ActivityVisualizationPipeline", "func makeVisualization(",
        "RouteDisplayPipeline(configuration: configuration.route).makeDisplayRoute(",
        "SpeedDisplayPipeline(configuration: configuration.speed).makeDisplaySpeed(",
        "ElevationDisplayPipeline(configuration: configuration.elevation).makeDisplayElevation(",
    ]),
    ("RouteDisplayPipeline.swift", route, ["struct RouteDisplayPipeline", "func makeDisplayRoute(", "RouteDisplayResult(", "ActivityRouteDisplayPoint("]),
    ("SpeedDisplayPipeline.swift", speed, ["struct SpeedDisplayPipeline", "func makeDisplaySpeed(", "SpeedDisplayResult(", "SpeedDisplayPoint("]),
    ("ElevationDisplayPipeline.swift", elevation, ["struct ElevationDisplayPipeline", "func makeDisplayElevation(", "switch selectedSource", "ElevationDisplayResult("]),
    ("CompactActivityVisualizationModels.swift", compact, [
        "struct CompactRouteDisplay", "struct CompactSpeedSparkline", "struct CompactElevationProfile",
        "init(route: RouteDisplayResult, maximumPointCount: Int = 48)",
        "init(speed: SpeedDisplayResult, maximumPointCount: Int = 48)",
        "init(elevation: ElevationDisplayResult, maximumPointCount: Int = 48)",
    ]),
]:
    for token in tokens:
        require_token(label, text, token)

for root in ["Shared/ActivityVisualization", "Tests/ActivityVisualizationTests"]:
    for token in ["import SwiftUI", "import MapKit", "import UIKit", "import AppKit", "import WatchKit"]:
        hits = scan_tokens(root, [token], {".swift"})
        print(f"FORBIDDEN_UI_IMPORT_COUNT[{root}][{token}]={len(hits)}")
        if hits:
            for file, hit in hits:
                print(f"FORBIDDEN_UI_IMPORT={file}::{hit}")
            fail(f"{root} contains forbidden platform UI import: {token}")
        else:
            pass_msg(f"{root} avoids forbidden token: {token}")

for path in [
    "Shared/ActivityVisualization", "Tests/ActivityVisualizationTests", "SkateTrack.xcodeproj/project.pbxproj",
    "iOS/Features/SessionSummary/SessionAdvancedChartsView.swift",
    "iOS/Features/SessionSummary/SessionRouteMapView.swift",
    "iOS/Features/SessionSummary/SpeedTimelineChartView.swift",
    "iOS/Features/SessionSummary/ElevationProfileChartView.swift",
    "macOS/Features/SessionBrowser/MacSessionViewerModel.swift",
    "macOS/Features/SessionBrowser/MacSessionDetailView.swift",
    "macOS/Features/SessionBrowser/MacRouteDisplayPipeline.swift",
    "macOS/Features/SessionBrowser/MacElevationDisplayPipeline.swift",
    "macOS/Features/SessionBrowser/MacSpeedSparklineView.swift", "watchOS",
]:
    if (REPO / path).exists():
        require_clean(path)

for path in shared_swift:
    filename = path.name
    count = source_phase_count(pbxproj, filename)
    print(f"PROJECT_SOURCE_PHASE_COUNT[{filename}]={count}")
    if count == 3:
        pass_msg(f"{filename} has iOS/macOS/watchOS source membership")
    else:
        fail(f"{filename} must have exactly 3 iOS/macOS/watchOS source memberships")
for path in test_swift:
    filename = path.name
    count = source_phase_count(pbxproj, filename)
    print(f"PROJECT_TEST_SOURCE_PHASE_COUNT[{filename}]={count}")
    if count == 1:
        pass_msg(f"{filename} has one ActivityVisualization test source membership")
    else:
        fail(f"{filename} must have exactly 1 ActivityVisualization test source membership")

restricted_hits = []
restricted_roots = ["Shared/Models", "Shared/Persistence", "Shared/Repositories", "Shared/Packages", "iOS/Core", "macOS/Core", "macOS/Persistence", "macOS/Repositories"]
restricted_tokens = ["displayDerivedTotalAscentMeters", "displayDerivedTotalDescentMeters", "displayDerived", "CompactRouteDisplay", "CompactSpeedSparkline", "CompactElevationProfile"]
for root in restricted_roots:
    restricted_hits.extend(scan_tokens(root, restricted_tokens, {".swift", ".json", ".md", ".txt"}))
print(f"COMPACT_OR_DISPLAY_DERIVED_PERSISTENCE_EXPORT_COUNT={len(restricted_hits)}")
if restricted_hits:
    for file, token in restricted_hits:
        print(f"FORBIDDEN_PERSISTENCE_EXPORT_TOKEN={file}::{token}")
    fail("compact/displayDerived tokens found in persistence/export/package paths")
else:
    pass_msg("compact/displayDerived tokens absent from persistence/export/package paths")

watch_hits = scan_tokens("watchOS", ["CompactRouteDisplay", "CompactSpeedSparkline", "CompactElevationProfile", "ActivityVisualizationPipeline", "ActivityVisualizationCompactSummary", "HKWorkoutSession", "startRecording"], {".swift"})
print(f"WATCH_UI_RECORDING_COMPACT_USAGE_COUNT={len(watch_hits)}")
if watch_hits:
    for file, token in watch_hits:
        print(f"WATCH_FORBIDDEN_TOKEN={file}::{token}")
    fail("watchOS has Watch UI/recording/compact consumption tokens")
else:
    pass_msg("watchOS has no Watch UI/recording/compact consumption changes")

final_doc_tokens = [
    "Task-031-prep-ActivityViz-016 Final Parity Gate", "Final Parity Gate",
    "verify_task031_prep_016_final_parity_gate.py", "ActivityViz-003 through ActivityViz-015 verifier family",
    "Shared decides visualization data semantics; platforms decide rendering",
    "display-only compact summaries", "no Watch UI", "no Watch recording", "no persistence/export/package schema change",
    "Task-031-prep closure gate",
]
for token in final_doc_tokens:
    require_token("docs/history/DEV_LOG.md", dev_log, token)
for token in [
    "Task-031-prep ActivityViz-016 Final Parity Gate", "scripts/verify_task031_prep_016_final_parity_gate.py",
    "final parity verifier", "ActivityViz-003 through ActivityViz-015 verifier family",
    "display-only compact summaries", "Task-031-prep closure gate",
]:
    require_token("docs/reference/FILE_STRUCTURE.md", file_structure, token)
for token in [
    "Task-031-prep final parity gate and closure decision", "Shared decides visualization data semantics; platforms decide rendering",
    "verify_task031_prep_016_final_parity_gate.py", "ActivityVisualizationResult", "ActivityVisualizationCompactSummary",
    "CompactRouteDisplay", "CompactSpeedSparkline", "CompactElevationProfile", "no Watch UI", "no Watch recording",
    "no persistence/export/package schema mutation",
]:
    require_token("docs/adr/ADR-INDEX.md", adr_index, token)
for token in [
    "Task-031-prep Activity Visualization Final Parity Gate Boundary", "Task-031-prep closure gate",
    "Shared decides visualization data semantics; platforms decide rendering", "display-only compact summaries",
    "no Watch UI", "no Watch recording", "no persistence/export/package schema change", "no trusted metric mutation",
]:
    require_token("docs/release/KNOWN_LIMITATIONS_PRE_ADP.md", known_limitations, token)
for token in [
    "Task-031-prep ActivityViz-016 final parity gate verifier", "PROJECT_SOURCE_PHASE_COUNT", "PROJECT_TEST_SOURCE_PHASE_COUNT",
    "COMPACT_OR_DISPLAY_DERIVED_PERSISTENCE_EXPORT_COUNT", "WATCH_UI_RECORDING_COMPACT_USAGE_COUNT",
    "VERIFY_TASK031_PREP_016_FINAL_PARITY_GATE_RESULT",
]:
    require_token("scripts/verify_task031_prep_016_final_parity_gate.py", verifier_text, token)

for label, text in [
    ("DEV_LOG.md", dev_log), ("FILE_STRUCTURE.md", file_structure), ("ADR-INDEX.md", adr_index),
    ("KNOWN_LIMITATIONS_PRE_ADP.md", known_limitations),
]:
    for token in [
        "ActivityViz-016 implemented Watch UI", "ActivityViz-016 implemented Watch recording",
        "ActivityViz-016 changed persistence schema", "ActivityViz-016 mutated trusted metrics",
    ]:
        forbid_token(label, text, token)

print("===== Summary =====")
print(f"WARNING_COUNT={warnings}")
print(f"FAILURE_COUNT={failures}")
if failures == 0:
    print("VERIFY_TASK031_PREP_016_FINAL_PARITY_GATE_RESULT=PASSED")
    sys.exit(0)
print("VERIFY_TASK031_PREP_016_FINAL_PARITY_GATE_RESULT=FAILED")
sys.exit(1)
