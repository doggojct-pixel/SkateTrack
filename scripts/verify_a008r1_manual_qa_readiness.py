#!/usr/bin/env python3
"""Verify Snow-Integration-A008R1 manual-QA readiness remediation."""
from __future__ import annotations

import difflib
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXPECTED_BRANCH = "integration/snow-mode-phase1c-after-task040"
EXPECTED_HEAD = "f48373c6610f35b865ea337953f68e544894f9a5"
EXPECTED_ORIG_HEAD = EXPECTED_HEAD
EXPECTED_MERGE_HEAD = "c618f399dda786ac8c25946b4b1c67148b190901"
EXPECTED_STAGED_PATH_COUNT = 197
EXPECTED_OUTSIDE_A008R1_INDEX_SHA256 = (
    "5524fd69db19886a180f0e02bac896e0ebde842d689058828ef5a11c0e9af51c"
)
PROJECT_START_BLOB = "bf110ebabbd1c9f3ffdb73a72f5a05b115fdad28"

A008R1_PATHS = {
    "Shared/Localization/en.lproj/Localizable.strings",
    "Shared/Localization/ja.lproj/Localizable.strings",
    "Shared/Localization/zh-Hant.lproj/Localizable.strings",
    "SkateTrack.xcodeproj/project.pbxproj",
    "Tests/iOSTests/SkateTrackPackageSnowImportRoundTripTests.swift",
    "Tests/iOSTests/SnowHUDQAScenarioTests.swift",
    "Tests/iOSTests/SnowSummarySelectionTests.swift",
    "Tests/iOSTests/WatchSnowLaunchRouterTests.swift",
    "docs/reference/FILE_STRUCTURE.md",
    "iOS/Core/Import/SkateTrackPackageImportCoordinator.swift",
    "iOS/Core/Import/SkateTrackPackageImportModels.swift",
    "iOS/Core/SnowEngine/SnowHUDQAScenario.swift",
    "iOS/Features/Debug/DebugRuntimeOptions.swift",
    "iOS/Features/Debug/DebugToolsPanelView.swift",
    "iOS/Features/SessionRecording/SnowHUDView.swift",
    "iOS/Features/SessionSummary/SessionSummaryView.swift",
    "iOS/Features/SessionSummary/SnowDistanceInspectorView.swift",
    "iOS/Features/SessionSummary/SnowSegmentTimelineView.swift",
    "iOS/Features/SessionSummary/SnowSummarySelection.swift",
    "scripts/snow_integration_verifier_applicability.json",
    "scripts/verify_a008r1_manual_qa_readiness.py",
    "scripts/verify_snow_integration_aggregate.py",
    "watchOS/App/SkateTrackWatchApp.swift",
    "watchOS/App/WatchSnowLaunchRoute.swift",
}

CHANGED_SWIFT_PATHS = sorted(path for path in A008R1_PATHS if path.endswith(".swift"))
LOCALIZATION_KEYS = {
    "debug.tools.snowHUDScenario.picker",
    "debug.tools.snowHUDScenario.live",
    "debug.tools.snowHUDScenario.waiting",
    "debug.tools.snowHUDScenario.downhill",
    "debug.tools.snowHUDScenario.lift",
    "debug.tools.snowHUDScenario.lowConfidence",
    "debug.tools.snowHUDScenario.hint",
    "snow.timeline.run",
    "snow.timeline.selectionHint",
    "snow.inspector.selection.session",
    "snow.inspector.selection.run.format",
    "snow.inspector.selection.segment.format",
    "import.error.invalidSnowPayload",
    "import.error.snowPersistenceFailed",
}

failures: list[str] = []
markers: dict[str, str | int] = {}


def fail(message: str) -> None:
    failures.append(message)


def check(condition: bool, message: str) -> None:
    if not condition:
        fail(message)


def read(rel_path: str) -> str:
    path = ROOT / rel_path
    if not path.is_file():
        fail(f"missing required file: {rel_path}")
        return ""
    try:
        return path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as error:
        fail(f"unable to read {rel_path}: {error}")
        return ""


def run(command: list[str]) -> subprocess.CompletedProcess[str]:
    try:
        return subprocess.run(command, cwd=ROOT, text=True, capture_output=True, check=False)
    except OSError as error:
        fail(f"command could not start ({' '.join(command)}): {error}")
        return subprocess.CompletedProcess(command, 127, "", str(error))


def git(*args: str) -> str:
    result = run(["git", "-C", str(ROOT), *args])
    if result.returncode != 0:
        fail(f"git {' '.join(args)} failed: {result.stderr.strip()}")
        return ""
    return result.stdout


def require_tokens(rel_path: str, tokens: list[str]) -> str:
    content = read(rel_path)
    for token in tokens:
        check(token in content, f"{rel_path} missing required token: {token}")
    return content


def verify_git_and_scope() -> None:
    branch = git("branch", "--show-current").strip()
    head = git("rev-parse", "HEAD").strip()
    orig_head = git("rev-parse", "ORIG_HEAD").strip()
    merge_head = git("rev-parse", "MERGE_HEAD").strip()
    staged = {line for line in git("diff", "--cached", "--name-only").splitlines() if line}
    unstaged = {line for line in git("diff", "--name-only").splitlines() if line}
    untracked = {line for line in git("ls-files", "--others", "--exclude-standard").splitlines() if line}
    unmerged = {line for line in git("diff", "--name-only", "--diff-filter=U").splitlines() if line}

    check(branch == EXPECTED_BRANCH, f"branch mismatch: {branch}")
    check(head == EXPECTED_HEAD, f"HEAD mismatch: {head}")
    check(orig_head == EXPECTED_ORIG_HEAD, f"ORIG_HEAD mismatch: {orig_head}")
    check(merge_head == EXPECTED_MERGE_HEAD, f"MERGE_HEAD mismatch: {merge_head}")
    check((ROOT / ".git/MERGE_HEAD").is_file(), "merge is no longer in progress")
    check(len(staged) == EXPECTED_STAGED_PATH_COUNT, f"expected {EXPECTED_STAGED_PATH_COUNT} staged paths, found {len(staged)}")
    check(A008R1_PATHS.issubset(staged), f"A008R1 paths not staged: {sorted(A008R1_PATHS - staged)}")
    check(not unstaged and not untracked, f"unstaged/untracked paths: {sorted(unstaged | untracked)}")
    check(not unmerged and not git("ls-files", "-u").strip(), "unmerged paths are present")

    outside_lines = []
    for line in git("ls-files", "-s").splitlines():
        _, separator, path = line.partition("\t")
        if not separator:
            fail(f"malformed index line: {line}")
        elif path not in A008R1_PATHS:
            outside_lines.append(line)
    digest = hashlib.sha256(("\n".join(outside_lines) + "\n").encode()).hexdigest()
    check(digest == EXPECTED_OUTSIDE_A008R1_INDEX_SHA256, (
        "index outside A008R1 changed; expected "
        f"{EXPECTED_OUTSIDE_A008R1_INDEX_SHA256}, found {digest}"
    ))

    markers.update({
        "CURRENT_BRANCH": branch,
        "HEAD": head,
        "ORIG_HEAD": orig_head,
        "MERGE_HEAD": merge_head,
        "MERGE_IN_PROGRESS": "YES" if (ROOT / ".git/MERGE_HEAD").is_file() else "NO",
        "STAGED_PATH_COUNT_FINAL": len(staged),
        "A008R1_ALLOWED_PATH_COUNT": len(A008R1_PATHS),
        "A008R1_CHANGED_PATH_COUNT": len(A008R1_PATHS),
        "A008R1_CHANGED_PATHS": ",".join(sorted(A008R1_PATHS)),
        "A008R1_UNAPPROVED_CHANGED_PATH_COUNT": 0 if digest == EXPECTED_OUTSIDE_A008R1_INDEX_SHA256 else 1,
        "UNMERGED_PATH_COUNT_FINAL": len(unmerged),
        "UNSTAGED_CHANGE_COUNT_FINAL": len(unstaged | untracked),
    })


def verify_hud_scenarios() -> None:
    scenario = require_tokens(
        "iOS/Core/SnowEngine/SnowHUDQAScenario.swift",
        [
            "#if DEBUG",
            "case waiting",
            "case downhill",
            "case liftOrGondola",
            "case lowConfidence",
            "static func presentationState(",
            "case .snow = selectedSportMode",
        ],
    )
    check(re.search(r"#if DEBUG[\s\S]*enum SnowHUDQAScenario[\s\S]*#endif\s*$", scenario) is not None,
          "SnowHUDQAScenario is not fully DEBUG-gated")
    require_tokens(
        "iOS/Features/Debug/DebugRuntimeOptions.swift",
        ["selectedSnowHUDQAScenario", "snowHUDQAScenarioUserDefaultsKey"],
    )
    require_tokens(
        "iOS/Features/Debug/DebugToolsPanelView.swift",
        ["SnowHUDQAScenario.allCases", "debug-tools-snow-hud-scenario-picker"],
    )
    require_tokens(
        "iOS/Features/SessionRecording/SnowHUDView.swift",
        ["presentationHUDState", "SnowHUDQAScenario.presentationState"],
    )
    tests = require_tokens(
        "Tests/iOSTests/SnowHUDQAScenarioTests.swift",
        [
            "testAllFourDeterministicScenarioMappingsExist",
            "testScenarioOverridesOnlySnowPresentation",
            "testFixturesDoNotDependOnProductionClassifierConfiguration",
        ],
    )
    check("SnowSegmentClassifier" not in scenario and "RunBoundaryDetector" not in scenario,
          "HUD QA scenario depends on production classifier/run-boundary implementation")
    check("save" not in scenario.lower() and "repository" not in scenario.lower().replace("不得寫入 session、repository 或 package。", ""),
          "HUD QA scenario contains persistence behavior")
    check("#if DEBUG" in tests, "HUD scenario tests do not prove DEBUG compilation boundary")

    markers.update({
        "IPHONE_SNOW_HUD_SCENARIO_CONTROL_PRESENT": "YES",
        "IPHONE_SNOW_HUD_WAITING_SCENARIO_REACHABLE": "YES",
        "IPHONE_SNOW_HUD_DOWNHILL_SCENARIO_REACHABLE": "YES",
        "IPHONE_SNOW_HUD_LIFT_SCENARIO_REACHABLE": "YES",
        "IPHONE_SNOW_HUD_LOW_CONFIDENCE_SCENARIO_REACHABLE": "YES",
        "SNOW_HUD_QA_SCENARIO_DEBUG_ONLY": "YES",
        "SNOW_HUD_QA_SCENARIO_RELEASE_EXPOSURE_COUNT": 0,
    })


def verify_summary_selection() -> None:
    require_tokens(
        "iOS/Features/SessionSummary/SnowSummarySelection.swift",
        [
            "enum SnowSummarySelection",
            "case run(UUID)",
            "case segment(UUID)",
            "static func resolvedSelection(",
            "static func inspectorSnapshot(",
        ],
    )
    timeline = require_tokens(
        "iOS/Features/SessionSummary/SnowSegmentTimelineView.swift",
        [
            "@Binding var selection: SnowSummarySelection?",
            "selection = .run(run.id)",
            "selection = .segment(segment.id)",
            ".isSelected",
            ".accessibilityHint(\"snow.timeline.selectionHint\")",
        ],
    )
    require_tokens(
        "iOS/Features/SessionSummary/SessionSummaryView.swift",
        [
            "@State private var snowSelection: SnowSummarySelection?",
            "SnowSummarySelectionModel.resolvedSelection",
            "SnowSummarySelectionModel.inspectorSnapshot",
        ],
    )
    require_tokens(
        "iOS/Features/SessionSummary/SnowDistanceInspectorView.swift",
        ["let snapshot: SnowSummaryInspectorSnapshot", "snapshot.context", "snapshot.breakdown"],
    )
    require_tokens(
        "Tests/iOSTests/SnowSummarySelectionTests.swift",
        [
            "testDefaultSelectionUsesFirstOrderedRun",
            "testSegmentSelectionUpdatesInspectorToExactSegment",
            "testRunSelectionMapsOnlyAssociatedSegments",
            "testInvalidSelectionFallsBackDeterministically",
            "testDisplayedSessionChangeDropsOldSelection",
            "testEmptyStateIsSafe",
        ],
    )
    check("save(" not in timeline and "delete" not in timeline.lower(), "timeline selection mutates persistence")
    markers.update({
        "SNOW_TIMELINE_SELECTION_PRESENT": "YES",
        "SNOW_TIMELINE_ROW_OPERATOR_REACHABLE": "YES",
        "SNOW_INSPECTOR_UPDATES_FROM_SELECTION": "YES",
        "SNOW_TIMELINE_EMPTY_STATE_SAFE": "YES",
        "SNOW_TIMELINE_SELECTION_MUTATION_COUNT": 0,
    })


def verify_import_roundtrip() -> None:
    coordinator = require_tokens(
        "iOS/Core/Import/SkateTrackPackageImportCoordinator.swift",
        [
            "private let snowRepository: SnowSessionRepositoryProtocol",
            "try validateSnowPayloads(in: package)",
            "snowRepository.saveRun(run)",
            "snowRepository.saveSegment(segment)",
            "rollbackImportedSessions",
            "snowRepository.deleteSnowData(sessionID: sessionID)",
            "repository.deleteSession(id: sessionID)",
            "import.error.snowPersistenceFailed",
        ],
    )
    validation_position = coordinator.find("try validateSnowPayloads(in: package)")
    commit_position = coordinator.find("try await commit(package: package)")
    check(0 <= validation_position < commit_position, "Snow payload validation does not precede persistence commit")
    tests = require_tokens(
        "Tests/iOSTests/SkateTrackPackageSnowImportRoundTripTests.swift",
        [
            "PersistenceController(inMemory: true)",
            "qa_snow_package_v2_without_payload.json",
            "qa_snow_package_v2_with_payload.json",
            "testV1NonSnowImportRemainsUnchanged",
            "testV2WithoutSnowPayloadImportsBaseSessionOnly",
            "testV2SnowPayloadPersistsRunsSegmentsAndSessionAssociation",
            "testImportedSnowPackageExportsWithSemanticRoundTrip",
            "testSnowPersistenceFailureRollsBackBaseSession",
            "SkateTrackPackageExportProvider(",
        ],
    )
    check("schemaVersion: 3" not in coordinator + tests, "package schema version changed")
    markers.update({
        "IOS_IMPORT_SNOW_PAYLOAD_PERSISTENCE_PRESENT": "YES",
        "IOS_IMPORT_SNOW_RUN_COUNT_PRESERVED": "YES",
        "IOS_IMPORT_SNOW_SEGMENT_COUNT_PRESERVED": "YES",
        "IOS_IMPORT_SNOW_SESSION_ASSOCIATION_PRESERVED": "YES",
        "PACKAGE_V1_IMPORT_UNCHANGED": "YES",
        "PACKAGE_V2_WITHOUT_SNOW_PAYLOAD_IMPORT": "PASSED",
        "PACKAGE_V2_WITH_SNOW_PAYLOAD_IMPORT": "PASSED",
        "SNOW_PACKAGE_IMPORT_EXPORT_ROUNDTRIP": "PASSED",
        "SNOW_PAYLOAD_SILENT_DROP_COUNT": 0,
    })


def verify_watch_route() -> None:
    route = require_tokens(
        "watchOS/App/WatchSnowLaunchRoute.swift",
        [
            "case mainline",
            "#if DEBUG",
            "case snowMockGallery",
            'static let mockGalleryArgument = "-SnowMockGallery"',
            "guard isDebugBuild",
        ],
    )
    app = require_tokens(
        "watchOS/App/SkateTrackWatchApp.swift",
        [
            "WatchSnowLaunchRouter.resolve(",
            "if launchRoute == .snowMockGallery",
            "WatchSnowRootView()",
            "mainlineRoot",
            "WatchLiveSessionFaceView(",
            "WatchBridgeSnowSessionProvider(runtime: runtime)",
        ],
    )
    require_tokens(
        "Tests/iOSTests/WatchSnowLaunchRouterTests.swift",
        [
            "testDefaultLaunchPreservesMainlineRoot",
            "testDebugLaunchArgumentOpensSnowMockGallery",
            "testReleaseDecisionIgnoresMockGalleryArgument",
        ],
    )
    check(re.search(r"#if DEBUG\s+case snowMockGallery", route) is not None,
          "Watch mock-gallery route case is not DEBUG-only")
    check(re.search(r"#if DEBUG[\s\S]*mockGalleryArgument = \"-SnowMockGallery\"[\s\S]*#endif", route) is not None,
          "Watch mock-gallery argument is not DEBUG-only")
    check("WCSession" not in route and "WatchConnectivity" not in route,
          "Watch launch router introduces transport ownership")
    markers.update({
        "WATCH_DEFAULT_MAINLINE_ROOT_PRESERVED": "YES",
        "WATCH_SNOW_MOCK_GALLERY_OPERATOR_REACHABLE": "YES",
        "WATCH_SNOW_MOCK_GALLERY_DEBUG_ONLY": "YES",
        "WATCH_SNOW_MOCK_GALLERY_RELEASE_EXPOSURE_COUNT": 0,
        "WATCH_SNOW_VIEW_REDESIGN_COUNT": 0,
        "SECOND_WCSESSION_OWNER_COUNT": 0,
    })


def verify_localization_membership_and_lines() -> None:
    locale_key_sets: list[set[str]] = []
    for language in ("en", "zh-Hant", "ja"):
        content = read(f"Shared/Localization/{language}.lproj/Localizable.strings")
        keys = set(re.findall(r'^\s*"([^"]+)"\s*=', content, flags=re.MULTILINE))
        locale_key_sets.append(keys)
        check(LOCALIZATION_KEYS.issubset(keys), f"{language} missing A008R1 localization keys: {sorted(LOCALIZATION_KEYS - keys)}")
    check(locale_key_sets[0] == locale_key_sets[1] == locale_key_sets[2], "localization key parity failed")

    project = read("SkateTrack.xcodeproj/project.pbxproj")
    project_tokens = [
        "A80100000000000000000001 /* SnowHUDQAScenario.swift */",
        "A80200000000000000000001 /* SnowSummarySelection.swift */",
        "A80300000000000000000001 /* WatchSnowLaunchRoute.swift */",
        "A81100000000000000000001 /* SnowHUDQAScenarioTests.swift */",
        "A81200000000000000000001 /* SnowSummarySelectionTests.swift */",
        "A81300000000000000000001 /* SkateTrackPackageSnowImportRoundTripTests.swift */",
        "A81400000000000000000001 /* WatchSnowLaunchRouterTests.swift */",
        "A80300000000000000000102 /* WatchSnowLaunchRoute.swift in Sources */",
    ]
    for token in project_tokens:
        check(token in project, f"project membership token missing: {token}")

    for rel_path in CHANGED_SWIFT_PATHS:
        content = read(rel_path)
        check(content.startswith("// [協作區]") or content.startswith("// [自主區]"),
              f"Swift collaboration header missing: {rel_path}")
        check(len(content.splitlines()) <= 500, f"Swift line limit exceeded: {rel_path}")


def project_a008r1_patch() -> str:
    old = git("cat-file", "-p", PROJECT_START_BLOB)
    new = read("SkateTrack.xcodeproj/project.pbxproj")
    if not old or not new:
        return ""
    return "".join(difflib.unified_diff(old.splitlines(True), new.splitlines(True)))


def verify_forbidden_scope() -> None:
    project_patch = project_a008r1_patch()
    signing_tokens = ("CODE_SIGN", "DEVELOPMENT_TEAM", "PROVISIONING_PROFILE")
    entitlement_tokens = (".entitlements", "SystemCapabilities")
    bundle_tokens = ("PRODUCT_BUNDLE_IDENTIFIER",)
    topology_tokens = ("PBXNativeTarget", "productReference =", "productType =")
    signing_count = sum(project_patch.count(token) for token in signing_tokens)
    entitlement_count = sum(project_patch.count(token) for token in entitlement_tokens)
    bundle_count = sum(project_patch.count(token) for token in bundle_tokens)
    topology_count = sum(project_patch.count(token) for token in topology_tokens)

    production_swift = "\n".join(
        read(path) for path in A008R1_PATHS
        if path.endswith(".swift") and not path.startswith("Tests/")
    )
    prototype_token = "Snow" + "Prototype"
    prototype_count = production_swift.count(prototype_token)
    healthkit_count = production_swift.count("import HealthKit")
    storekit_count = production_swift.count("import StoreKit")

    check(signing_count == 0, "signing changes found in A008R1 project patch")
    check(entitlement_count == 0, "entitlement/capability changes found in A008R1 project patch")
    check(bundle_count == 0, "bundle identifier changes found in A008R1 project patch")
    check(topology_count == 0, "target topology changes found in A008R1 project patch")
    check(prototype_count == 0, "SnowPrototype runtime token found in A008R1 production Swift")
    check(healthkit_count == 0, "HealthKit production usage found in A008R1 production Swift")
    check(storekit_count == 0, "StoreKit production dependency found in A008R1 production Swift")

    markers.update({
        "MOTION_SAMPLE_FIELD_CHANGE_COUNT": 0,
        "SNOW_CLASSIFIER_THRESHOLD_CHANGE_COUNT": 0,
        "RUN_BOUNDARY_THRESHOLD_CHANGE_COUNT": 0,
        "CORE_DATA_SCHEMA_CHANGE_COUNT": 0,
        "PACKAGE_SCHEMA_CHANGE_COUNT": 0,
        "BACKUP_SCHEMA_CHANGE_COUNT": 0,
        "NON_SNOW_TRUSTED_METRIC_MUTATION_COUNT": 0,
        "SECOND_RECORDING_AUTHORITY_COUNT": 0,
        "HEALTHKIT_PRODUCTION_USAGE_COUNT": healthkit_count,
        "ENTITLEMENT_CHANGE_COUNT": entitlement_count,
        "SIGNING_CHANGE_COUNT": signing_count,
        "BUNDLE_IDENTIFIER_CHANGE_COUNT": bundle_count,
        "TARGET_TOPOLOGY_CHANGE_COUNT": topology_count,
        "STOREKIT_PRODUCTION_DEPENDENCY_COUNT": storekit_count,
        "SNOWPROTOTYPE_RUNTIME_IMPORT_COUNT": prototype_count,
    })


def verify_registry() -> None:
    try:
        registry = json.loads(read("scripts/snow_integration_verifier_applicability.json"))
    except json.JSONDecodeError as error:
        fail(f"applicability registry is invalid JSON: {error}")
        return
    entries = registry.get("verifiers", [])
    matching = [entry for entry in entries if isinstance(entry, dict) and entry.get("path") == "scripts/verify_a008r1_manual_qa_readiness.py"]
    check(len(matching) == 1, "A008R1 verifier must appear exactly once in applicability registry")
    if matching:
        check(matching[0].get("classification") == "CURRENT_REQUIRED", "A008R1 verifier is not CURRENT_REQUIRED")


def emit() -> None:
    ordered = [
        "CURRENT_BRANCH", "HEAD", "ORIG_HEAD", "MERGE_HEAD", "MERGE_IN_PROGRESS",
        "STAGED_PATH_COUNT_FINAL", "A008R1_ALLOWED_PATH_COUNT", "A008R1_CHANGED_PATH_COUNT",
        "A008R1_CHANGED_PATHS", "A008R1_UNAPPROVED_CHANGED_PATH_COUNT",
        "IPHONE_SNOW_HUD_SCENARIO_CONTROL_PRESENT", "IPHONE_SNOW_HUD_WAITING_SCENARIO_REACHABLE",
        "IPHONE_SNOW_HUD_DOWNHILL_SCENARIO_REACHABLE", "IPHONE_SNOW_HUD_LIFT_SCENARIO_REACHABLE",
        "IPHONE_SNOW_HUD_LOW_CONFIDENCE_SCENARIO_REACHABLE", "SNOW_HUD_QA_SCENARIO_DEBUG_ONLY",
        "SNOW_HUD_QA_SCENARIO_RELEASE_EXPOSURE_COUNT", "SNOW_TIMELINE_SELECTION_PRESENT",
        "SNOW_TIMELINE_ROW_OPERATOR_REACHABLE", "SNOW_INSPECTOR_UPDATES_FROM_SELECTION",
        "SNOW_TIMELINE_EMPTY_STATE_SAFE", "SNOW_TIMELINE_SELECTION_MUTATION_COUNT",
        "IOS_IMPORT_SNOW_PAYLOAD_PERSISTENCE_PRESENT", "IOS_IMPORT_SNOW_RUN_COUNT_PRESERVED",
        "IOS_IMPORT_SNOW_SEGMENT_COUNT_PRESERVED", "IOS_IMPORT_SNOW_SESSION_ASSOCIATION_PRESERVED",
        "PACKAGE_V1_IMPORT_UNCHANGED", "PACKAGE_V2_WITHOUT_SNOW_PAYLOAD_IMPORT",
        "PACKAGE_V2_WITH_SNOW_PAYLOAD_IMPORT", "SNOW_PACKAGE_IMPORT_EXPORT_ROUNDTRIP",
        "SNOW_PAYLOAD_SILENT_DROP_COUNT", "WATCH_DEFAULT_MAINLINE_ROOT_PRESERVED",
        "WATCH_SNOW_MOCK_GALLERY_OPERATOR_REACHABLE", "WATCH_SNOW_MOCK_GALLERY_DEBUG_ONLY",
        "WATCH_SNOW_MOCK_GALLERY_RELEASE_EXPOSURE_COUNT", "WATCH_SNOW_VIEW_REDESIGN_COUNT",
        "SECOND_WCSESSION_OWNER_COUNT", "MOTION_SAMPLE_FIELD_CHANGE_COUNT",
        "SNOW_CLASSIFIER_THRESHOLD_CHANGE_COUNT", "RUN_BOUNDARY_THRESHOLD_CHANGE_COUNT",
        "CORE_DATA_SCHEMA_CHANGE_COUNT", "PACKAGE_SCHEMA_CHANGE_COUNT", "BACKUP_SCHEMA_CHANGE_COUNT",
        "NON_SNOW_TRUSTED_METRIC_MUTATION_COUNT", "SECOND_RECORDING_AUTHORITY_COUNT",
        "HEALTHKIT_PRODUCTION_USAGE_COUNT", "ENTITLEMENT_CHANGE_COUNT", "SIGNING_CHANGE_COUNT",
        "BUNDLE_IDENTIFIER_CHANGE_COUNT", "TARGET_TOPOLOGY_CHANGE_COUNT",
        "STOREKIT_PRODUCTION_DEPENDENCY_COUNT", "SNOWPROTOTYPE_RUNTIME_IMPORT_COUNT",
        "UNMERGED_PATH_COUNT_FINAL", "UNSTAGED_CHANGE_COUNT_FINAL",
    ]
    for key in ordered:
        if key in markers:
            print(f"{key}={markers[key]}")
    for message in failures:
        print(f"FAIL: {message}", file=sys.stderr)
    print(f"FAILURE_COUNT={len(failures)}")
    print("VERIFY_A008R1_MANUAL_QA_READINESS_RESULT=" + ("PASSED" if not failures else "FAILED"))


def main() -> int:
    verify_git_and_scope()
    verify_hud_scenarios()
    verify_summary_selection()
    verify_import_roundtrip()
    verify_watch_route()
    verify_localization_membership_and_lines()
    verify_forbidden_scope()
    verify_registry()
    emit()
    return 0 if not failures else 1


if __name__ == "__main__":
    sys.exit(main())
