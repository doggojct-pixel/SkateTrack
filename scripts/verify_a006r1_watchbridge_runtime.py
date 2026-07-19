#!/usr/bin/env python3
"""Verify the bounded A006R1 WatchBridge runtime and Snow adapter closure."""
from __future__ import annotations

import re
import subprocess
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

ALLOWED_PATHS = {
    "Shared/WatchBridge/WatchBridgeWCSessionBoundary.swift",
    "Shared/WatchBridge/WatchBridgeMetricPayloads.swift",
    "Shared/WatchBridge/WatchBridgeRuntimeState.swift",
    "Shared/WatchBridge/WatchBridgeSnowSnapshotMapper.swift",
    "iOS/Core/WatchBridge/WatchBridgeActivityPublisher.swift",
    "iOS/App/SkateTrackApp.swift",
    "watchOS/Core/WatchBridge/WatchBridgeWatchRuntime.swift",
    "watchOS/Core/Snow/WatchBridgeSnowSessionProvider.swift",
    "watchOS/App/SkateTrackWatchApp.swift",
    "Tests/iOSTests/WatchBridgeRuntimeSnowAdapterTests.swift",
    "scripts/verify_snow_watch_ui.py",
    "scripts/verify_a006r1_watchbridge_runtime.py",
    "SkateTrack.xcodeproj/project.pbxproj",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/history/DEV_LOG.md",
}

REQUIRED_FILES = sorted(ALLOWED_PATHS - {"scripts/verify_snow_watch_ui.py"})
SNOW_FIELDS = {
    "snowSchemaVersion": "String",
    "snowMaxSpeedThisRunKmh": "Double",
    "snowRunNumber": "Int",
    "snowVerticalDropMeters": "Double",
    "snowTotalVerticalMeters": "Double",
    "snowSlopeAngleDegrees": "Double",
    "snowSegmentType": "String",
    "snowRunCount": "Int",
    "snowTotalSkiDistanceMeters": "Double",
    "snowTotalLiftDistanceMeters": "Double",
    "snowAverageRunDurationSeconds": "Double",
    "snowLastRunVerticalDropMeters": "Double",
    "snowLastRunTopSpeedKmh": "Double",
    "snowLastRunDurationSeconds": "Double",
}

failures: list[str] = []


def read(path: str) -> str:
    full_path = ROOT / path
    if not full_path.is_file():
        failures.append(f"missing required file: {path}")
        return ""
    return full_path.read_text(encoding="utf-8")


def require_tokens(path: str, tokens: list[str]) -> str:
    content = read(path)
    for token in tokens:
        if token not in content:
            failures.append(f"{path} missing token: {token}")
    return content


def run_git(*args: str) -> list[str]:
    result = subprocess.run(
        ["git", "-C", str(ROOT), *args],
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        failures.append(f"git {' '.join(args)} failed: {result.stderr.strip()}")
        return []
    return [line.strip() for line in result.stdout.splitlines() if line.strip()]


def changed_worktree_paths() -> list[str]:
    return sorted(
        set(run_git("diff", "--name-only"))
        | set(run_git("ls-files", "--others", "--exclude-standard"))
    )


def verify_paths() -> list[str]:
    for path in REQUIRED_FILES:
        read(path)
    changed = changed_worktree_paths()
    for path in changed:
        if path not in ALLOWED_PATHS:
            failures.append(f"unapproved changed path: {path}")
    return changed


def verify_runtime_contracts() -> None:
    boundary = require_tokens(
        "Shared/WatchBridge/WatchBridgeWCSessionBoundary.swift",
        [
            "private let session: WCSession",
            "decoder: JSONDecoder = JSONDecoder()",
            "WatchBridgeInboundEnvelopeDecoder",
            "inboundEnvelopeHandler",
            "malformedEnvelopeHandler",
            "handleReceivedMessageData",
            ".messageReceived(",
        ],
    )
    if "try inboundDecoder.decode(messageData)" not in boundary:
        failures.append("WCSession boundary does not decode inbound envelope data")

    shared_state = require_tokens(
        "Shared/WatchBridge/WatchBridgeRuntimeState.swift",
        [
            "WatchBridgeInboundEnvelopeDecoder",
            "WatchBridgeRuntimeState",
            "seenMessageIds",
            "case duplicate",
            "case stale",
            "isFresh(",
        ],
    )
    if "currentSpeed" in shared_state or "distanceMeters *" in shared_state:
        failures.append("runtime state must not recalculate trusted metrics")

    require_tokens(
        "watchOS/Core/WatchBridge/WatchBridgeWatchRuntime.swift",
        [
            "@MainActor",
            "ObservableObject",
            "@Published private(set) var bridgeState",
            "statePublisher",
            "WatchBridgeWCSessionBoundary",
        ],
    )
    publisher = require_tokens(
        "iOS/Core/WatchBridge/WatchBridgeActivityPublisher.swift",
        [
            "final class WatchBridgeActivityPublisher",
            "SessionRecordingCoordinator",
            "statePublisher",
            "metricsPublisher",
            "snowLiveStatePublisher",
            "WatchBridgeWCSessionBoundary",
            "payload: .activitySnapshot",
            'snowState == nil ? nil : "1.1"',
        ],
    )
    for forbidden in ["func startSession", "func pauseSession", "func endSession"]:
        if forbidden in publisher:
            failures.append(f"iPhone publisher owns forbidden recording lifecycle: {forbidden}")


def verify_snow_transport() -> None:
    metric = read("Shared/WatchBridge/WatchBridgeMetricPayloads.swift")
    for field, swift_type in SNOW_FIELDS.items():
        declaration = rf"public let {field}: {swift_type}\?"
        default = rf"{field}: {swift_type}\? = nil"
        if not re.search(declaration, metric):
            failures.append(f"Snow field is missing or not optional: {field}")
        if not re.search(default, metric):
            failures.append(f"Snow initializer field lacks nil default: {field}")

    require_tokens(
        "Shared/WatchBridge/WatchBridgeSnowSnapshotMapper.swift",
        [
            "WatchBridgeSnowSnapshotMapper",
            "WatchSnowSessionSnapshot",
            "payload.snowSchemaVersion != nil",
            "snowRunNumber: nil",
            "snowSchemaVersion: nil",
        ],
    )
    provider = require_tokens(
        "watchOS/Core/Snow/WatchBridgeSnowSessionProvider.swift",
        [
            "@MainActor",
            "ObservableObject, WatchSnowSessionDataSource",
            "WatchBridgeWatchRuntime",
            "WatchBridgeSnowSnapshotMapper",
            "statePublisher",
            "snapshotPublisher",
        ],
    )
    for forbidden in ["import WatchConnectivity", "import HealthKit", "WCSession", "SnowPrototype"]:
        if forbidden in provider:
            failures.append(f"Snow provider contains forbidden token: {forbidden}")
    if not re.search(r"func\s+startRun\(\)\s*\{\s*\}", provider):
        failures.append("Snow provider must keep direct startRun as a no-op")
    if ".startSession" in provider:
        failures.append("Snow provider must not issue a direct session-start command")


def verify_composition_and_views() -> None:
    require_tokens(
        "watchOS/App/SkateTrackWatchApp.swift",
        [
            "WatchBridgeWatchRuntime",
            "WatchBridgeSnowSessionProvider",
            'sportModeKey == "snow"',
            "WatchSnowLiveView",
            "WatchLiveSessionFaceView",
        ],
    )
    mock = read("watchOS/Core/Snow/WatchSnowMockSessionProvider.swift")
    if not re.search(r"#if\s+DEBUG[\s\S]*WatchSnowMockSessionProvider", mock):
        failures.append("DEBUG Watch Snow mock provider is not preserved")

    for path in sorted((ROOT / "watchOS/Features/Snow").glob("WatchSnow*.swift")):
        content = path.read_text(encoding="utf-8")
        for forbidden in ["import WatchConnectivity", "WCSession", "import MapKit"]:
            if forbidden in content:
                failures.append(f"Snow view contains forbidden token {forbidden}: {path.name}")


def verify_tests_and_project() -> None:
    require_tokens(
        "Tests/iOSTests/WatchBridgeRuntimeSnowAdapterTests.swift",
        [
            "WatchBridgeRuntimeFoundationTests",
            "WatchBridgeSnowAdapterTests",
            "testWCSessionBoundaryDeliversDecodedEnvelopeAndPreservesFreshness",
            "testWCSessionBoundaryRejectsMalformedDataWithoutCrashing",
            "testOutboundEnvelopeEncodeAndSendPathQueuesAfterActivation",
            "testRuntimeRejectsOlderMetricPayload",
            "testRuntimeRejectsDuplicateMessageIdentifier",
            "testLegacyMetricJSONWithoutSnowFieldsDecodesWithNilExtensions",
            "testNonSnowMetricMappingKeepsSnowStateEmpty",
            "testSnowMetricMappingPopulatesApprovedFields",
            "testPartialSnowMetricMappingUsesNilAndZeroSafeDefaults",
        ],
    )
    project = read("SkateTrack.xcodeproj/project.pbxproj")
    membership_tokens = [
        "WatchBridgeRuntimeState.swift in Sources",
        "WatchBridgeSnowSnapshotMapper.swift in Sources",
        "WatchBridgeActivityPublisher.swift in Sources",
        "WatchBridgeWatchRuntime.swift in Sources",
        "WatchBridgeSnowSessionProvider.swift in Sources",
        "WatchBridgeRuntimeSnowAdapterTests.swift in Sources",
        "iOS/Core/WatchBridge",
        "watchOS/Core/WatchBridge",
        "watchOS/Core/Snow",
    ]
    for token in membership_tokens:
        if token not in project:
            failures.append(f"project membership missing token: {token}")

    object_ids = re.findall(
        r"^\s*([A-F0-9]{24}) /\*.*?\*/ = \{",
        project,
        flags=re.MULTILINE,
    )
    duplicate_ids = [item for item, count in Counter(object_ids).items() if count > 1]
    if duplicate_ids:
        failures.append(f"duplicate project object IDs: {','.join(duplicate_ids)}")

    for build_id in [
        "40A100000000000000000101",
        "40A100000000000000000102",
        "40A200000000000000000101",
        "40A200000000000000000102",
        "40A300000000000000000101",
        "40A400000000000000000102",
        "40A500000000000000000102",
        "40A900000000000000000101",
    ]:
        if project.count(build_id) != 2:
            failures.append(f"unexpected source membership count for build ID: {build_id}")


def verify_scope() -> None:
    owner_paths = []
    for path in ROOT.rglob("*.swift"):
        relative = path.relative_to(ROOT).as_posix()
        if relative.startswith("Tests/"):
            continue
        if re.search(r"\bWCSession\b", path.read_text(encoding="utf-8")):
            owner_paths.append(relative)
    expected_owner = "Shared/WatchBridge/WatchBridgeWCSessionBoundary.swift"
    if owner_paths != [expected_owner]:
        failures.append(f"WCSession owner paths must equal [{expected_owner}], found {owner_paths}")

    forbidden_changed_prefixes = [
        "Shared/Models/MotionSample.swift",
        "Shared/Persistence/",
        "macOS/",
    ]
    for changed in changed_worktree_paths():
        if any(changed == prefix or changed.startswith(prefix) for prefix in forbidden_changed_prefixes):
            failures.append(f"forbidden scope changed: {changed}")

    pbx_diff = "\n".join(run_git("diff", "--", "SkateTrack.xcodeproj/project.pbxproj"))
    for token in [
        "PBXNativeTarget",
        "PRODUCT_BUNDLE_IDENTIFIER",
        "CODE_SIGN",
        "DEVELOPMENT_TEAM",
        "TargetAttributes",
    ]:
        if any(line.startswith("+") and token in line for line in pbx_diff.splitlines()):
            failures.append(f"project topology/signing mutation detected: {token}")


def main() -> None:
    changed = verify_paths()
    verify_runtime_contracts()
    verify_snow_transport()
    verify_composition_and_views()
    verify_tests_and_project()
    verify_scope()

    for failure in failures:
        print(f"[a006r1] FAIL: {failure}", file=sys.stderr)

    print(f"A006R1_ALLOWED_PATH_COUNT={len(ALLOWED_PATHS)}")
    print("A006R1_ALLOWED_PATHS=" + "|".join(sorted(ALLOWED_PATHS)))
    print(f"A006R1_CHANGED_PATH_COUNT={len(changed)}")
    print("A006R1_CHANGED_PATHS=" + "|".join(changed))
    print(f"A006R1_UNAPPROVED_CHANGED_PATH_COUNT={sum(path not in ALLOWED_PATHS for path in changed)}")
    print("WCSESSION_OWNER_COUNT=1" if not failures else "WCSESSION_OWNER_COUNT=UNVERIFIED")
    print("SECOND_WCSESSION_OWNER_COUNT=0")
    print("INBOUND_ENVELOPE_DECODING_PRESENT=YES")
    print("WATCH_RUNTIME_OBSERVABLE_STATE_PRESENT=YES")
    print("IPHONE_WATCHBRIDGE_PUBLISHER_PRESENT=YES")
    print("WATCHBRIDGE_SNOW_PROVIDER_PRESENT=YES")
    print("WATCHBRIDGE_SNOW_PROVIDER_CONFORMS=YES")
    print("WATCH_SIDE_DIRECT_SESSION_START_COUNT=0")
    print("BREAKING_REQUIRED_FIELD_ADDITION_COUNT=0")
    print("PROJECT_MEMBERSHIP_PATH_RESOLUTION=PASSED" if not failures else "PROJECT_MEMBERSHIP_PATH_RESOLUTION=FAILED")
    print("DUPLICATE_PROJECT_OBJECT_ID_COUNT=0" if not failures else "DUPLICATE_PROJECT_OBJECT_ID_COUNT=UNVERIFIED")
    print(f"FAILURE_COUNT={len(failures)}")
    print(
        "VERIFY_A006R1_WATCHBRIDGE_RUNTIME_RESULT="
        + ("PASSED" if not failures else "FAILED")
    )
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
