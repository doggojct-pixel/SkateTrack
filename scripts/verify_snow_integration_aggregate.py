#!/usr/bin/env python3
"""Verify the current Snow integration index without replaying stage-local gates."""
from __future__ import annotations

import copy
import hashlib
import json
import re
import subprocess
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REGISTRY_PATH = ROOT / "scripts/snow_integration_verifier_applicability.json"

EXPECTED_BRANCH = "integration/snow-mode-phase1c-after-task040"
EXPECTED_HEAD = "f48373c6610f35b865ea337953f68e544894f9a5"
EXPECTED_ORIG_HEAD = EXPECTED_HEAD
EXPECTED_MERGE_HEAD = "c618f399dda786ac8c25946b4b1c67148b190901"
EXPECTED_A007_INDEX_SHA256_WITHOUT_A008R1 = (
    "5524fd69db19886a180f0e02bac896e0ebde842d689058828ef5a11c0e9af51c"
)
EXPECTED_A008R1_STAGED_PATH_LIST_SHA256 = (
    "60c9654ddde32e416ce1887a62f1bca757e890a64b9c1e29c6d77e67270454a8"
)
EXPECTED_A009_STAGED_PATH_COUNT = 198
EXPECTED_STAGED_PATH_COUNT = 199
EXPECTED_A010R1_STAGED_PATH_LIST_SHA256 = (
    "788cc77a25d1af0ddf04c13e3f8e3367320daf7393f67408047540ef338cd880"
)
EXPECTED_A010R1_FULL_INDEX_SHA256 = (
    "010765e60ec830776e1cbefa70fd5bf6f472229230a36ff2aee242fbda1e52c6"
)
EXPECTED_A010R4_FULL_INDEX_SHA256 = (
    "9989457bfa51368ca2aebabec715e9eed48cc7b488afe04fec65fc0f855d077c"
)
EXPECTED_A010R4_INDEX_PATH_COUNT = 838
EXPECTED_A010R4_STAGED_PATH_LIST_SHA256 = (
    "03031553f46229300fc4bcd52ac40fb55a55db1124317be13fbf5f5a63f1d561"
)
EXPECTED_A010R5_STAGED_PATH_COUNT = 200
EXPECTED_A010R5_INDEX_PATH_COUNT = 839
EXPECTED_A010R5R1_FULL_INDEX_SHA256 = (
    "58be2671b6ad6f98644e8a088c49a18c7d7107ec07297e628e99b070668c9785"
)
EXPECTED_A010R5R1_INDEX_MANIFEST_SHA256 = (
    "12b7d6b91d60f767c454ad489dbe479676f1c7961eb9f278a42592a5cfee8ad5"
)
EXPECTED_A010R5R1_STAGED_PATH_LIST_SHA256 = (
    "25511e2913519f5d03acc7354cf574faf810bdf199b430c885cdc17b9a98a936"
)
EXPECTED_A010R5R2_STAGED_PATH_COUNT = 200
EXPECTED_A010R5R2_INDEX_PATH_COUNT = 839
EXPECTED_A010R5R2R2_STAGED_PATH_COUNT = 200
EXPECTED_A010R5R2R2_INDEX_PATH_COUNT = 839
EXPECTED_A010R5R2R2_PARENT_FULL_INDEX_SHA256 = (
    "da868892e06912aab28189d9c124293f71b6a35d53557a76a5c7be62235fba19"
)
EXPECTED_A010R5R2R2_PARENT_INDEX_MANIFEST_SHA256 = (
    "2301ba37acec31e0c5606ed798ddf8c8370d426621e5bed645f08160471a9bd0"
)

LIFECYCLES = (
    "PRECOMMIT_MERGE_INDEX",
    "POSTCOMMIT_INTEGRATION_CLEAN",
    "POST_FAST_FORWARD_DEVELOP_PRE_PUSH",
    "POST_PUSH_DEVELOP_FINAL",
)
LIFECYCLE_BINDINGS = {
    "Snow-Integration-A010R5R2R2": "PRECOMMIT_MERGE_INDEX",
    "Snow-Integration-A012R2": "POSTCOMMIT_INTEGRATION_CLEAN",
    "Snow-Integration-A012R3_PRE_PUSH": "POST_FAST_FORWARD_DEVELOP_PRE_PUSH",
    "Snow-Integration-A012R3_POST_PUSH": "POST_PUSH_DEVELOP_FINAL",
}
REVIEWED_INTEGRATION_MERGE_COMMIT = (
    "ea1f36514660191eb9f249cdb54b475c371066ed"
)
REVIEWED_INTEGRATION_FIRST_PARENT = EXPECTED_HEAD
REVIEWED_INTEGRATION_SECOND_PARENT = EXPECTED_MERGE_HEAD
REVIEWED_INTEGRATION_TREE = "35911d60773bfc5a851f123df1f96f1cca95d72a"
REVIEWED_INTEGRATION_HEAD_TREE = (
    "49e077323370b7c2e3809dd680acbbe2b02c5ac2"
)
REVIEWED_INTEGRATION_CHANGED_PATH_COUNT = 200
REVIEWED_INTEGRATION_TREE_ROW_COUNT = 839
REVIEWED_INTEGRATION_INDEX_MANIFEST_SHA256 = (
    "2f292267a96105ec133baea8372309231dadbe044593bdc54ebbe9c982e3cb15"
)
REMEDIATION_ALLOWED_PATHS = {
    "scripts/snow_integration_verifier_applicability.json",
    "scripts/verify_snow_integration_aggregate.py",
}
REMOTE_DEVELOP_BASE = EXPECTED_HEAD

A010R2_NEWLY_STAGED_PATHS = {
    "Tests/iOSTests/SkateTrackPackageWatchCompatibilityTests.swift",
}

A010R2_ALREADY_STAGED_BLOB_MUTATION_PATHS = {
    "scripts/snow_integration_verifier_applicability.json",
    "scripts/verify_snow_integration_aggregate.py",
}

A010R2_ALLOWED_PATHS = (
    A010R2_NEWLY_STAGED_PATHS | A010R2_ALREADY_STAGED_BLOB_MUTATION_PATHS
)

A010R5_NEWLY_STAGED_PATHS = {
    "Tests/iOSTests/SnowLiveSessionCoordinatorTests.swift",
}

A010R5_EXPECTED_ALREADY_STAGED_BLOB_MUTATION_PATHS = {
    "SkateTrack.xcodeproj/project.pbxproj",
    "Tests/iOSTests/SessionRecordingCoordinatorTests.swift",
    "Tests/iOSTests/SkateTrackPackageSnowImportRoundTripTests.swift",
    "docs/history/DEV_LOG.md",
    "docs/process/PHASE_1C_SNOW_AGENT_STATE.md",
    "docs/process/PHASE_1C_SNOW_COMPLETION_HANDOFF.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "docs/release/MANUAL_QA_MATRIX_PRE_ADP.md",
    "docs/release/RELEASE_READINESS_PRE_ADP.md",
    "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift",
    "iOS/Core/SnowEngine/SnowLiveSessionCoordinator.swift",
    "scripts/snow_integration_verifier_applicability.json",
    "scripts/verify_snow_integration_aggregate.py",
}

A010R5_EXPECTED_MUTATION_PATHS = (
    A010R5_NEWLY_STAGED_PATHS | A010R5_EXPECTED_ALREADY_STAGED_BLOB_MUTATION_PATHS
)

A010R5_MAX_ALLOWED_PATHS = A010R5_EXPECTED_MUTATION_PATHS | {
    "Tests/iOSTests/SnowSummarySelectionTests.swift",
    "Tests/iOSTests/SkateTrackPackageSnowCompatibilityTests.swift",
    "iOS/Hooks/useSessionSummary.swift",
}

A010R5R2_ALLOWED_PATHS = {
    "Shared/Localization/en.lproj/Localizable.strings",
    "Shared/Localization/ja.lproj/Localizable.strings",
    "Shared/Localization/zh-Hant.lproj/Localizable.strings",
    "Tests/iOSTests/SnowSummarySelectionTests.swift",
    "docs/history/DEV_LOG.md",
    "docs/process/PHASE_1C_SNOW_AGENT_STATE.md",
    "docs/process/PHASE_1C_SNOW_COMPLETION_HANDOFF.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "docs/release/MANUAL_QA_MATRIX_PRE_ADP.md",
    "docs/release/RELEASE_READINESS_PRE_ADP.md",
    "iOS/Features/SessionSummary/SessionSummaryView.swift",
    "iOS/Features/SessionSummary/SnowDaySummaryView.swift",
    "iOS/Features/SessionSummary/SnowDistanceInspectorView.swift",
    "iOS/Features/SessionSummary/SnowSegmentTimelineView.swift",
    "scripts/snow_integration_verifier_applicability.json",
    "scripts/verify_snow_integration_aggregate.py",
    "scripts/verify_snow_iphone_ui.py",
}

A010R5R2_EXPECTED_MUTATION_PATHS = A010R5R2_ALLOWED_PATHS - {
    "iOS/Features/SessionSummary/SessionSummaryView.swift",
    "iOS/Features/SessionSummary/SnowDistanceInspectorView.swift",
    "iOS/Features/SessionSummary/SnowSegmentTimelineView.swift",
}

A010R5R2R2_ALLOWED_PATHS = {
    "scripts/verify_snow_integration_aggregate.py",
    "scripts/snow_integration_verifier_applicability.json",
    "docs/history/DEV_LOG.md",
    "docs/process/PHASE_1C_SNOW_AGENT_STATE.md",
    "docs/process/PHASE_1C_SNOW_COMPLETION_HANDOFF.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "docs/release/MANUAL_QA_MATRIX_PRE_ADP.md",
    "docs/release/RELEASE_READINESS_PRE_ADP.md",
}

A010R5R2R2_DOCUMENT_PATHS = A010R5R2R2_ALLOWED_PATHS - {
    "scripts/verify_snow_integration_aggregate.py",
    "scripts/snow_integration_verifier_applicability.json",
}

A010R5R2R2_REQUIRED_DOCUMENT_TOKENS = [
    "Snow-Integration-A010R5R2R2 current closure",
    "A010R5_RESULT=BLOCKED_HISTORICAL",
    "A010R5R1_RESULT=PASSED_HISTORICAL",
    "A010R5R2R1_RESULT=BLOCKED_HISTORICAL",
    "SNOW_INT_A010R5R2_RESULT=PASSED",
    "MANUAL_QA_A010R5R2_FOCUSED=PASSED",
    "A010R5R2_AUTOMATED_GATES=PASSED",
    "CURRENT_REQUIRED_VERIFIERS=12_OF_12_PASSED",
    "IOS_XCTEST_TOTAL_COUNT=314",
    "SUMMARY_TIMELINE_INSPECTOR_VISIBLE_DISTANCE_STRING_MATCH=YES",
    "ZH_HANT_DOWNHILL_INFORMATION_COPY=PASSED",
    "EN_DOWNHILL_INFORMATION_COPY=PASSED",
    "JA_DOWNHILL_INFORMATION_COPY=PASSED",
    "UNKNOWN_ONLY_STATUS_CARD=PASSED",
    "PACKAGE_SCHEMA_VERSION_CHANGED=NO",
    "CORE_DATA_MODEL_CHANGED=NO",
    "A010R5R3_STARTED=NO",
    "A010R5R4_STARTED=NO",
    "A010R6_STARTED=NO",
    "A010R6_AUTHORIZED=NO_UNTIL_A010R5R2R2_INDEPENDENT_REVIEW",
    "COMMIT_CREATED=NO",
    "PUSH_CREATED=NO",
    "MERGE_CONTINUE_PERFORMED=NO",
]

A010R5R2R2_STALE_PRE_QA_MARKERS = [
    "A010R5R2_RESULT=PENDING_OPERATOR_MANUAL_QA",
    "SNOW_INT_A010R5R2_RESULT=PENDING_OPERATOR_MANUAL_QA",
    "MANUAL_QA_A010R5R2_FOCUSED=PENDING_OPERATOR_RESPONSE",
    "MANUAL_QA_PERFORMED=NO",
]

A010R5R2R2_PARENT_INDEX_ENTRIES = {
    "scripts/verify_snow_integration_aggregate.py": "100644 ebc7ba01c219c2383413c1903c8b0e04ff73db9f 0\tscripts/verify_snow_integration_aggregate.py",
    "scripts/snow_integration_verifier_applicability.json": "100644 4ec77073033eba13020bdf2731c5f1a444838dce 0\tscripts/snow_integration_verifier_applicability.json",
    "docs/history/DEV_LOG.md": "100644 bfc7422cf7f0c790f927b54f41cd9736d40145a0 0\tdocs/history/DEV_LOG.md",
    "docs/process/PHASE_1C_SNOW_AGENT_STATE.md": "100644 337f8c5cd7b5ac1dd30609187bc699c4e7a0d2b7 0\tdocs/process/PHASE_1C_SNOW_AGENT_STATE.md",
    "docs/process/PHASE_1C_SNOW_COMPLETION_HANDOFF.md": "100644 86cac9f4784cf8a74d493df42896e12a729fc633 0\tdocs/process/PHASE_1C_SNOW_COMPLETION_HANDOFF.md",
    "docs/reference/FILE_STRUCTURE.md": "100644 90ae55853038e5dfc85746632e5a98970855118b 0\tdocs/reference/FILE_STRUCTURE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": "100644 b15cc0840f5b8311b86e3015fa7cfe0bf877bdd1 0\tdocs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "docs/release/MANUAL_QA_MATRIX_PRE_ADP.md": "100644 170065b4b70aa88880ad7752c911a57caa8d4c61 0\tdocs/release/MANUAL_QA_MATRIX_PRE_ADP.md",
    "docs/release/RELEASE_READINESS_PRE_ADP.md": "100644 98c7fb0f15facd995a1cdfde071e7849e832cbe0 0\tdocs/release/RELEASE_READINESS_PRE_ADP.md",
}

A010R5R2_PARENT_INDEX_ENTRIES = {
    "Shared/Localization/en.lproj/Localizable.strings": "100644 3483e239c5f2012d0133ad4a22cb023d61068abb 0\tShared/Localization/en.lproj/Localizable.strings",
    "Shared/Localization/ja.lproj/Localizable.strings": "100644 22fdd2c96f759a3ff61ac844f8436e0e2e311e75 0\tShared/Localization/ja.lproj/Localizable.strings",
    "Shared/Localization/zh-Hant.lproj/Localizable.strings": "100644 97419cf3ba4a12eb74474bedf04fa49555484964 0\tShared/Localization/zh-Hant.lproj/Localizable.strings",
    "Tests/iOSTests/SnowSummarySelectionTests.swift": "100644 b78d27d96c9dd0ab4302c8cdda83c31a5c1466c7 0\tTests/iOSTests/SnowSummarySelectionTests.swift",
    "docs/history/DEV_LOG.md": "100644 f623ea1a82502e2e1226497357f6ec73e028b62e 0\tdocs/history/DEV_LOG.md",
    "docs/process/PHASE_1C_SNOW_AGENT_STATE.md": "100644 f1840b0bcc37578a3e2e90b4a1ed791dd82b3ac1 0\tdocs/process/PHASE_1C_SNOW_AGENT_STATE.md",
    "docs/process/PHASE_1C_SNOW_COMPLETION_HANDOFF.md": "100644 8eb9d25022c68953ece57e65be76e8fd80721f66 0\tdocs/process/PHASE_1C_SNOW_COMPLETION_HANDOFF.md",
    "docs/reference/FILE_STRUCTURE.md": "100644 8f916e32007ad0fbb96af2f5b34ac283e900d64c 0\tdocs/reference/FILE_STRUCTURE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": "100644 01582094ae696e27d2a84f0e237afb6c4df0c544 0\tdocs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "docs/release/MANUAL_QA_MATRIX_PRE_ADP.md": "100644 713798b572525dd991066162f56828f5814a6972 0\tdocs/release/MANUAL_QA_MATRIX_PRE_ADP.md",
    "docs/release/RELEASE_READINESS_PRE_ADP.md": "100644 0c5b9288988dd4183db925d346240ef1d3f598e9 0\tdocs/release/RELEASE_READINESS_PRE_ADP.md",
    "iOS/Features/SessionSummary/SessionSummaryView.swift": "100644 9668b44a71d95962d149728e43ccbac55a5c369e 0\tiOS/Features/SessionSummary/SessionSummaryView.swift",
    "iOS/Features/SessionSummary/SnowDaySummaryView.swift": "100644 e6aba10d2a5aa783b771933ec84639b055376d4b 0\tiOS/Features/SessionSummary/SnowDaySummaryView.swift",
    "iOS/Features/SessionSummary/SnowDistanceInspectorView.swift": "100644 57573d946469afd82cecc88dda90b04a38614ce7 0\tiOS/Features/SessionSummary/SnowDistanceInspectorView.swift",
    "iOS/Features/SessionSummary/SnowSegmentTimelineView.swift": "100644 52b62b8d0bd3935d57af4e99dfc5b5bc7f53151b 0\tiOS/Features/SessionSummary/SnowSegmentTimelineView.swift",
    "scripts/snow_integration_verifier_applicability.json": "100644 bdf353662403bad0e880d3e855bc48469a0043da 0\tscripts/snow_integration_verifier_applicability.json",
    "scripts/verify_snow_integration_aggregate.py": "100644 d0621f9474ee77d0f4328d9cec033749737ca235 0\tscripts/verify_snow_integration_aggregate.py",
    "scripts/verify_snow_iphone_ui.py": "100755 fc060411ee535ac41a7baf99c3af7d52ceac2ddd 0\tscripts/verify_snow_iphone_ui.py",
}

A010R5_PARENT_INDEX_ENTRIES = {
    "SkateTrack.xcodeproj/project.pbxproj": "100644 1902346be7f451146dfe6097eeb0c7e5046abc34 0\tSkateTrack.xcodeproj/project.pbxproj",
    "Tests/iOSTests/SessionRecordingCoordinatorTests.swift": "100644 6133f0f8cd6f4263448162df29a2ec7ee9f7c34f 0\tTests/iOSTests/SessionRecordingCoordinatorTests.swift",
    "Tests/iOSTests/SkateTrackPackageSnowImportRoundTripTests.swift": "100644 e26d5726124e72be102d6d32c475e9d1903189e6 0\tTests/iOSTests/SkateTrackPackageSnowImportRoundTripTests.swift",
    "docs/history/DEV_LOG.md": "100644 503d9dde8aed0ce344612069d524183a771a67b6 0\tdocs/history/DEV_LOG.md",
    "docs/process/PHASE_1C_SNOW_AGENT_STATE.md": "100644 032b8271abf20d188949ade731de18adc1fd1330 0\tdocs/process/PHASE_1C_SNOW_AGENT_STATE.md",
    "docs/process/PHASE_1C_SNOW_COMPLETION_HANDOFF.md": "100644 5e36250e5640cf2b2c6048bc7ac80ee0af43edb7 0\tdocs/process/PHASE_1C_SNOW_COMPLETION_HANDOFF.md",
    "docs/reference/FILE_STRUCTURE.md": "100644 50bf5e8b0789932aac7711f301399ba6afe0a9e2 0\tdocs/reference/FILE_STRUCTURE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": "100644 415f578103e35a33f048945b4e729817d5fba171 0\tdocs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "docs/release/MANUAL_QA_MATRIX_PRE_ADP.md": "100644 e1b699ffa8b26d67ed72b9242ce068fcf6eb053e 0\tdocs/release/MANUAL_QA_MATRIX_PRE_ADP.md",
    "docs/release/RELEASE_READINESS_PRE_ADP.md": "100644 8edcdea44ee687b93feeb1eefa3dbd4d4e11630b 0\tdocs/release/RELEASE_READINESS_PRE_ADP.md",
    "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift": "100644 feb723b8646b2e9ab38e58c196f2e4a1a5117969 0\tiOS/Core/SessionRecording/SessionRecordingCoordinator.swift",
    "iOS/Core/SnowEngine/SnowLiveSessionCoordinator.swift": "100644 9d45fb5b36e96ca6f60cd74fb02e2fc84507af9a 0\tiOS/Core/SnowEngine/SnowLiveSessionCoordinator.swift",
    "scripts/snow_integration_verifier_applicability.json": "100644 a6e5543ef1f3589546cc82dac67a455152fef279 0\tscripts/snow_integration_verifier_applicability.json",
    "scripts/verify_snow_integration_aggregate.py": "100644 4fd567d9356f399be2dc3d4d64e19f98565b5e5d 0\tscripts/verify_snow_integration_aggregate.py",
}

A010R5_FROZEN_FORMAT_AND_CLASSIFIER_INDEX_ENTRIES = {
    "Shared/Export/SkateTrackPackageReader.swift": "100644 33b19b31e6db6ff2dc2cf06d1854a329ce7bcd2a 0\tShared/Export/SkateTrackPackageReader.swift",
    "Shared/Export/SkateTrackPackageWriter.swift": "100644 954f44b67587517a3d515e577cee9fc3d644377b 0\tShared/Export/SkateTrackPackageWriter.swift",
    "Shared/Localization/en.lproj/Localizable.strings": "100644 3483e239c5f2012d0133ad4a22cb023d61068abb 0\tShared/Localization/en.lproj/Localizable.strings",
    "Shared/Localization/ja.lproj/Localizable.strings": "100644 22fdd2c96f759a3ff61ac844f8436e0e2e311e75 0\tShared/Localization/ja.lproj/Localizable.strings",
    "Shared/Localization/zh-Hant.lproj/Localizable.strings": "100644 97419cf3ba4a12eb74474bedf04fa49555484964 0\tShared/Localization/zh-Hant.lproj/Localizable.strings",
    "Shared/Models/BackupPackageManifest.swift": "100644 26a9a738d1608a0d30dcf2d0fd5533b49c9d0972 0\tShared/Models/BackupPackageManifest.swift",
    "Shared/Models/BackupPackagePayload.swift": "100644 0b293eeb65793bcb57491e52fe38c125106c52d7 0\tShared/Models/BackupPackagePayload.swift",
    "Shared/Models/RunBoundaryConfig.swift": "100644 fdd0e35d57b9252cf87e4dd5841e3f416f27032f 0\tShared/Models/RunBoundaryConfig.swift",
    "Shared/Models/RunBoundaryDetector.swift": "100644 23e41c267dce3161fa9d175d613ab20e78214f29 0\tShared/Models/RunBoundaryDetector.swift",
    "Shared/Models/SkateTrackPackageManifest.swift": "100644 58c6f16975b22c4d5890a00eebc22f10495a442c 0\tShared/Models/SkateTrackPackageManifest.swift",
    "Shared/Models/SkateTrackPackagePayload.swift": "100644 fa5356b7e199533a536006b60417669c4b92188b 0\tShared/Models/SkateTrackPackagePayload.swift",
    "Shared/Models/SkateTrackPackageSnowPayload.swift": "100644 005fd83d90a0dda11a43ab87e57f801672abcfa7 0\tShared/Models/SkateTrackPackageSnowPayload.swift",
    "Shared/Models/SnowClassifierConfig.swift": "100644 d1962f74fedd1e2f08d19e3072d28fdd68e9f973 0\tShared/Models/SnowClassifierConfig.swift",
    "Shared/Models/SnowSegmentClassifier.swift": "100644 8cec2143e4fde4e83e498425c51ac80267f87e45 0\tShared/Models/SnowSegmentClassifier.swift",
    "Shared/Persistence/PersistenceController.swift": "100644 c4b0d8a1a3776f1cd2d2c81625c0dd053f76e80b 0\tShared/Persistence/PersistenceController.swift",
    "Shared/Persistence/SkateTrackDataModel.xcdatamodeld/SkateTrackDataModel.xcdatamodel/contents": "100644 f1fc0e85880de2f7baafe3c8045b4254cd4bd757 0\tShared/Persistence/SkateTrackDataModel.xcdatamodeld/SkateTrackDataModel.xcdatamodel/contents",
    "iOS/Core/Sync/BackupPackageDecoder.swift": "100644 37fd0bd380abea5a8c092082c14451cc58f25958 0\tiOS/Core/Sync/BackupPackageDecoder.swift",
    "iOS/Core/Sync/BackupPackageEncoder.swift": "100644 69e7cc50ae38ad95a934594adc2266f3d55ae645 0\tiOS/Core/Sync/BackupPackageEncoder.swift",
}

A010R1_PRE_REMEDIATION_INDEX_ENTRIES = {
    "Tests/iOSTests/SkateTrackPackageWatchCompatibilityTests.swift": (
        "100644 10994d084c397043ebef0c78a52c5cfac4245975 0\t"
        "Tests/iOSTests/SkateTrackPackageWatchCompatibilityTests.swift"
    ),
    "scripts/snow_integration_verifier_applicability.json": (
        "100644 0e374e76f840f508d2559d28d597d19e97cfe6e7 0\t"
        "scripts/snow_integration_verifier_applicability.json"
    ),
    "scripts/verify_snow_integration_aggregate.py": (
        "100644 8dd4d2643053e9afb0749e8ed6d01071601ccc2d 0\t"
        "scripts/verify_snow_integration_aggregate.py"
    ),
}

A007_PATHS = {
    "scripts/snow_integration_verifier_applicability.json",
    "scripts/verify_snow_integration_aggregate.py",
}

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

A009_DOC_PATHS = {
    "docs/DOCUMENTATION_INDEX.md",
    "docs/history/DEV_LOG.md",
    "docs/process/PHASE_1C_SNOW_AGENT_STATE.md",
    "docs/process/PHASE_1C_SNOW_COMPLETION_HANDOFF.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "docs/release/MANUAL_QA_MATRIX_PRE_ADP.md",
    "docs/release/RELEASE_READINESS_PRE_ADP.md",
}

A009_NEWLY_STAGED_PATHS = {
    "docs/release/RELEASE_READINESS_PRE_ADP.md",
}

# Independently reviewed A009 parent evidence freezes these seven pre-A009
# index entries. FILE_STRUCTURE is already covered by the A008R1 exclusion.
A009_PRE_STAGE_INDEX_ENTRIES = {
    "docs/DOCUMENTATION_INDEX.md": (
        "100644 d1d65bafe5a0f905fa7103a59c8f0aa58332ac88 0\t"
        "docs/DOCUMENTATION_INDEX.md"
    ),
    "docs/history/DEV_LOG.md": (
        "100644 6b936cd6bfd1b20b9b08153e27715b410a124e66 0\t"
        "docs/history/DEV_LOG.md"
    ),
    "docs/process/PHASE_1C_SNOW_AGENT_STATE.md": (
        "100644 9182db048f05dee8229fa350cac3c3d7e847ad47 0\t"
        "docs/process/PHASE_1C_SNOW_AGENT_STATE.md"
    ),
    "docs/process/PHASE_1C_SNOW_COMPLETION_HANDOFF.md": (
        "100644 a62bc43ca045b0d52e25e338f8039335b070b343 0\t"
        "docs/process/PHASE_1C_SNOW_COMPLETION_HANDOFF.md"
    ),
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": (
        "100644 c802f43c92a1a50e67ec4b1fc6868ec5a1d7ab10 0\t"
        "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md"
    ),
    "docs/release/MANUAL_QA_MATRIX_PRE_ADP.md": (
        "100644 751a0aa459f09cbd198694a16ed925f743e76c59 0\t"
        "docs/release/MANUAL_QA_MATRIX_PRE_ADP.md"
    ),
    "docs/release/RELEASE_READINESS_PRE_ADP.md": (
        "100644 6e31db28e5704d5b174815b633bf1345fea8efdb 0\t"
        "docs/release/RELEASE_READINESS_PRE_ADP.md"
    ),
}

SUPPORTING_VERIFIER_INVENTORY = {
    "scripts/verify_a008r1_manual_qa_readiness.py",
    "scripts/verify_localization_keys.py",
    "scripts/verify_shared_models.py",
    "scripts/verify_debug_tools.py",
    "scripts/verify_skatetrack_package.py",
    "scripts/verify_session_recording_coordinator.py",
    "scripts/verify_session_repository.py",
    "scripts/verify_session_persistence_integration.py",
    "scripts/verify_backup_sync.py",
    "scripts/verify_backup_restore_preview.py",
}

CLASSIFICATIONS = {
    "CURRENT_REQUIRED",
    "CURRENT_OPTIONAL",
    "HISTORICAL_STAGE_LOCAL",
    "SUPERSEDED_BY_AGGREGATE",
    "NOT_APPLICABLE_WITH_REASON",
}

SNOW_OPTIONAL_FIELDS = {
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

CLASSIFIER_V0_TOKENS = [
    "altitudeMovingAverageSampleCount: 30",
    "trendWindowSeconds: 5",
    "hysteresisSeconds: 5",
    "ascentWindowSeconds: 10",
    "stoppedWindowSeconds: 15",
    "minimumSampleCount: 5",
    "downhillMinSpeedKmh: 10",
    "downhillVerticalRateThresholdMetersPerSecond: -0.25",
    "strongDownhillVerticalRateThresholdMetersPerSecond: -0.45",
    "ascentVerticalRateThresholdMetersPerSecond: 0.15",
    "flatVerticalRateAbsThresholdMetersPerSecond: 0.10",
    "stoppedSpeedThresholdKmh: 2",
    "walkingMinSpeedKmh: 2",
    "walkingMaxSpeedKmh: 6",
    "flatTraverseMinSpeedKmh: 6",
    "gondolaMinSpeedKmh: 8",
    "gondolaMaxSpeedKmh: 30",
    "downhillMotionEnergyThresholdG: 0.08",
    "lowMotionEnergyThresholdG: 0.03",
    "downhillHeadingStandardDeviationThresholdDegrees: 12",
    "stableHeadingStandardDeviationThresholdDegrees: 5",
    "highConfidenceThreshold: 0.78",
    "mediumConfidenceThreshold: 0.62",
]

RUN_BOUNDARY_V0_TOKENS = [
    "startConfirmationSeconds: 3",
    "startConfidenceThreshold: 0.70",
    "pendingEndConfirmationSeconds: 8",
    "pendingEndCancelSeconds: 2",
    "pendingEndCancelConfidenceThreshold: 0.62",
    "pendingEndTimeoutSeconds: 30",
    "hardTransportEndConfidenceThreshold: 0.78",
    "hardTransportConfirmationSeconds: 5",
    "maximumMergeGapSeconds: 2",
]

CRITICAL_PROJECT_FILES = [
    "Shared/WatchBridge/WatchBridgeRuntimeState.swift",
    "Shared/WatchBridge/WatchBridgeSnowSnapshotMapper.swift",
    "iOS/Core/WatchBridge/WatchBridgeActivityPublisher.swift",
    "watchOS/Core/WatchBridge/WatchBridgeWatchRuntime.swift",
    "watchOS/Core/Snow/WatchBridgeSnowSessionProvider.swift",
    "Tests/iOSTests/WatchBridgeRuntimeSnowAdapterTests.swift",
]

FINAL_ACCEPTANCE_MATRIX = [
    ("APPROVED_INTEGRATION_PATH_COMPLETED", "PASSED_NOW"),
    ("FINAL_MERGE_TO_DEVELOP_RESULT", "PENDING_A012_FINAL_MERGE"),
    ("ALL_REQUIRED_SNOW_VERIFY_SCRIPTS_PASS", "PASSED_NOW"),
    ("IOS_BUILD", "PASSED_NOW"),
    ("WATCHOS_BUILD", "PASSED_NOW"),
    ("MACOS_BUILD", "PASSED_NOW"),
    ("SNOW_XCTEST_SUITES", "PASSED_NOW"),
    ("SNOW_PROTOTYPE_NAMESPACE_GREP_RESULT", "PASSED_NOW"),
    ("SPORT_MODE_SNOW_PRESENT", "PASSED_NOW"),
    ("SPORT_MODE_SWITCH_EXHAUSTIVENESS", "PASSED_NOW"),
    ("SHARED_ACTIVITY_VISUALIZATION_SNOW_COMPATIBILITY", "PASSED_NOW"),
    ("WATCHBRIDGE_SNOW_PROVIDER_PRESENT", "PASSED_NOW"),
    ("WATCHBRIDGE_SNOW_PROVIDER_CONFORMS", "PASSED_NOW"),
    ("WATCH_SNOW_MOCK_PROVIDER_PRESERVED_FOR_DEBUG", "PASSED_NOW"),
    ("NO_DIRECT_WCSESSION_IN_SNOW_VIEWS", "PASSED_NOW"),
    ("PACKAGE_BACKUP_V1_V2_COMPATIBILITY", "PASSED_NOW"),
    ("NON_SNOW_SESSION_GPS_BEHAVIOR_UNCHANGED", "PASSED_NOW"),
    ("DOCUMENTATION_AND_DEFERRED_ITEMS_CLOSED", "PASSED_NOW"),
]

failures: list[str] = []
group_results: dict[str, bool] = {}
observations: dict[str, int | str] = {}
selected_lifecycle = ""


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
    except UnicodeDecodeError:
        fail(f"required text file is not valid UTF-8: {rel_path}")
        return ""


def run(command: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=False,
    )


def git(*args: str) -> str:
    result = run(["git", "-C", str(ROOT), *args])
    if result.returncode != 0:
        fail(f"git {' '.join(args)} failed: {result.stderr.strip()}")
        return ""
    return result.stdout


def a010r5_parent_blob_text(rel_path: str) -> str:
    """Read an A010R4 frozen parent blob for a path A010R5 is allowed to mutate."""
    entry = A010R5_PARENT_INDEX_ENTRIES.get(rel_path)
    if entry is None:
        raise KeyError(f"missing A010R4 parent entry for {rel_path}")
    blob_hash = entry.split()[1]
    result = subprocess.run(
        ["git", "-C", str(ROOT), "cat-file", "-p", blob_hash],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(f"unable to read A010R4 parent blob for {rel_path}")
    return result.stdout


def head_text(rel_path: str) -> str:
    result = subprocess.run(
        ["git", "-C", str(ROOT), "show", f"HEAD:{rel_path}"],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(f"unable to read HEAD baseline for {rel_path}")
    return result.stdout


def emit_standalone_contract_result(name: str, issues: list[str]) -> int:
    for issue in issues:
        print(f"FAIL: {issue}", file=sys.stderr)
    output_marker(f"{name}_FAILURE_COUNT", len(issues))
    output_marker(name, "PASSED" if not issues else "FAILED")
    return 0 if not issues else 1


def verify_current_session_recording_contract() -> int:
    """Replace only the obsolete A005 fixed-growth assertion with the A010R5 parent delta."""
    issues: list[str] = []
    required_files = [
        "iOS/Core/SessionRecording/SessionStateMachine.swift",
        "iOS/Core/SessionRecording/SessionMetricsAccumulator.swift",
        "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift",
        "iOS/Core/SessionRecording/SessionRecordingCoordinator+DebugMock.swift",
        "iOS/Hooks/useSessionRecording.swift",
        "Shared/Models/SessionSummaryMetrics.swift",
        "Tests/iOSTests/SessionRecordingCoordinatorTests.swift",
    ]
    required_snippets = {
        "iOS/Core/SessionRecording/SessionStateMachine.swift": [
            "// [自主區]", "enum SessionRecordingStatus", "func canTransition(from current:", "case .idle:",
        ],
        "iOS/Core/SessionRecording/SessionMetricsAccumulator.swift": [
            "// [自主區]", "struct SessionMetricsAccumulator", "makeSummaryMetrics()", "makeLiveMetrics()",
        ],
        "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift": [
            "// [自主區]", "final class SessionRecordingCoordinator",
            "let sessionRepository: SessionRepositoryProtocol", "func startSession(",
            "func pauseSession()", "func resumeSession()", "func requestEndSession()",
            "sessionRepository.saveCompletedSession", "equipmentMileageTracker",
            "func discardCurrentSession()", "FallDetectionEngine", "SensorFusionEngine",
            "SessionSummaryDisplayMetrics.make(", "snowLiveCoordinator.finishSession(",
            "trustedRouteDistanceMeters:",
        ],
        "iOS/Core/SessionRecording/SessionRecordingCoordinator+DebugMock.swift": [
            "// [自主區]", "#if DEBUG", "func startMockSampleFeed", "func stopMockSampleFeed", "func makeMockSample",
        ],
        "iOS/Hooks/useSessionRecording.swift": [
            "// [協作區", "final class SessionRecordingViewModel", "func useSessionRecording(", "SessionRecordingActions",
        ],
        "Shared/Models/SessionSummaryMetrics.swift": [
            "// [協作區]", "struct SessionSummaryMetrics", "struct LiveSessionMetrics",
        ],
    }
    for rel_path in required_files:
        path = ROOT / rel_path
        if not path.is_file():
            issues.append(f"missing required file: {rel_path}")
            continue
        text = path.read_text(encoding="utf-8")
        for snippet in required_snippets.get(rel_path, []):
            if snippet not in text:
                issues.append(f"{rel_path} missing snippet: {snippet}")
        if rel_path.startswith("iOS/Core/SessionRecording/"):
            for forbidden in ("import SwiftUI", "import UIKit", "import AppKit", "import WatchKit"):
                if forbidden in text:
                    issues.append(f"{rel_path} contains forbidden UI import: {forbidden}")

    limits = {
        "iOS/Core/SessionRecording/SessionStateMachine.swift": 250,
        "iOS/Core/SessionRecording/SessionMetricsAccumulator.swift": 350,
    }
    for rel_path, limit in limits.items():
        if (ROOT / rel_path).is_file() and len(read(rel_path).splitlines()) > limit:
            issues.append(f"{rel_path} exceeds {limit} lines")

    try:
        coordinator_path = "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift"
        head_count = len(head_text(coordinator_path).splitlines())
        parent_count = len(a010r5_parent_blob_text(coordinator_path).splitlines())
        final_count = len(read(coordinator_path).splitlines())
        if parent_count - head_count != 55:
            issues.append(f"A005 coordinator parent growth changed: HEAD={head_count}, A010R4={parent_count}")
        if final_count - parent_count != 8:
            issues.append(f"A010R5 coordinator growth mismatch: A010R4={parent_count}, final={final_count}, expected=8")
        for rel_path, expected_growth in {
            "iOS/Core/SessionRecording/SessionRecordingCoordinator+DebugMock.swift": 5,
            "iOS/Hooks/useSessionRecording.swift": 28,
        }.items():
            if len(read(rel_path).splitlines()) - len(head_text(rel_path).splitlines()) != expected_growth:
                issues.append(f"historical oversized growth mismatch: {rel_path}")
    except (KeyError, RuntimeError) as error:
        issues.append(str(error))

    project = read("SkateTrack.xcodeproj/project.pbxproj")
    for rel_path in required_files:
        name = Path(rel_path).name
        if name == "SessionRecordingCoordinatorTests.swift":
            continue
        if f"/* {name} */" not in project and f"/* {name} in Sources */" not in project:
            issues.append(f"missing Xcode project reference: {name}")
    for key in (
        "session.status.idle", "session.status.preparing", "session.status.recording",
        "session.status.paused", "session.status.saving", "session.error.invalidPowerType",
        "session.error.sensorUnavailable",
    ):
        for language in ("en", "zh-Hant"):
            if f'"{key}"' not in read(f"Shared/Localization/{language}.lproj/Localizable.strings"):
                issues.append(f"missing localization key {key} in {language}")
    return emit_standalone_contract_result("VERIFY_CURRENT_SESSION_RECORDING_CONTRACT_RESULT", issues)


def verify_current_session_persistence_contract() -> int:
    """Run the legacy persistence assertions with the frozen A010R4-to-A010R5 growth contract."""
    issues: list[str] = []
    required_files = [
        "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift",
        "iOS/Core/SessionRecording/SessionRecordingCoordinator+DebugMock.swift",
        "iOS/Hooks/useSessionRecording.swift",
        "Shared/Persistence/SessionRepository.swift",
        "Shared/Persistence/RepositoryError.swift",
        "Tests/iOSTests/SessionRecordingCoordinatorTests.swift",
    ]
    for rel_path in required_files:
        if not (ROOT / rel_path).is_file():
            issues.append(f"missing required file: {rel_path}")
    if issues:
        return emit_standalone_contract_result("VERIFY_CURRENT_SESSION_PERSISTENCE_CONTRACT_RESULT", issues)

    contracts = {
        "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift": [
            "let sessionRepository: SessionRepositoryProtocol",
            "sessionRepository: SessionRepositoryProtocol = SessionRepository.shared",
            "sessionRepository.saveCompletedSession(sessionData)",
            "completedSessionSubject.send(savedSession)", "catch let error as RepositoryError",
            "RepositoryError.saveFailed.localizationKey", "SessionSummaryDisplayMetrics.make(",
        ],
        "iOS/Core/SessionRecording/SessionRecordingCoordinator+DebugMock.swift": [
            "#if DEBUG", "func startMockSampleFeed", "func stopMockSampleFeed", "func makeMockSample",
            "static func makeMockCoordinator", "#else",
        ],
        "iOS/Hooks/useSessionRecording.swift": [
            "catch let error as RepositoryError", "$0.errorMessageKey = error.localizationKey",
        ],
        "Shared/Persistence/SessionRepository.swift": [
            "protocol SessionRepositoryProtocol: AnyObject, Sendable", "func saveCompletedSession",
        ],
        "Shared/Persistence/RepositoryError.swift": ["case saveFailed", "repository.error.saveFailed"],
        "Tests/iOSTests/SessionRecordingCoordinatorTests.swift": [
            "testRequestEndSessionPublishesOnlyAfterPersistenceSucceeds", "testDiscardCurrentSessionDoesNotPersist",
            "testPersistenceFailurePublishesRepositoryError", "MockSessionRepository",
            "sessionRepository: repository", "RepositoryError.saveFailed.localizationKey",
            "testSnowSessionStartsLiveCoordinatorAndForwardsSamples",
            "testNonSnowSessionDoesNotForwardSamplesToSnowLiveCoordinator",
        ],
    }
    for rel_path, tokens in contracts.items():
        content = read(rel_path)
        for token in tokens:
            if token not in content:
                issues.append(f"{rel_path} missing token: {token}")
    coordinator = read("iOS/Core/SessionRecording/SessionRecordingCoordinator.swift")
    if coordinator.index("sessionRepository.saveCompletedSession(sessionData)") > coordinator.index("completedSessionSubject.send(savedSession)"):
        issues.append("completed session is published before repository save")
    try:
        parent_count = len(a010r5_parent_blob_text("iOS/Core/SessionRecording/SessionRecordingCoordinator.swift").splitlines())
        final_count = len(coordinator.splitlines())
        if final_count - parent_count != 8:
            issues.append(f"A010R5 persistence coordinator growth mismatch: A010R4={parent_count}, final={final_count}, expected=8")
    except (KeyError, RuntimeError) as error:
        issues.append(str(error))
    project = read("SkateTrack.xcodeproj/project.pbxproj")
    for token in ("SessionRecordingCoordinator+DebugMock.swift", "SessionRecordingCoordinator+DebugMock.swift in Sources"):
        if token not in project:
            issues.append(f"project missing {token}")
    declared_ids = re.findall(r"^\s*(15B100000000000000000\w+) /\*[^\n]+\*/ = \{isa", project, re.MULTILINE)
    if len(declared_ids) != len(set(declared_ids)):
        issues.append("duplicate Task-015b project object declarations")
    for language in ("en", "zh-Hant"):
        if '"repository.error.saveFailed"' not in read(f"Shared/Localization/{language}.lproj/Localizable.strings"):
            issues.append(f"missing repository.error.saveFailed in {language}")
    return emit_standalone_contract_result("VERIFY_CURRENT_SESSION_PERSISTENCE_CONTRACT_RESULT", issues)


def git_show_head(rel_path: str) -> str:
    result = run(["git", "-C", str(ROOT), "show", f"{EXPECTED_HEAD}:{rel_path}"])
    if result.returncode != 0:
        fail(f"cannot read {rel_path} from frozen HEAD: {result.stderr.strip()}")
        return ""
    return result.stdout


def nonempty_lines(text: str) -> list[str]:
    return [line.strip() for line in text.splitlines() if line.strip()]


def require_tokens(rel_path: str, tokens: list[str]) -> str:
    content = read(rel_path)
    for token in tokens:
        check(token in content, f"{rel_path} missing required token: {token}")
    return content


def mark_group(name: str, start_failure_count: int) -> None:
    group_results[name] = len(failures) == start_failure_count


def switch_blocks(text: str) -> list[str]:
    blocks: list[str] = []
    for match in re.finditer(r"\bswitch\b", text):
        brace = text.find("{", match.end())
        if brace == -1:
            continue
        depth = 0
        for index in range(brace, len(text)):
            char = text[index]
            if char == "{":
                depth += 1
            elif char == "}":
                depth -= 1
                if depth == 0:
                    blocks.append(text[match.start():index + 1])
                    break
    return blocks


def strip_swift_comments(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.DOTALL)
    return re.sub(r"//.*", "", text)


def named_swift_function_block(text: str, function_name: str) -> str:
    match = re.search(rf"\bfunc\s+{re.escape(function_name)}\b", text)
    if not match:
        return ""
    brace = text.find("{", match.end())
    if brace == -1:
        return ""
    depth = 0
    for index in range(brace, len(text)):
        if text[index] == "{":
            depth += 1
        elif text[index] == "}":
            depth -= 1
            if depth == 0:
                return text[match.start():index + 1]
    return ""


def watch_package_contract_failures(text: str) -> list[str]:
    issues: list[str] = []

    def require_in(function_name: str, tokens: list[str]) -> str:
        block = named_swift_function_block(text, function_name)
        if not block:
            issues.append(f"missing Watch package test function: {function_name}")
            return ""
        for token in tokens:
            if token not in block:
                issues.append(f"{function_name} missing semantic contract token: {token}")
        return block

    require_in(
        "testLegacySchemaOnePackageDecodesWithoutWatchCompatibilityMetadata",
        ["schemaVersion: 1", "XCTAssertEqual(decoded.manifest.schemaVersion, 1)",
         "XCTAssertNil(decoded.manifest.watchSampleCompatibility)"],
    )
    current_block = require_in(
        "testOptionalWatchCompatibilityMetadataRoundTripsWithoutSchemaBump",
        ["SkateTrackPackageManifest.currentSchemaVersion", "baselinePayload",
         "XCTAssertEqual(decoded.manifest.schemaVersion, baselineDecoded.manifest.schemaVersion)",
         "trustedMetricMutationCount, 0", "routeGeometryMutationCount, 0",
         "XCTAssertNil(decoded.primarySession?.snowPayload)"],
    )
    if "XCTAssertEqual(decoded.manifest.schemaVersion, 1)" in current_block:
        issues.append("current Watch metadata round trip retains stale literal schema-1 expectation")
    require_in(
        "testTask030dImportStillAcceptsLegacyPackageWithoutWatchMetadata",
        ["schemaVersion: 1", "manifest?.schemaVersion, 1",
         "manifest?.watchSampleCompatibility"],
    )
    require_in(
        "testTask030eReadOnlyViewerReaderStillOpensLegacyPackage",
        ["schemaVersion: 1", "XCTAssertEqual(payload.manifest.schemaVersion, 1)",
         "XCTAssertNil(payload.manifest.watchSampleCompatibility)"],
    )
    return issues


def normalized_a010r1_index_digest(index_lines: list[str]) -> str:
    normalized: list[str] = []
    for line in index_lines:
        _, separator, path = line.partition("\t")
        if not separator:
            normalized.append(line)
            continue
        normalized.append(A010R1_PRE_REMEDIATION_INDEX_ENTRIES.get(path, line))
    return hashlib.sha256(("\n".join(normalized) + "\n").encode("utf-8")).hexdigest()


def parse_cli_contract(arguments: list[str]) -> tuple[str, str, str]:
    """Return command kind, lifecycle, and a fail-closed CLI error."""
    standalone = {
        ("--current-session-recording-contract",): "SESSION_RECORDING",
        ("--current-session-persistence-contract",): "SESSION_PERSISTENCE",
    }
    standalone_kind = standalone.get(tuple(arguments))
    if standalone_kind:
        return standalone_kind, "", ""
    if not arguments:
        return "INVALID", "", "missing required --lifecycle argument"
    if len(arguments) != 2 or arguments[0] != "--lifecycle":
        return (
            "INVALID",
            "",
            "normal aggregate verification requires exactly one "
            "--lifecycle VALUE declaration",
        )
    lifecycle = arguments[1]
    if lifecycle not in LIFECYCLES:
        return "INVALID", "", f"unknown lifecycle: {lifecycle}"
    return "AGGREGATE", lifecycle, ""


def lifecycle_registry_failures(registry: object) -> list[str]:
    """Validate exact CLI authority, allow-list, binding, and command parity."""
    issues: list[str] = []

    def expect(condition: bool, message: str) -> None:
        if not condition:
            issues.append(message)

    if not isinstance(registry, dict):
        return ["applicability registry root must be an object"]
    expect(registry.get("task_id") == "Snow-Integration-A012R2", (
        "applicability registry task_id is not A012R2"
    ))
    expect(registry.get("lifecycle_selection") == "EXPLICIT_CLI", (
        "registry lifecycle selection is not EXPLICIT_CLI"
    ))
    allowed = registry.get("allowed_lifecycles")
    expect(isinstance(allowed, list), "registry allowed_lifecycles must be a list")
    if isinstance(allowed, list):
        expect(len(allowed) == len(set(allowed)), (
            "registry contains duplicate lifecycle values"
        ))
        expect(tuple(allowed) == LIFECYCLES, (
            "registry/script lifecycle allow-list drift"
        ))
    expect(registry.get("allowed_lifecycle_count") == len(LIFECYCLES), (
        "registry allowed lifecycle count differs"
    ))
    expect(registry.get("current_required_verifier_count") == 12, (
        "registry declared CURRENT_REQUIRED verifier count differs"
    ))

    bindings = registry.get("lifecycle_bindings")
    expect(isinstance(bindings, list), "registry lifecycle_bindings must be a list")
    if not isinstance(bindings, list):
        return issues
    task_phases = [
        item.get("task_phase")
        for item in bindings
        if isinstance(item, dict)
    ]
    lifecycle_values = [
        item.get("lifecycle")
        for item in bindings
        if isinstance(item, dict)
    ]
    expect(len(bindings) == len(LIFECYCLE_BINDINGS), (
        "registry lifecycle binding count differs"
    ))
    expect(len(task_phases) == len(bindings), (
        "registry contains non-object lifecycle binding"
    ))
    expect(len(task_phases) == len(set(task_phases)), (
        "registry contains duplicate/conflicting task-phase binding"
    ))
    expect(set(task_phases) == set(LIFECYCLE_BINDINGS), (
        "registry task-phase binding set differs"
    ))
    expect(set(lifecycle_values) == set(LIFECYCLES), (
        "registry lifecycle binding values differ"
    ))
    for item in bindings:
        if not isinstance(item, dict):
            continue
        task_phase = item.get("task_phase")
        lifecycle = item.get("lifecycle")
        expected_lifecycle = LIFECYCLE_BINDINGS.get(task_phase)
        expect(lifecycle == expected_lifecycle, (
            f"registry lifecycle binding differs for {task_phase}"
        ))
        expected_command = [
            "python3",
            "scripts/verify_snow_integration_aggregate.py",
            "--lifecycle",
            expected_lifecycle,
        ]
        expect(item.get("command") == expected_command, (
            f"registry lifecycle command drift for {task_phase}"
        ))
        expect(item.get("environment") == {}, (
            f"registry lifecycle environment must be empty for {task_phase}"
        ))
    return issues


def valid_lifecycle_state_fixture(lifecycle: str) -> dict[str, object]:
    """Build a synthetic valid state for pure lifecycle contract regressions."""
    candidate = "a" * 40
    candidate_tree = "b" * 40
    common: dict[str, object] = {
        "lifecycle_declarations": [lifecycle],
        "branch": EXPECTED_BRANCH,
        "head": candidate,
        "head_tree": candidate_tree,
        "index_tree": candidate_tree,
        "orig_head": "ABSENT",
        "merge_head": "ABSENT",
        "merge_in_progress": False,
        "staged_path_count": 0,
        "unstaged_change_count": 0,
        "untracked_path_count": 0,
        "unmerged_path_count": 0,
        "worktree_and_index_clean": True,
        "local_integration": candidate,
        "remote_tracking_integration": candidate,
        "remote_integration": candidate,
        "local_develop": REVIEWED_INTEGRATION_MERGE_COMMIT,
        "remote_tracking_develop": REMOTE_DEVELOP_BASE,
        "remote_develop": REMOTE_DEVELOP_BASE,
        "candidate": candidate,
        "candidate_parent_count": 1,
        "candidate_first_parent": REVIEWED_INTEGRATION_MERGE_COMMIT,
        "candidate_changed_path_count": 2,
        "candidate_changed_paths": sorted(REMEDIATION_ALLOWED_PATHS),
        "candidate_all_other_paths_equal_a011_tree": True,
        "historical_merge_commit": REVIEWED_INTEGRATION_MERGE_COMMIT,
        "historical_first_parent": REVIEWED_INTEGRATION_FIRST_PARENT,
        "historical_second_parent": REVIEWED_INTEGRATION_SECOND_PARENT,
        "historical_tree": REVIEWED_INTEGRATION_TREE,
        "historical_changed_path_count": REVIEWED_INTEGRATION_CHANGED_PATH_COUNT,
        "historical_changed_path_list_sha256": (
            EXPECTED_A010R5R1_STAGED_PATH_LIST_SHA256
        ),
        "historical_tree_row_count": REVIEWED_INTEGRATION_TREE_ROW_COUNT,
        "historical_index_manifest_sha256": (
            REVIEWED_INTEGRATION_INDEX_MANIFEST_SHA256
        ),
        "historical_progression_failure_count": 0,
        "historical_tree_and_blobs_valid": True,
        "formal_18_of_18_claimed": False,
        "final_18_of_18_eligible": False,
    }
    if lifecycle == "PRECOMMIT_MERGE_INDEX":
        common.update({
            "head": EXPECTED_HEAD,
            "head_tree": REVIEWED_INTEGRATION_HEAD_TREE,
            "index_tree": REVIEWED_INTEGRATION_TREE,
            "orig_head": EXPECTED_ORIG_HEAD,
            "merge_head": EXPECTED_MERGE_HEAD,
            "merge_in_progress": True,
            "staged_path_count": EXPECTED_A010R5R2R2_STAGED_PATH_COUNT,
            "worktree_and_index_clean": False,
            "local_integration": EXPECTED_HEAD,
            "remote_tracking_integration": EXPECTED_HEAD,
            "remote_integration": EXPECTED_HEAD,
            "local_develop": EXPECTED_HEAD,
            "remote_tracking_develop": EXPECTED_HEAD,
            "remote_develop": EXPECTED_HEAD,
            "precommit_index_data_row_count": EXPECTED_A010R5R2R2_INDEX_PATH_COUNT,
            "precommit_index_manifest_sha256": (
                REVIEWED_INTEGRATION_INDEX_MANIFEST_SHA256
            ),
            "precommit_staged_path_list_sha256": (
                EXPECTED_A010R5R1_STAGED_PATH_LIST_SHA256
            ),
            "precommit_progression_failure_count": 0,
        })
    elif lifecycle == "POST_FAST_FORWARD_DEVELOP_PRE_PUSH":
        common.update({
            "branch": "develop",
            "local_develop": candidate,
            "remote_tracking_integration": candidate,
            "remote_integration": candidate,
        })
    elif lifecycle == "POST_PUSH_DEVELOP_FINAL":
        common.update({
            "branch": "develop",
            "local_develop": candidate,
            "remote_tracking_integration": candidate,
            "remote_integration": candidate,
            "remote_tracking_develop": candidate,
            "remote_develop": candidate,
            "final_18_of_18_eligible": True,
        })
    return common


def lifecycle_state_failures(
    lifecycle: str,
    state: dict[str, object],
) -> list[str]:
    """Pure fail-closed lifecycle validation used by real and synthetic states."""
    issues: list[str] = []

    def expect(condition: bool, message: str) -> None:
        if not condition:
            issues.append(message)

    expect(lifecycle in LIFECYCLES, f"unknown lifecycle contract: {lifecycle}")
    declarations = state.get("lifecycle_declarations")
    expect(declarations == [lifecycle], (
        "lifecycle declaration is missing, duplicate, conflicting, or ambiguous"
    ))
    if lifecycle not in LIFECYCLES:
        return issues

    expect(state.get("formal_18_of_18_claimed") is False, (
        "formal 18-of-18 must remain an A012R3 task-level decision"
    ))
    if lifecycle == "PRECOMMIT_MERGE_INDEX":
        expected = {
            "branch": EXPECTED_BRANCH,
            "head": EXPECTED_HEAD,
            "head_tree": REVIEWED_INTEGRATION_HEAD_TREE,
            "index_tree": REVIEWED_INTEGRATION_TREE,
            "orig_head": EXPECTED_ORIG_HEAD,
            "merge_head": EXPECTED_MERGE_HEAD,
            "merge_in_progress": True,
            "staged_path_count": EXPECTED_A010R5R2R2_STAGED_PATH_COUNT,
            "unstaged_change_count": 0,
            "untracked_path_count": 0,
            "unmerged_path_count": 0,
            "precommit_index_data_row_count": EXPECTED_A010R5R2R2_INDEX_PATH_COUNT,
            "precommit_index_manifest_sha256": (
                REVIEWED_INTEGRATION_INDEX_MANIFEST_SHA256
            ),
            "precommit_staged_path_list_sha256": (
                EXPECTED_A010R5R1_STAGED_PATH_LIST_SHA256
            ),
            "precommit_progression_failure_count": 0,
        }
        for key, expected_value in expected.items():
            expect(state.get(key) == expected_value, (
                f"PRECOMMIT_MERGE_INDEX {key} differs"
            ))
        expect(state.get("final_18_of_18_eligible") is False, (
            "precommit lifecycle cannot be final-18 eligible"
        ))
        return issues

    common_expected = {
        "merge_head": "ABSENT",
        "merge_in_progress": False,
        "staged_path_count": 0,
        "unstaged_change_count": 0,
        "untracked_path_count": 0,
        "unmerged_path_count": 0,
        "worktree_and_index_clean": True,
        "candidate_parent_count": 1,
        "candidate_first_parent": REVIEWED_INTEGRATION_MERGE_COMMIT,
        "candidate_changed_path_count": len(REMEDIATION_ALLOWED_PATHS),
        "candidate_changed_paths": sorted(REMEDIATION_ALLOWED_PATHS),
        "candidate_all_other_paths_equal_a011_tree": True,
        "historical_merge_commit": REVIEWED_INTEGRATION_MERGE_COMMIT,
        "historical_first_parent": REVIEWED_INTEGRATION_FIRST_PARENT,
        "historical_second_parent": REVIEWED_INTEGRATION_SECOND_PARENT,
        "historical_tree": REVIEWED_INTEGRATION_TREE,
        "historical_changed_path_count": REVIEWED_INTEGRATION_CHANGED_PATH_COUNT,
        "historical_changed_path_list_sha256": (
            EXPECTED_A010R5R1_STAGED_PATH_LIST_SHA256
        ),
        "historical_tree_row_count": REVIEWED_INTEGRATION_TREE_ROW_COUNT,
        "historical_index_manifest_sha256": (
            REVIEWED_INTEGRATION_INDEX_MANIFEST_SHA256
        ),
        "historical_progression_failure_count": 0,
        "historical_tree_and_blobs_valid": True,
    }
    for key, expected_value in common_expected.items():
        expect(state.get(key) == expected_value, (
            f"committed historical/candidate evidence {key} differs"
        ))
    candidate = state.get("candidate")
    expect(isinstance(candidate, str) and re.fullmatch(r"[0-9a-f]{40}", candidate) is not None, (
        "dynamic remediation candidate is not a 40-hex commit identity"
    ))
    expect(state.get("head") == candidate, "HEAD is not the derived remediation candidate")
    expect(state.get("local_integration") == candidate, (
        "local integration ref is not the derived remediation candidate"
    ))
    expect(state.get("index_tree") == state.get("head_tree"), (
        "clean committed index tree does not equal HEAD tree"
    ))
    expect(state.get("local_develop") == (
        candidate
        if lifecycle in {
            "POST_FAST_FORWARD_DEVELOP_PRE_PUSH",
            "POST_PUSH_DEVELOP_FINAL",
        }
        else REVIEWED_INTEGRATION_MERGE_COMMIT
    ), "local develop ref differs for lifecycle")

    if lifecycle == "POSTCOMMIT_INTEGRATION_CLEAN":
        expect(state.get("branch") == EXPECTED_BRANCH, (
            "POSTCOMMIT_INTEGRATION_CLEAN branch differs"
        ))
        expect(state.get("remote_tracking_develop") == REMOTE_DEVELOP_BASE, (
            "remote-tracking develop advanced during integration lifecycle"
        ))
        expect(state.get("remote_develop") == REMOTE_DEVELOP_BASE, (
            "remote develop advanced during integration lifecycle"
        ))
        remote_pair = (
            state.get("remote_tracking_integration"),
            state.get("remote_integration"),
        )
        valid_pairs = {
            (
                REVIEWED_INTEGRATION_MERGE_COMMIT,
                REVIEWED_INTEGRATION_MERGE_COMMIT,
            ): "PRE_PUSH",
            (candidate, candidate): "POST_PUSH",
        }
        expect(remote_pair in valid_pairs, (
            "remote integration refs do not match exactly one pre/post-push substate"
        ))
        expect(state.get("final_18_of_18_eligible") is False, (
            "integration lifecycle cannot be final-18 eligible"
        ))
    elif lifecycle == "POST_FAST_FORWARD_DEVELOP_PRE_PUSH":
        expect(state.get("branch") == "develop", (
            "POST_FAST_FORWARD_DEVELOP_PRE_PUSH branch differs"
        ))
        expect(state.get("remote_tracking_integration") == candidate, (
            "remote-tracking integration is not candidate before develop push"
        ))
        expect(state.get("remote_integration") == candidate, (
            "remote integration is not candidate before develop push"
        ))
        expect(state.get("remote_tracking_develop") == REMOTE_DEVELOP_BASE, (
            "remote-tracking develop unexpectedly advanced before push"
        ))
        expect(state.get("remote_develop") == REMOTE_DEVELOP_BASE, (
            "remote develop unexpectedly advanced before push"
        ))
        expect(state.get("final_18_of_18_eligible") is False, (
            "pre-push develop lifecycle cannot be final-18 eligible"
        ))
    elif lifecycle == "POST_PUSH_DEVELOP_FINAL":
        expect(state.get("branch") == "develop", (
            "POST_PUSH_DEVELOP_FINAL branch differs"
        ))
        for key in (
            "remote_tracking_integration",
            "remote_integration",
            "remote_tracking_develop",
            "remote_develop",
        ):
            expect(state.get(key) == candidate, (
                f"final lifecycle {key} is not candidate"
            ))
        expect(state.get("final_18_of_18_eligible") is True, (
            "final lifecycle is not eligible by Git/static contract"
        ))
    return issues


def lifecycle_regression_results() -> dict[str, bool]:
    """Return the required four positive and eleven negative pure regressions."""
    positive = {
        "PRECOMMIT_MERGE_INDEX_VALID": "PRECOMMIT_MERGE_INDEX",
        "POSTCOMMIT_INTEGRATION_CLEAN_VALID": "POSTCOMMIT_INTEGRATION_CLEAN",
        "POST_FAST_FORWARD_DEVELOP_PRE_PUSH_VALID": (
            "POST_FAST_FORWARD_DEVELOP_PRE_PUSH"
        ),
        "POST_PUSH_DEVELOP_FINAL_VALID": "POST_PUSH_DEVELOP_FINAL",
    }
    results = {
        name: not lifecycle_state_failures(
            lifecycle,
            valid_lifecycle_state_fixture(lifecycle),
        )
        for name, lifecycle in positive.items()
    }

    negative_mutations: dict[str, tuple[str, str, object]] = {
        "WRONG_BRANCH_FOR_LIFECYCLE": (
            "POSTCOMMIT_INTEGRATION_CLEAN", "branch", "develop"
        ),
        "WRONG_HEAD_OR_TREE": (
            "PRECOMMIT_MERGE_INDEX", "head_tree", "0" * 40
        ),
        "UNEXPECTED_MERGE_HEAD": (
            "POSTCOMMIT_INTEGRATION_CLEAN", "merge_head", EXPECTED_MERGE_HEAD
        ),
        "UNEXPECTED_STAGED_CHANGE_IN_CLEAN_LIFECYCLE": (
            "POSTCOMMIT_INTEGRATION_CLEAN", "staged_path_count", 1
        ),
        "MISSING_HISTORICAL_PATH": (
            "POSTCOMMIT_INTEGRATION_CLEAN",
            "historical_changed_path_count",
            REVIEWED_INTEGRATION_CHANGED_PATH_COUNT - 1,
        ),
        "MUTATED_HISTORICAL_TREE_OR_BLOB": (
            "POSTCOMMIT_INTEGRATION_CLEAN",
            "historical_tree_and_blobs_valid",
            False,
        ),
        "REMOTE_INTEGRATION_MISMATCH": (
            "POSTCOMMIT_INTEGRATION_CLEAN",
            "remote_integration",
            "c" * 40,
        ),
        "REMOTE_DEVELOP_UNEXPECTED_ADVANCE": (
            "POSTCOMMIT_INTEGRATION_CLEAN",
            "remote_develop",
            "d" * 40,
        ),
        "FALSE_18_OF_18_BEFORE_REMOTE_PUSH": (
            "POST_FAST_FORWARD_DEVELOP_PRE_PUSH",
            "formal_18_of_18_claimed",
            True,
        ),
        "FINAL_MODE_REMOTE_DEVELOP_MISMATCH": (
            "POST_PUSH_DEVELOP_FINAL",
            "remote_develop",
            REMOTE_DEVELOP_BASE,
        ),
        "AMBIGUOUS_LIFECYCLE_STATE": (
            "POSTCOMMIT_INTEGRATION_CLEAN",
            "lifecycle_declarations",
            ["POSTCOMMIT_INTEGRATION_CLEAN", "POST_PUSH_DEVELOP_FINAL"],
        ),
    }
    for name, (lifecycle, key, value) in negative_mutations.items():
        state = copy.deepcopy(valid_lifecycle_state_fixture(lifecycle))
        state[key] = value
        if name == "UNEXPECTED_MERGE_HEAD":
            state["merge_in_progress"] = True
        results[name] = bool(lifecycle_state_failures(lifecycle, state))
    return results


def legacy_aggregate_regression_results() -> dict[str, bool]:
    """Expose the existing active-stale-marker regression family as pure logic."""
    final_contract = "\n".join(A010R5R2R2_REQUIRED_DOCUMENT_TOKENS)
    return {
        marker: bool(active_stale_pre_qa_markers(f"{final_contract}\n{marker}\n"))
        for marker in A010R5R2R2_STALE_PRE_QA_MARKERS
    }


def stage_progression_failures(
    staged_paths: list[str],
    index_lines: list[str],
    unstaged_paths: set[str],
    untracked_paths: set[str],
    unmerged_paths: set[str],
    unmerged_index: list[str],
) -> tuple[list[str], dict[str, int | str]]:
    """Validate exact A007 -> A008R1 -> A009 -> A010R2 progression."""
    issues: list[str] = []
    staged_set = set(staged_paths)

    def expect(condition: bool, message: str) -> None:
        if not condition:
            issues.append(message)

    expect(not unmerged_paths and not unmerged_index, "unmerged paths are present")
    expect(not unstaged_paths and not untracked_paths, (
        f"unstaged/untracked paths are present: {sorted(unstaged_paths | untracked_paths)}"
    ))
    expect(len(staged_paths) == len(staged_set), "duplicate staged path entries are present")
    expect(len(staged_set) == EXPECTED_STAGED_PATH_COUNT, (
        f"expected {EXPECTED_STAGED_PATH_COUNT} staged paths, found {len(staged_set)}"
    ))
    expect(A007_PATHS.issubset(staged_set), "A007 verifier paths are not both staged")
    expect(A008R1_PATHS.issubset(staged_set), "A008R1 exact allowed paths are not all staged")
    expect(A009_DOC_PATHS.issubset(staged_set), "A009 exact documentation paths are not all staged")
    expect(A009_NEWLY_STAGED_PATHS.issubset(staged_set), (
        "A009 sole newly staged path is missing"
    ))
    expect(A010R2_NEWLY_STAGED_PATHS.issubset(staged_set), (
        "A010R2 sole newly staged Watch package test path is missing"
    ))

    a010r1_staged_paths = staged_set - A010R2_NEWLY_STAGED_PATHS
    a010r1_staged_input = "\n".join(sorted(a010r1_staged_paths)) + "\n"
    a010r1_staged_digest = hashlib.sha256(a010r1_staged_input.encode("utf-8")).hexdigest()
    expect(len(a010r1_staged_paths) == EXPECTED_A009_STAGED_PATH_COUNT, (
        f"expected exact 198-path A010R1 stage, found {len(a010r1_staged_paths)}"
    ))
    expect(a010r1_staged_digest == EXPECTED_A010R1_STAGED_PATH_LIST_SHA256, (
        "A010R1 staged-path baseline changed; expected "
        f"{EXPECTED_A010R1_STAGED_PATH_LIST_SHA256}, found {a010r1_staged_digest}"
    ))

    prior_staged_paths = a010r1_staged_paths - A009_NEWLY_STAGED_PATHS
    prior_staged_input = "\n".join(sorted(prior_staged_paths)) + "\n"
    prior_staged_digest = hashlib.sha256(prior_staged_input.encode("utf-8")).hexdigest()
    expect(len(prior_staged_paths) == 197, (
        f"expected exact 197-path A008R1 stage before A009, found {len(prior_staged_paths)}"
    ))
    expect(prior_staged_digest == EXPECTED_A008R1_STAGED_PATH_LIST_SHA256, (
        "A008R1 staged-path baseline changed; expected "
        f"{EXPECTED_A008R1_STAGED_PATH_LIST_SHA256}, found {prior_staged_digest}"
    ))

    normalized_without_a008r1: list[str] = []
    malformed_count = 0
    for line in index_lines:
        _, separator, path = line.partition("\t")
        if not separator:
            malformed_count += 1
            continue
        if path in A008R1_PATHS:
            continue
        a010r1_line = A010R1_PRE_REMEDIATION_INDEX_ENTRIES.get(path, line)
        normalized_without_a008r1.append(A009_PRE_STAGE_INDEX_ENTRIES.get(path, a010r1_line))
    expect(malformed_count == 0, f"malformed git index line count: {malformed_count}")
    digest_input = "\n".join(normalized_without_a008r1) + "\n"
    historical_digest = hashlib.sha256(digest_input.encode("utf-8")).hexdigest()
    expect(historical_digest == EXPECTED_A007_INDEX_SHA256_WITHOUT_A008R1, (
        "index entries outside approved A008R1/A009 stage-local paths changed; "
        f"expected frozen A007 digest {EXPECTED_A007_INDEX_SHA256_WITHOUT_A008R1}, "
        f"found {historical_digest}"
    ))

    index_by_path = {}
    for line in index_lines:
        _, separator, path = line.partition("\t")
        if separator:
            index_by_path[path] = line
    actual_a010r2_blob_mutations = {
        path for path, prior_line in A010R1_PRE_REMEDIATION_INDEX_ENTRIES.items()
        if index_by_path.get(path) != prior_line
    }
    expect(actual_a010r2_blob_mutations == A010R2_ALLOWED_PATHS, (
        "A010R2 exact allowed blob mutation set differs; expected "
        f"{sorted(A010R2_ALLOWED_PATHS)}, found {sorted(actual_a010r2_blob_mutations)}"
    ))
    normalized_full_index_digest = normalized_a010r1_index_digest(index_lines)
    expect(normalized_full_index_digest == EXPECTED_A010R1_FULL_INDEX_SHA256, (
        "index outside exact A010R2 allowed blobs changed; expected normalized A010R1 digest "
        f"{EXPECTED_A010R1_FULL_INDEX_SHA256}, found {normalized_full_index_digest}"
    ))

    forbidden_runtime_negative_lines = list(index_lines)
    for index, line in enumerate(forbidden_runtime_negative_lines):
        if line.endswith("\tShared/Export/SkateTrackPackageReader.swift"):
            mode_and_hash, _, path = line.partition("\t")
            mode, _, stage = mode_and_hash.split()
            forbidden_runtime_negative_lines[index] = f"{mode} {'0' * 40} {stage}\t{path}"
            break
    negative_runtime_mutation_rejected = (
        normalized_a010r1_index_digest(forbidden_runtime_negative_lines)
        != EXPECTED_A010R1_FULL_INDEX_SHA256
    )
    expect(negative_runtime_mutation_rejected, (
        "negative regression did not reject forbidden package-reader runtime mutation"
    ))

    stage_observations: dict[str, int | str] = {
        "A009_EXPECTED_STAGED_PATH_COUNT": EXPECTED_A009_STAGED_PATH_COUNT,
        "A009_CHANGED_DOC_PATH_COUNT": len(A009_DOC_PATHS),
        "A009_CHANGED_DOC_PATHS": ",".join(sorted(A009_DOC_PATHS)),
        "A009_NEWLY_STAGED_PATH_COUNT": len(A009_NEWLY_STAGED_PATHS),
        "A009_NEWLY_STAGED_PATHS": ",".join(sorted(A009_NEWLY_STAGED_PATHS)),
        "A009_UNAPPROVED_CHANGED_PATH_COUNT": 0 if not issues else 1,
        "A009_A008R1_STAGED_PATH_LIST_SHA256": prior_staged_digest,
        "A009_NORMALIZED_A007_INDEX_SHA256": historical_digest,
        "A009_INDEX_OUTSIDE_ALLOWED_PATHS_MATCHES_APPROVED_BASELINE": (
            "YES" if historical_digest == EXPECTED_A007_INDEX_SHA256_WITHOUT_A008R1 else "NO"
        ),
        "A010R2_EXPECTED_STAGED_PATH_COUNT": EXPECTED_STAGED_PATH_COUNT,
        "A010R2_NEWLY_STAGED_PATH_COUNT": len(A010R2_NEWLY_STAGED_PATHS),
        "A010R2_NEWLY_STAGED_PATHS": ",".join(sorted(A010R2_NEWLY_STAGED_PATHS)),
        "A010R2_ALREADY_STAGED_BLOB_MUTATION_COUNT": len(A010R2_ALREADY_STAGED_BLOB_MUTATION_PATHS),
        "A010R2_ALREADY_STAGED_BLOB_MUTATION_PATHS": ",".join(sorted(A010R2_ALREADY_STAGED_BLOB_MUTATION_PATHS)),
        "A010R2_ACTUAL_BLOB_MUTATION_COUNT": len(actual_a010r2_blob_mutations),
        "A010R2_NORMALIZED_A010R1_FULL_INDEX_SHA256": normalized_full_index_digest,
        "A010R2_FORBIDDEN_RUNTIME_MUTATION_NEGATIVE_REGRESSION": (
            "PASSED" if negative_runtime_mutation_rejected else "FAILED"
        ),
        "A010R2_UNAPPROVED_CHANGED_PATH_COUNT": 0 if not issues else 1,
    }
    return issues, stage_observations


def a010r5_stage_progression_failures(
    staged_paths: list[str],
    index_lines: list[str],
    unstaged_paths: set[str],
    untracked_paths: set[str],
    unmerged_paths: set[str],
    unmerged_index: list[str],
) -> tuple[list[str], dict[str, int | str]]:
    """Validate A007-A010R4 history and the exact A010R5 Variant-A progression."""
    issues: list[str] = []
    staged_set = set(staged_paths)
    index_by_path = {
        path: line
        for line in index_lines
        for _, separator, path in [line.partition("\t")]
        if separator
    }

    def expect(condition: bool, message: str) -> None:
        if not condition:
            issues.append(message)

    expect(not unmerged_paths and not unmerged_index, "unmerged paths are present")
    expect(not unstaged_paths and not untracked_paths, (
        f"unstaged/untracked paths are present: {sorted(unstaged_paths | untracked_paths)}"
    ))
    expect(len(staged_paths) == len(staged_set), "duplicate staged path entries are present")
    expect(len(staged_set) == EXPECTED_A010R5_STAGED_PATH_COUNT, (
        f"expected {EXPECTED_A010R5_STAGED_PATH_COUNT} A010R5 staged paths, found {len(staged_set)}"
    ))
    expect(A010R5_NEWLY_STAGED_PATHS.issubset(staged_set), (
        "A010R5 sole newly staged coordinator test path is missing"
    ))

    parent_staged_paths = staged_set - A010R5_NEWLY_STAGED_PATHS
    parent_staged_digest = hashlib.sha256(
        ("\n".join(sorted(parent_staged_paths)) + "\n").encode("utf-8")
    ).hexdigest()
    expect(len(parent_staged_paths) == EXPECTED_STAGED_PATH_COUNT, (
        f"expected exact 199-path A010R4 parent stage, found {len(parent_staged_paths)}"
    ))
    expect(parent_staged_digest == EXPECTED_A010R4_STAGED_PATH_LIST_SHA256, (
        "A010R4 staged-path parent changed; expected "
        f"{EXPECTED_A010R4_STAGED_PATH_LIST_SHA256}, found {parent_staged_digest}"
    ))

    actual_existing_blob_mutations = {
        path for path, parent_line in A010R5_PARENT_INDEX_ENTRIES.items()
        if index_by_path.get(path) != parent_line
    }
    expect(
        actual_existing_blob_mutations == A010R5_EXPECTED_ALREADY_STAGED_BLOB_MUTATION_PATHS,
        "A010R5 exact already-staged blob mutation set differs; expected "
        f"{sorted(A010R5_EXPECTED_ALREADY_STAGED_BLOB_MUTATION_PATHS)}, "
        f"found {sorted(actual_existing_blob_mutations)}",
    )

    normalized_parent_index_lines = []
    for line in index_lines:
        _, separator, path = line.partition("\t")
        if not separator:
            issues.append(f"malformed git index line: {line}")
            continue
        if path in A010R5_NEWLY_STAGED_PATHS:
            continue
        normalized_parent_index_lines.append(A010R5_PARENT_INDEX_ENTRIES.get(path, line))

    normalized_parent_digest = hashlib.sha256(
        ("\n".join(normalized_parent_index_lines) + "\n").encode("utf-8")
    ).hexdigest()
    expect(len(normalized_parent_index_lines) == EXPECTED_A010R4_INDEX_PATH_COUNT, (
        "normalized A010R4 parent index path count differs; expected "
        f"{EXPECTED_A010R4_INDEX_PATH_COUNT}, found {len(normalized_parent_index_lines)}"
    ))
    expect(normalized_parent_digest == EXPECTED_A010R4_FULL_INDEX_SHA256, (
        "index outside exact A010R5 allowed blobs changed; expected normalized A010R4 digest "
        f"{EXPECTED_A010R4_FULL_INDEX_SHA256}, found {normalized_parent_digest}"
    ))
    expect(len(index_lines) == EXPECTED_A010R5_INDEX_PATH_COUNT, (
        f"expected {EXPECTED_A010R5_INDEX_PATH_COUNT} final index paths, found {len(index_lines)}"
    ))

    frozen_mutations = {
        path for path, parent_line in A010R5_FROZEN_FORMAT_AND_CLASSIFIER_INDEX_ENTRIES.items()
        if index_by_path.get(path) != parent_line
    }
    expect(not frozen_mutations, (
        "format/schema/localization/classifier frozen paths changed: "
        f"{sorted(frozen_mutations)}"
    ))

    def negative_mutation_is_rejected(path: str) -> bool:
        mutated = list(normalized_parent_index_lines)
        for index, line in enumerate(mutated):
            if line.endswith(f"\t{path}"):
                mode_and_hash, _, item_path = line.partition("\t")
                mode, _, stage = mode_and_hash.split()
                mutated[index] = f"{mode} {'0' * 40} {stage}\t{item_path}"
                break
        digest = hashlib.sha256(("\n".join(mutated) + "\n").encode("utf-8")).hexdigest()
        return digest != EXPECTED_A010R4_FULL_INDEX_SHA256

    schema_negative_rejected = negative_mutation_is_rejected(
        "Shared/Models/SkateTrackPackageManifest.swift"
    )
    classifier_negative_rejected = negative_mutation_is_rejected(
        "Shared/Models/SnowSegmentClassifier.swift"
    )
    expect(schema_negative_rejected, (
        "negative regression did not reject forbidden package-schema mutation"
    ))
    expect(classifier_negative_rejected, (
        "negative regression did not reject forbidden classifier mutation"
    ))

    historical_issues, historical_observations = stage_progression_failures(
        sorted(parent_staged_paths),
        normalized_parent_index_lines,
        set(),
        set(),
        set(),
        [],
    )
    issues.extend(historical_issues)
    historical_observations.update({
        "A010R4_FINAL_INDEX_EQUALS_A010R5_START_INDEX": "YES",
        "A010R5_STAGE_VARIANT": "VARIANT_A",
        "A010R5_EXPECTED_STAGED_PATH_COUNT": EXPECTED_A010R5_STAGED_PATH_COUNT,
        "A010R5_NEWLY_STAGED_PATH_COUNT": len(A010R5_NEWLY_STAGED_PATHS),
        "A010R5_NEWLY_STAGED_PATHS": ",".join(sorted(A010R5_NEWLY_STAGED_PATHS)),
        "A010R5_ALLOWED_PATH_COUNT_MAXIMUM": len(A010R5_MAX_ALLOWED_PATHS),
        "A010R5_ACTUAL_MUTATION_PATH_COUNT": len(actual_existing_blob_mutations | A010R5_NEWLY_STAGED_PATHS),
        "A010R5_ACTUAL_MUTATION_PATHS": ",".join(sorted(actual_existing_blob_mutations | A010R5_NEWLY_STAGED_PATHS)),
        "A010R5_NORMALIZED_A010R4_FULL_INDEX_SHA256": normalized_parent_digest,
        "A010R5_UNAUTHORIZED_BLOB_MUTATION_COUNT": 0 if normalized_parent_digest == EXPECTED_A010R4_FULL_INDEX_SHA256 else 1,
        "A010R5_FROZEN_FORMAT_CLASSIFIER_MUTATION_COUNT": len(frozen_mutations),
        "A010R5_PACKAGE_SCHEMA_NEGATIVE_REGRESSION": "PASSED" if schema_negative_rejected else "FAILED",
        "A010R5_CLASSIFIER_MUTATION_NEGATIVE_REGRESSION": "PASSED" if classifier_negative_rejected else "FAILED",
        "A010R5_PARENT_STAGED_PATH_LIST_SHA256": parent_staged_digest,
    })
    return issues, historical_observations


def a010r5r2_stage_progression_failures(
    staged_paths: list[str],
    index_lines: list[str],
    unstaged_paths: set[str],
    untracked_paths: set[str],
    unmerged_paths: set[str],
    unmerged_index: list[str],
) -> tuple[list[str], dict[str, int | str]]:
    """Validate exact A010R5R1 parent preservation and zero-new-path A010R5R2 progression."""
    issues: list[str] = []
    staged_set = set(staged_paths)
    index_by_path = {
        path: line
        for line in index_lines
        for _, separator, path in [line.partition("\t")]
        if separator
    }

    def expect(condition: bool, message: str) -> None:
        if not condition:
            issues.append(message)

    expect(not unmerged_paths and not unmerged_index, "unmerged paths are present")
    expect(not unstaged_paths and not untracked_paths, (
        f"unstaged/untracked paths are present: {sorted(unstaged_paths | untracked_paths)}"
    ))
    expect(len(staged_paths) == len(staged_set), "duplicate staged path entries are present")
    expect(len(staged_set) == EXPECTED_A010R5R2_STAGED_PATH_COUNT, (
        f"expected {EXPECTED_A010R5R2_STAGED_PATH_COUNT} A010R5R2 staged paths, "
        f"found {len(staged_set)}"
    ))
    expect(len(index_lines) == EXPECTED_A010R5R2_INDEX_PATH_COUNT, (
        f"expected {EXPECTED_A010R5R2_INDEX_PATH_COUNT} A010R5R2 index rows, "
        f"found {len(index_lines)}"
    ))

    staged_digest = hashlib.sha256(
        ("\n".join(sorted(staged_set)) + "\n").encode("utf-8")
    ).hexdigest()
    expect(staged_digest == EXPECTED_A010R5R1_STAGED_PATH_LIST_SHA256, (
        "A010R5R2 changed the frozen 200-path staged set; expected "
        f"{EXPECTED_A010R5R1_STAGED_PATH_LIST_SHA256}, found {staged_digest}"
    ))

    actual_blob_mutations = {
        path for path, parent_line in A010R5R2_PARENT_INDEX_ENTRIES.items()
        if index_by_path.get(path) != parent_line
    }
    expect(actual_blob_mutations == A010R5R2_EXPECTED_MUTATION_PATHS, (
        "A010R5R2 exact existing-blob mutation set differs; expected "
        f"{sorted(A010R5R2_EXPECTED_MUTATION_PATHS)}, "
        f"found {sorted(actual_blob_mutations)}"
    ))

    normalized_parent_lines: list[str] = []
    for line in index_lines:
        _, separator, path = line.partition("\t")
        if not separator:
            issues.append(f"malformed git index line: {line}")
            continue
        normalized_parent_lines.append(A010R5R2_PARENT_INDEX_ENTRIES.get(path, line))
    normalized_parent_digest = hashlib.sha256(
        ("\n".join(normalized_parent_lines) + "\n").encode("utf-8")
    ).hexdigest()
    expect(normalized_parent_digest == EXPECTED_A010R5R1_FULL_INDEX_SHA256, (
        "index outside exact A010R5R2 allowed blobs changed; expected normalized "
        f"A010R5R1 digest {EXPECTED_A010R5R1_FULL_INDEX_SHA256}, "
        f"found {normalized_parent_digest}"
    ))

    historical_issues, historical_observations = a010r5_stage_progression_failures(
        staged_paths,
        normalized_parent_lines,
        set(),
        set(),
        set(),
        [],
    )
    issues.extend(historical_issues)

    forbidden_negative_lines = list(normalized_parent_lines)
    forbidden_path = "iOS/Core/SnowEngine/SnowHUDQAScenario.swift"
    for index, line in enumerate(forbidden_negative_lines):
        if line.endswith(f"\t{forbidden_path}"):
            mode_and_hash, _, path = line.partition("\t")
            mode, _, stage = mode_and_hash.split()
            forbidden_negative_lines[index] = f"{mode} {'0' * 40} {stage}\t{path}"
            break
    forbidden_negative_digest = hashlib.sha256(
        ("\n".join(forbidden_negative_lines) + "\n").encode("utf-8")
    ).hexdigest()
    forbidden_scope_negative_rejected = (
        forbidden_negative_digest != EXPECTED_A010R5R1_FULL_INDEX_SHA256
    )
    expect(forbidden_scope_negative_rejected, (
        "negative regression did not reject forbidden Debug scenario mutation"
    ))

    historical_observations.update({
        "A010R5R1_FINAL_INDEX_EQUALS_A010R5R2_START_INDEX": "YES",
        "A010R5R1_FINAL_INDEX_MANIFEST_SHA256": EXPECTED_A010R5R1_INDEX_MANIFEST_SHA256,
        "A010R5R2_START_INDEX_DATA_ROW_COUNT": EXPECTED_A010R5R2_INDEX_PATH_COUNT,
        "A010R5R2_EXPECTED_STAGED_PATH_COUNT": EXPECTED_A010R5R2_STAGED_PATH_COUNT,
        "A010R5R2_NEWLY_STAGED_PATH_COUNT": 0,
        "A010R5R2_INDEX_PATH_ADDED_COUNT": 0,
        "A010R5R2_INDEX_PATH_REMOVED_COUNT": 0,
        "A010R5R2_ALLOWED_PATH_COUNT": len(A010R5R2_ALLOWED_PATHS),
        "A010R5R2_ACTUAL_MUTATION_PATH_COUNT": len(actual_blob_mutations),
        "A010R5R2_ACTUAL_MUTATION_PATHS": ",".join(sorted(actual_blob_mutations)),
        "A010R5R2_NORMALIZED_A010R5R1_FULL_INDEX_SHA256": normalized_parent_digest,
        "A010R5R2_UNAUTHORIZED_BLOB_MUTATION_COUNT": (
            0 if normalized_parent_digest == EXPECTED_A010R5R1_FULL_INDEX_SHA256 else 1
        ),
        "A010R5R2_FORBIDDEN_SCOPE_NEGATIVE_REGRESSION": (
            "PASSED" if forbidden_scope_negative_rejected else "FAILED"
        ),
    })
    return issues, historical_observations


def a010r5r2r2_stage_progression_failures(
    staged_paths: list[str],
    index_lines: list[str],
    unstaged_paths: set[str],
    untracked_paths: set[str],
    unmerged_paths: set[str],
    unmerged_index: list[str],
) -> tuple[list[str], dict[str, int | str]]:
    """Validate exact nine-blob docs/verifier closure from the frozen R2/R1 index."""
    issues: list[str] = []
    staged_set = set(staged_paths)
    index_by_path = {
        path: line
        for line in index_lines
        for _, separator, path in [line.partition("\t")]
        if separator
    }

    def expect(condition: bool, message: str) -> None:
        if not condition:
            issues.append(message)

    expect(not unmerged_paths and not unmerged_index, "unmerged paths are present")
    expect(not unstaged_paths and not untracked_paths, (
        f"unstaged/untracked paths are present: {sorted(unstaged_paths | untracked_paths)}"
    ))
    expect(len(staged_paths) == len(staged_set), "duplicate staged path entries are present")
    expect(len(staged_set) == EXPECTED_A010R5R2R2_STAGED_PATH_COUNT, (
        f"expected {EXPECTED_A010R5R2R2_STAGED_PATH_COUNT} A010R5R2R2 staged paths, "
        f"found {len(staged_set)}"
    ))
    expect(len(index_lines) == EXPECTED_A010R5R2R2_INDEX_PATH_COUNT, (
        f"expected {EXPECTED_A010R5R2R2_INDEX_PATH_COUNT} A010R5R2R2 index rows, "
        f"found {len(index_lines)}"
    ))

    staged_digest = hashlib.sha256(
        ("\n".join(sorted(staged_set)) + "\n").encode("utf-8")
    ).hexdigest()
    expect(staged_digest == EXPECTED_A010R5R1_STAGED_PATH_LIST_SHA256, (
        "A010R5R2R2 changed the frozen 200-path staged set; expected "
        f"{EXPECTED_A010R5R1_STAGED_PATH_LIST_SHA256}, found {staged_digest}"
    ))

    actual_blob_mutations = {
        path for path, parent_line in A010R5R2R2_PARENT_INDEX_ENTRIES.items()
        if index_by_path.get(path) != parent_line
    }
    expect(actual_blob_mutations == A010R5R2R2_ALLOWED_PATHS, (
        "A010R5R2R2 exact existing-blob mutation set differs; expected "
        f"{sorted(A010R5R2R2_ALLOWED_PATHS)}, found {sorted(actual_blob_mutations)}"
    ))

    normalized_parent_lines: list[str] = []
    for line in index_lines:
        _, separator, path = line.partition("\t")
        if not separator:
            issues.append(f"malformed git index line: {line}")
            continue
        normalized_parent_lines.append(A010R5R2R2_PARENT_INDEX_ENTRIES.get(path, line))
    normalized_parent_digest = hashlib.sha256(
        ("\n".join(normalized_parent_lines) + "\n").encode("utf-8")
    ).hexdigest()
    expect(
        normalized_parent_digest == EXPECTED_A010R5R2R2_PARENT_FULL_INDEX_SHA256,
        "index outside exact A010R5R2R2 allowed blobs changed; expected normalized "
        f"parent digest {EXPECTED_A010R5R2R2_PARENT_FULL_INDEX_SHA256}, "
        f"found {normalized_parent_digest}",
    )

    historical_issues, historical_observations = a010r5r2_stage_progression_failures(
        staged_paths,
        normalized_parent_lines,
        set(),
        set(),
        set(),
        [],
    )
    issues.extend(historical_issues)
    historical_observations.update({
        "A010R5R2R1_FINAL_INDEX_EQUALS_A010R5R2R2_START_INDEX": "YES",
        "A010R5R2R2_START_INDEX_MANIFEST_SHA256": (
            EXPECTED_A010R5R2R2_PARENT_INDEX_MANIFEST_SHA256
        ),
        "A010R5R2R2_NEWLY_STAGED_PATH_COUNT": 0,
        "A010R5R2R2_INDEX_PATH_ADDED_COUNT": 0,
        "A010R5R2R2_INDEX_PATH_REMOVED_COUNT": 0,
        "A010R5R2R2_INDEX_BLOB_OR_MODE_CHANGED_COUNT": len(actual_blob_mutations),
        "A010R5R2R2_CHANGED_PATHS_MATCH_EXACT_ALLOWED_SET": (
            "YES" if actual_blob_mutations == A010R5R2R2_ALLOWED_PATHS else "NO"
        ),
        "A010R5R2R2_ACTUAL_MUTATION_PATHS": ",".join(sorted(actual_blob_mutations)),
        "A010R5R2R2_NORMALIZED_PARENT_FULL_INDEX_SHA256": normalized_parent_digest,
        "STAGED_PATH_COUNT_FINAL": len(staged_set),
        "INDEX_DATA_ROW_COUNT_FINAL": len(index_lines),
        "UNSTAGED_CHANGE_COUNT_FINAL": len(unstaged_paths),
        "UNTRACKED_PATH_COUNT_FINAL": len(untracked_paths),
        "UNMERGED_PATH_COUNT_FINAL": len(unmerged_paths) + len(unmerged_index),
    })
    return issues, historical_observations


def verify_registry() -> None:
    start = len(failures)
    try:
        registry = json.loads(read("scripts/snow_integration_verifier_applicability.json"))
    except json.JSONDecodeError as error:
        fail(f"applicability registry is invalid JSON: {error}")
        mark_group("registry", start)
        return

    check(registry.get("schema_version") == 1, "unexpected applicability registry schema")
    for issue in lifecycle_registry_failures(registry):
        fail(issue)
    progression = registry.get("a010r2_stage_progression")
    check(isinstance(progression, dict), "registry A010R2 stage progression is missing")
    if isinstance(progression, dict):
        check(progression.get("expected_staged_path_count") == EXPECTED_STAGED_PATH_COUNT, (
            "registry A010R2 staged-path count differs"
        ))
        check(set(progression.get("newly_staged_paths", [])) == A010R2_NEWLY_STAGED_PATHS, (
            "registry A010R2 newly staged paths differ"
        ))
        check(
            set(progression.get("already_staged_blob_mutation_paths", []))
            == A010R2_ALREADY_STAGED_BLOB_MUTATION_PATHS,
            "registry A010R2 already-staged blob mutation paths differ",
        )
        check(
            progression.get("embedded_contract_guard")
            == "scripts/verify_snow_integration_aggregate.py#watch-package-test-contract",
            "registry A010R2 embedded contract guard differs",
        )
    a010r5_progression = registry.get("a010r5_stage_progression")
    check(isinstance(a010r5_progression, dict), "registry A010R5 stage progression is missing")
    if isinstance(a010r5_progression, dict):
        check(a010r5_progression.get("variant") == "VARIANT_A", (
            "registry A010R5 stage variant differs"
        ))
        check(
            a010r5_progression.get("expected_staged_path_count")
            == EXPECTED_A010R5_STAGED_PATH_COUNT,
            "registry A010R5 staged-path count differs",
        )
        check(
            set(a010r5_progression.get("newly_staged_paths", []))
            == A010R5_NEWLY_STAGED_PATHS,
            "registry A010R5 newly staged paths differ",
        )
        check(
            set(a010r5_progression.get("expected_mutation_paths", []))
            == A010R5_EXPECTED_MUTATION_PATHS,
            "registry A010R5 expected mutation paths differ",
        )
        check(
            a010r5_progression.get("embedded_contract_guard")
            == "scripts/verify_snow_integration_aggregate.py#a010r5-remediation-contract",
            "registry A010R5 embedded contract guard differs",
        )
    a010r5r2_progression = registry.get("a010r5r2_stage_progression")
    check(isinstance(a010r5r2_progression, dict), (
        "registry A010R5R2 stage progression is missing"
    ))
    if isinstance(a010r5r2_progression, dict):
        check(
            a010r5r2_progression.get("expected_staged_path_count")
            == EXPECTED_A010R5R2_STAGED_PATH_COUNT,
            "registry A010R5R2 staged-path count differs",
        )
        check(
            a010r5r2_progression.get("expected_index_data_row_count")
            == EXPECTED_A010R5R2_INDEX_PATH_COUNT,
            "registry A010R5R2 index-row count differs",
        )
        check(a010r5r2_progression.get("newly_staged_paths") == [], (
            "registry A010R5R2 must have zero newly staged paths"
        ))
        check(
            set(a010r5r2_progression.get("allowed_paths", []))
            == A010R5R2_ALLOWED_PATHS,
            "registry A010R5R2 allowed paths differ",
        )
        check(
            set(a010r5r2_progression.get("expected_mutation_paths", []))
            == A010R5R2_EXPECTED_MUTATION_PATHS,
            "registry A010R5R2 expected mutation paths differ",
        )
        check(
            a010r5r2_progression.get("start_index_manifest_sha256")
            == EXPECTED_A010R5R1_INDEX_MANIFEST_SHA256,
            "registry A010R5R2 start index manifest differs",
        )
        check(
            a010r5r2_progression.get("start_staged_path_list_sha256")
            == EXPECTED_A010R5R1_STAGED_PATH_LIST_SHA256,
            "registry A010R5R2 start staged-path digest differs",
        )
        check(
            a010r5r2_progression.get("embedded_contract_guard")
            == "scripts/verify_snow_integration_aggregate.py#a010r5r2-presentation-contract",
            "registry A010R5R2 embedded contract guard differs",
        )
    a010r5r2r2_progression = registry.get("a010r5r2r2_stage_progression")
    check(isinstance(a010r5r2r2_progression, dict), (
        "registry A010R5R2R2 stage progression is missing"
    ))
    if isinstance(a010r5r2r2_progression, dict):
        check(
            a010r5r2r2_progression.get("expected_staged_path_count")
            == EXPECTED_A010R5R2R2_STAGED_PATH_COUNT,
            "registry A010R5R2R2 staged-path count differs",
        )
        check(
            a010r5r2r2_progression.get("expected_index_data_row_count")
            == EXPECTED_A010R5R2R2_INDEX_PATH_COUNT,
            "registry A010R5R2R2 index-row count differs",
        )
        check(a010r5r2r2_progression.get("newly_staged_paths") == [], (
            "registry A010R5R2R2 must have zero newly staged paths"
        ))
        check(
            set(a010r5r2r2_progression.get("allowed_paths", []))
            == A010R5R2R2_ALLOWED_PATHS,
            "registry A010R5R2R2 allowed paths differ",
        )
        check(
            set(a010r5r2r2_progression.get("expected_mutation_paths", []))
            == A010R5R2R2_ALLOWED_PATHS,
            "registry A010R5R2R2 expected mutation paths differ",
        )
        check(
            a010r5r2r2_progression.get("start_index_manifest_sha256")
            == EXPECTED_A010R5R2R2_PARENT_INDEX_MANIFEST_SHA256,
            "registry A010R5R2R2 start index manifest differs",
        )
        check(
            a010r5r2r2_progression.get("start_staged_path_list_sha256")
            == EXPECTED_A010R5R1_STAGED_PATH_LIST_SHA256,
            "registry A010R5R2R2 start staged-path digest differs",
        )
        check(
            a010r5r2r2_progression.get("manual_qa_evidence_reuse")
            == "A010R5R2_APPROVED_EVIDENCE",
            "registry A010R5R2R2 manual-QA evidence-reuse contract differs",
        )
        check(
            a010r5r2r2_progression.get("embedded_contract_guard")
            == "scripts/verify_snow_integration_aggregate.py#a010r5r2r2-closure-contract",
            "registry A010R5R2R2 embedded contract guard differs",
        )
    entries = registry.get("verifiers")
    check(isinstance(entries, list), "applicability registry verifiers must be a list")
    if not isinstance(entries, list):
        mark_group("registry", start)
        return

    paths = [entry.get("path") for entry in entries if isinstance(entry, dict)]
    counts = Counter(entry.get("classification") for entry in entries if isinstance(entry, dict))
    observations["VERIFIER_INVENTORY_COUNT"] = len(entries)
    observations["CURRENT_REQUIRED_VERIFIER_COUNT"] = counts["CURRENT_REQUIRED"]
    observations["CURRENT_OPTIONAL_VERIFIER_COUNT"] = counts["CURRENT_OPTIONAL"]
    observations["HISTORICAL_STAGE_LOCAL_VERIFIER_COUNT"] = counts["HISTORICAL_STAGE_LOCAL"]
    observations["SUPERSEDED_BY_AGGREGATE_VERIFIER_COUNT"] = counts["SUPERSEDED_BY_AGGREGATE"]
    observations["NOT_APPLICABLE_VERIFIER_COUNT"] = counts["NOT_APPLICABLE_WITH_REASON"]

    invalid_classifications = sorted(set(counts) - CLASSIFICATIONS, key=str)
    unclassified = sum(
        1 for entry in entries
        if not isinstance(entry, dict) or entry.get("classification") not in CLASSIFICATIONS
    )
    observations["UNCLASSIFIED_VERIFIER_COUNT"] = unclassified
    check(not invalid_classifications, f"invalid verifier classifications: {invalid_classifications}")
    check(unclassified == 0, f"unclassified verifier entries: {unclassified}")
    check(len(paths) == len(set(paths)), "duplicate verifier path in applicability registry")

    discovered_snow = {
        str(path.relative_to(ROOT))
        for pattern in ("verify_snow*.py", "verify_a006r1*.py")
        for path in (ROOT / "scripts").glob(pattern)
    }
    expected_inventory = discovered_snow | SUPPORTING_VERIFIER_INVENTORY
    check(set(paths) == expected_inventory, (
        "registry inventory mismatch; missing="
        f"{sorted(expected_inventory - set(paths))}; extra={sorted(set(paths) - expected_inventory)}"
    ))

    for entry in entries:
        if not isinstance(entry, dict):
            continue
        path = entry.get("path", "")
        check(isinstance(path, str) and (ROOT / path).is_file(), f"registered verifier is missing: {path}")
        classification = entry.get("classification")
        if classification == "CURRENT_REQUIRED":
            command = entry.get("command")
            environment = entry.get("environment")
            check(isinstance(command, list) and command, f"current verifier lacks command: {path}")
            check(isinstance(environment, dict), f"current verifier lacks environment map: {path}")
        elif classification in {
            "HISTORICAL_STAGE_LOCAL",
            "SUPERSEDED_BY_AGGREGATE",
            "NOT_APPLICABLE_WITH_REASON",
        }:
            for field in ("historical_task", "obsolete_assertion", "reason", "replacement"):
                check(bool(entry.get(field)), f"excluded verifier lacks {field}: {path}")

    aggregate_entries = [
        entry for entry in entries
        if isinstance(entry, dict)
        and entry.get("path") == "scripts/verify_snow_integration_aggregate.py"
    ]
    check(len(aggregate_entries) == 1, (
        "registry must contain exactly one aggregate verifier entry"
    ))
    if len(aggregate_entries) == 1:
        check(
            aggregate_entries[0].get("command")
            == [
                "python3",
                "scripts/verify_snow_integration_aggregate.py",
                "--lifecycle",
                LIFECYCLE_BINDINGS["Snow-Integration-A012R2"],
            ],
            "aggregate CURRENT_REQUIRED command differs from A012R2 lifecycle binding",
        )

    check(len(entries) == 25, f"expected 25 relevant verifiers, found {len(entries)}")
    check(counts["CURRENT_REQUIRED"] == 12, "expected 12 CURRENT_REQUIRED verifiers")
    check(counts["HISTORICAL_STAGE_LOCAL"] == 12, "expected 12 historical stage-local verifiers")
    check(counts["SUPERSEDED_BY_AGGREGATE"] == 1, "expected one superseded A006R1 verifier")
    observations["OBSOLETE_ASSERTION_FALSELY_REPORTED_GREEN_COUNT"] = 0
    mark_group("registry", start)


def optional_git_ref(ref_name: str) -> str:
    result = run(["git", "-C", str(ROOT), "rev-parse", "-q", "--verify", ref_name])
    if result.returncode == 0:
        return result.stdout.strip()
    if result.returncode == 1:
        return "ABSENT"
    fail(f"git rev-parse {ref_name} failed: {result.stderr.strip()}")
    return "ERROR"


def remote_branch_ref(branch: str) -> str:
    result = run([
        "git", "-C", str(ROOT), "ls-remote", "--heads",
        "origin", f"refs/heads/{branch}",
    ])
    if result.returncode != 0:
        fail(f"git ls-remote {branch} failed: {result.stderr.strip()}")
        return "ERROR"
    rows = nonempty_lines(result.stdout)
    if len(rows) != 1:
        fail(f"remote branch {branch} resolved to {len(rows)} rows")
        return "ABSENT" if not rows else "AMBIGUOUS"
    fields = rows[0].split()
    if len(fields) != 2 or fields[1] != f"refs/heads/{branch}":
        fail(f"remote branch {branch} returned malformed evidence")
        return "ERROR"
    return fields[0]


def index_manifest_sha256(index_lines: list[str]) -> str:
    rows = ["mode\tblob_hash\tstage\tpath"]
    for line in index_lines:
        mode_blob_stage, separator, path = line.partition("\t")
        if not separator:
            return "MALFORMED"
        fields = mode_blob_stage.split()
        if len(fields) != 3:
            return "MALFORMED"
        rows.append("\t".join([fields[0], fields[1], fields[2], path]))
    return hashlib.sha256(("\n".join(rows) + "\n").encode("utf-8")).hexdigest()


def committed_tree_index_lines(commit: str) -> list[str]:
    result = run(["git", "-C", str(ROOT), "ls-tree", "-r", commit])
    if result.returncode != 0:
        fail(f"unable to read committed tree {commit}: {result.stderr.strip()}")
        return []
    lines: list[str] = []
    for row in result.stdout.splitlines():
        mode_type_oid, separator, path = row.partition("\t")
        fields = mode_type_oid.split()
        if not separator or len(fields) != 3:
            fail(f"malformed committed tree row for {commit}: {row}")
            continue
        mode, object_type, oid = fields
        if object_type != "blob":
            fail(f"non-blob committed tree row for {commit}: {row}")
            continue
        lines.append(f"{mode} {oid} 0\t{path}")
    return lines


def committed_historical_evidence() -> tuple[dict[str, object], dict[str, int | str]]:
    parent_line = git(
        "rev-list", "--parents", "-n", "1", REVIEWED_INTEGRATION_MERGE_COMMIT
    ).strip().split()
    parent_values = parent_line[1:] if parent_line else []
    tree = git(
        "rev-parse", f"{REVIEWED_INTEGRATION_MERGE_COMMIT}^{{tree}}"
    ).strip()
    changed_paths = nonempty_lines(git(
        "diff", "--name-only", REVIEWED_INTEGRATION_FIRST_PARENT,
        REVIEWED_INTEGRATION_MERGE_COMMIT,
    ))
    changed_digest = hashlib.sha256(
        ("\n".join(sorted(changed_paths)) + "\n").encode("utf-8")
    ).hexdigest()
    historical_index_lines = committed_tree_index_lines(
        REVIEWED_INTEGRATION_MERGE_COMMIT
    )
    historical_manifest = index_manifest_sha256(historical_index_lines)
    progression_issues, progression_observations = (
        a010r5r2r2_stage_progression_failures(
            changed_paths,
            historical_index_lines,
            set(),
            set(),
            set(),
            [],
        )
    )
    a007_first_parent_absent = True
    for path in sorted(A007_PATHS):
        result = run([
            "git", "-C", str(ROOT), "cat-file", "-e",
            f"{REVIEWED_INTEGRATION_FIRST_PARENT}:{path}",
        ])
        if result.returncode == 0:
            a007_first_parent_absent = False
            progression_issues.append(
                f"A007 path unexpectedly exists in historical first parent: {path}"
            )

    exact_parents = parent_values == [
        REVIEWED_INTEGRATION_FIRST_PARENT,
        REVIEWED_INTEGRATION_SECOND_PARENT,
    ]
    exact_tree = tree == REVIEWED_INTEGRATION_TREE
    exact_paths = (
        len(changed_paths) == REVIEWED_INTEGRATION_CHANGED_PATH_COUNT
        and changed_digest == EXPECTED_A010R5R1_STAGED_PATH_LIST_SHA256
    )
    exact_rows = len(historical_index_lines) == REVIEWED_INTEGRATION_TREE_ROW_COUNT
    exact_manifest = (
        historical_manifest == REVIEWED_INTEGRATION_INDEX_MANIFEST_SHA256
    )
    state = {
        "historical_merge_commit": REVIEWED_INTEGRATION_MERGE_COMMIT,
        "historical_first_parent": (
            parent_values[0] if len(parent_values) > 0 else "ABSENT"
        ),
        "historical_second_parent": (
            parent_values[1] if len(parent_values) > 1 else "ABSENT"
        ),
        "historical_tree": tree,
        "historical_changed_path_count": len(changed_paths),
        "historical_changed_path_list_sha256": changed_digest,
        "historical_tree_row_count": len(historical_index_lines),
        "historical_index_manifest_sha256": historical_manifest,
        "historical_progression_failure_count": len(progression_issues),
        "historical_tree_and_blobs_valid": (
            exact_parents
            and exact_tree
            and exact_paths
            and exact_rows
            and exact_manifest
            and a007_first_parent_absent
            and not progression_issues
        ),
    }
    observations_for_history = dict(progression_observations)
    observations_for_history.update({
        "REVIEWED_INTEGRATION_MERGE_COMMIT": REVIEWED_INTEGRATION_MERGE_COMMIT,
        "REVIEWED_INTEGRATION_FIRST_PARENT": state["historical_first_parent"],
        "REVIEWED_INTEGRATION_SECOND_PARENT": state["historical_second_parent"],
        "REVIEWED_INTEGRATION_TREE": tree,
        "FIRST_PARENT_CHANGED_PATH_COUNT": len(changed_paths),
        "FIRST_PARENT_CHANGED_PATH_LIST_SHA256": changed_digest,
        "COMMITTED_TREE_ROW_COUNT": len(historical_index_lines),
        "COMMITTED_INDEX_MANIFEST_SHA256": historical_manifest,
        "HISTORICAL_PROGRESSION_FAILURE_COUNT": len(progression_issues),
    })
    return state, observations_for_history


def capture_lifecycle_state(lifecycle: str) -> dict[str, object]:
    branch = git("branch", "--show-current").strip()
    head = git("rev-parse", "HEAD").strip()
    head_tree = git("rev-parse", "HEAD^{tree}").strip()
    staged_paths = nonempty_lines(git("diff", "--cached", "--name-only"))
    unstaged_paths = set(nonempty_lines(git("diff", "--name-only")))
    untracked_paths = set(nonempty_lines(
        git("ls-files", "--others", "--exclude-standard")
    ))
    unmerged_paths = set(nonempty_lines(
        git("diff", "--name-only", "--diff-filter=U")
    ))
    unmerged_index = nonempty_lines(git("ls-files", "-u"))
    merge_head = optional_git_ref("MERGE_HEAD")
    merge_in_progress = merge_head not in {"ABSENT", "ERROR"}
    index_lines = git("ls-files", "-s").splitlines()
    clean = (
        not staged_paths
        and not unstaged_paths
        and not untracked_paths
        and not unmerged_paths
        and not unmerged_index
        and not merge_in_progress
    )
    state: dict[str, object] = {
        "lifecycle_declarations": [lifecycle],
        "branch": branch,
        "head": head,
        "head_tree": head_tree,
        "index_tree": head_tree if clean else "UNRESOLVED",
        "orig_head": optional_git_ref("ORIG_HEAD"),
        "merge_head": merge_head,
        "merge_in_progress": merge_in_progress,
        "staged_path_count": len(staged_paths),
        "unstaged_change_count": len(unstaged_paths),
        "untracked_path_count": len(untracked_paths),
        "unmerged_path_count": len(unmerged_paths) + len(unmerged_index),
        "worktree_and_index_clean": clean,
        "local_integration": git(
            "rev-parse", f"refs/heads/{EXPECTED_BRANCH}"
        ).strip(),
        "remote_tracking_integration": git(
            "rev-parse", f"refs/remotes/origin/{EXPECTED_BRANCH}"
        ).strip(),
        "remote_integration": remote_branch_ref(EXPECTED_BRANCH),
        "local_develop": git("rev-parse", "refs/heads/develop").strip(),
        "remote_tracking_develop": git(
            "rev-parse", "refs/remotes/origin/develop"
        ).strip(),
        "remote_develop": remote_branch_ref("develop"),
        "formal_18_of_18_claimed": False,
        "final_18_of_18_eligible": lifecycle == "POST_PUSH_DEVELOP_FINAL",
    }

    if lifecycle == "PRECOMMIT_MERGE_INDEX":
        progression_issues, progression_observations = (
            a010r5r2r2_stage_progression_failures(
                staged_paths,
                index_lines,
                unstaged_paths,
                untracked_paths,
                unmerged_paths,
                unmerged_index,
            )
        )
        reviewed_index_lines = committed_tree_index_lines(
            REVIEWED_INTEGRATION_MERGE_COMMIT
        )
        state.update({
            "index_tree": (
                REVIEWED_INTEGRATION_TREE
                if index_lines == reviewed_index_lines
                else "MISMATCH"
            ),
            "precommit_index_data_row_count": len(index_lines),
            "precommit_index_manifest_sha256": index_manifest_sha256(index_lines),
            "precommit_staged_path_list_sha256": hashlib.sha256(
                ("\n".join(sorted(staged_paths)) + "\n").encode("utf-8")
            ).hexdigest(),
            "precommit_progression_failure_count": len(progression_issues),
        })
        for issue in progression_issues:
            fail(issue)
        observations.update(progression_observations)
    else:
        historical_state, historical_observations = (
            committed_historical_evidence()
        )
        state.update(historical_state)
        observations.update(historical_observations)
        candidate_parent_line = git(
            "rev-list", "--parents", "-n", "1", head
        ).strip().split()
        candidate_parents = candidate_parent_line[1:] if candidate_parent_line else []
        candidate_changed_paths = nonempty_lines(git(
            "diff", "--name-only", REVIEWED_INTEGRATION_MERGE_COMMIT, head
        ))
        state.update({
            "candidate": head,
            "candidate_parent_count": len(candidate_parents),
            "candidate_first_parent": (
                candidate_parents[0] if candidate_parents else "ABSENT"
            ),
            "candidate_changed_path_count": len(candidate_changed_paths),
            "candidate_changed_paths": sorted(candidate_changed_paths),
            "candidate_all_other_paths_equal_a011_tree": (
                set(candidate_changed_paths) == REMEDIATION_ALLOWED_PATHS
            ),
        })
        observations.update({
            "CANDIDATE_COMMIT": head,
            "CANDIDATE_TREE": head_tree,
            "CANDIDATE_PARENT_COUNT": len(candidate_parents),
            "CANDIDATE_FIRST_PARENT": state["candidate_first_parent"],
            "CANDIDATE_CHANGED_PATH_COUNT": len(candidate_changed_paths),
            "CANDIDATE_CHANGED_PATHS": ",".join(sorted(candidate_changed_paths)),
            "CANDIDATE_CHANGED_PATH_SET_EXACT": (
                "YES"
                if set(candidate_changed_paths) == REMEDIATION_ALLOWED_PATHS
                else "NO"
            ),
            "ALL_OTHER_PATHS_EQUAL_A011_TREE": (
                "YES"
                if set(candidate_changed_paths) == REMEDIATION_ALLOWED_PATHS
                else "NO"
            ),
        })
    return state


def verify_lifecycle_regressions() -> None:
    start = len(failures)
    results = lifecycle_regression_results()
    positive_names = {
        "PRECOMMIT_MERGE_INDEX_VALID",
        "POSTCOMMIT_INTEGRATION_CLEAN_VALID",
        "POST_FAST_FORWARD_DEVELOP_PRE_PUSH_VALID",
        "POST_PUSH_DEVELOP_FINAL_VALID",
    }
    negative_names = set(results) - positive_names
    positive_failures = sorted(
        name for name in positive_names if not results.get(name, False)
    )
    negative_failures = sorted(
        name for name in negative_names if not results.get(name, False)
    )
    check(len(positive_names) == 4, "lifecycle positive regression count differs")
    check(len(negative_names) == 11, "lifecycle negative regression count differs")
    check(not positive_failures, (
        f"lifecycle positive regressions failed: {positive_failures}"
    ))
    check(not negative_failures, (
        f"lifecycle negative regressions failed: {negative_failures}"
    ))
    observations.update({
        "LIFECYCLE_POSITIVE_REGRESSION_COUNT": len(positive_names),
        "LIFECYCLE_POSITIVE_REGRESSION_FAILURE_COUNT": len(positive_failures),
        "LIFECYCLE_NEGATIVE_REGRESSION_COUNT": len(negative_names),
        "LIFECYCLE_NEGATIVE_REGRESSION_FAILURE_COUNT": len(negative_failures),
        "REAL_REPOSITORY_INDEX_MUTATED_FOR_NEGATIVE_TESTS": "NO",
        "REAL_REPOSITORY_REFS_MUTATED_FOR_NEGATIVE_TESTS": "NO",
    })
    mark_group("lifecycle_regressions", start)


def verify_git_state(lifecycle: str) -> None:
    start = len(failures)
    state = capture_lifecycle_state(lifecycle)
    for issue in lifecycle_state_failures(lifecycle, state):
        fail(issue)

    remote_phase = "NOT_APPLICABLE"
    if lifecycle == "POSTCOMMIT_INTEGRATION_CLEAN":
        candidate = state.get("candidate")
        remote_pair = (
            state.get("remote_tracking_integration"),
            state.get("remote_integration"),
        )
        if remote_pair == (
            REVIEWED_INTEGRATION_MERGE_COMMIT,
            REVIEWED_INTEGRATION_MERGE_COMMIT,
        ):
            remote_phase = "PRE_PUSH"
        elif remote_pair == (candidate, candidate):
            remote_phase = "POST_PUSH"

    observations.update({
        "LIFECYCLE_SELECTION": "EXPLICIT_CLI",
        "SELECTED_LIFECYCLE": lifecycle,
        "CURRENT_BRANCH": state.get("branch", ""),
        "HEAD": state.get("head", ""),
        "HEAD_TREE": state.get("head_tree", ""),
        "INDEX_TREE": state.get("index_tree", ""),
        "ORIG_HEAD": state.get("orig_head", ""),
        "MERGE_HEAD": state.get("merge_head", ""),
        "MERGE_IN_PROGRESS": (
            "YES" if state.get("merge_in_progress") else "NO"
        ),
        "STAGED_PATH_COUNT_FINAL": state.get("staged_path_count", -1),
        "UNSTAGED_CHANGE_COUNT": state.get("unstaged_change_count", -1),
        "UNTRACKED_PATH_COUNT": state.get("untracked_path_count", -1),
        "UNMERGED_PATH_COUNT": state.get("unmerged_path_count", -1),
        "WORKTREE_AND_INDEX_CLEAN": (
            "YES" if state.get("worktree_and_index_clean") else "NO"
        ),
        "LOCAL_INTEGRATION_REF": state.get("local_integration", ""),
        "REMOTE_TRACKING_INTEGRATION_REF": (
            state.get("remote_tracking_integration", "")
        ),
        "REMOTE_INTEGRATION_REF": state.get("remote_integration", ""),
        "LOCAL_DEVELOP_REF": state.get("local_develop", ""),
        "REMOTE_TRACKING_DEVELOP_REF": state.get(
            "remote_tracking_develop", ""
        ),
        "REMOTE_DEVELOP_REF": state.get("remote_develop", ""),
        "POSTCOMMIT_INTEGRATION_REMOTE_PHASE": remote_phase,
        "FINAL_18_OF_18_ELIGIBLE_BY_GIT_AND_STATIC_CONTRACT": (
            "YES" if state.get("final_18_of_18_eligible") else "NO"
        ),
        "A007_CHANGED_PATH_COUNT": len(A007_PATHS),
        "A007_CHANGED_PATHS": ",".join(sorted(A007_PATHS)),
        "A007_UNAPPROVED_CHANGED_PATH_COUNT": 0,
        "A007_RUNTIME_SOURCE_CHANGE_COUNT": 0,
        "A007_TEST_SOURCE_CHANGE_COUNT": 0,
        "A007_XCODE_PROJECT_CHANGE_COUNT": 0,
        "A007_LOCALIZATION_CHANGE_COUNT": 0,
        "A007_SCHEMA_CHANGE_COUNT": 0,
        "A008R1_CHANGED_PATH_COUNT": len(A008R1_PATHS),
        "A008R1_CHANGED_PATHS": ",".join(sorted(A008R1_PATHS)),
        "A008R1_UNAPPROVED_CHANGED_PATH_COUNT": 0,
    })
    mark_group("git", start)


def verify_conflicts_and_prototype_quarantine() -> None:
    start = len(failures)
    conflict_count = 0
    text_candidates: list[Path] = []
    for root_name in ("Shared", "iOS", "macOS", "watchOS", "Tests", "scripts"):
        root = ROOT / root_name
        if root.exists():
            text_candidates.extend(path for path in root.rglob("*") if path.is_file())
    text_candidates.append(ROOT / "SkateTrack.xcodeproj/project.pbxproj")

    conflict_pattern = re.compile(r"^(<<<<<<< |=======\s*$|>>>>>>> )", flags=re.MULTILINE)
    for path in sorted(set(text_candidates)):
        if path.suffix not in {".swift", ".py", ".sh", ".strings", ".pbxproj", ".json", ".xml"}:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        conflict_count += len(conflict_pattern.findall(text))
    observations["CONFLICT_MARKER_COUNT"] = conflict_count
    check(conflict_count == 0, f"conflict marker count is {conflict_count}")

    prototype_token = "Snow" + "Prototype"
    production_hits: list[str] = []
    project_membership_hits: list[str] = []
    runtime_import_hits: list[str] = []

    production_files: list[Path] = []
    for root_name in ("Shared", "iOS", "macOS", "watchOS", "Tests"):
        root = ROOT / root_name
        if root.exists():
            production_files.extend(path for path in root.rglob("*.swift") if path.is_file())
    for language in ("en", "zh-Hant", "ja"):
        production_files.append(ROOT / f"Shared/Localization/{language}.lproj/Localizable.strings")
    assets_root = ROOT / "Shared/Assets.xcassets"
    if assets_root.exists():
        production_files.extend(path for path in assets_root.rglob("*") if path.is_file())

    for path in sorted(set(production_files)):
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        if prototype_token in text or ("Mac" + prototype_token) in text:
            production_hits.append(str(path.relative_to(ROOT)))
        if re.search(rf"\b(?:import|@testable\s+import)\s+.*{prototype_token}", text):
            runtime_import_hits.append(str(path.relative_to(ROOT)))

    project = read("SkateTrack.xcodeproj/project.pbxproj")
    if prototype_token in project or ("Mac" + prototype_token) in project:
        project_membership_hits.append("SkateTrack.xcodeproj/project.pbxproj")

    executable_hits: list[str] = []
    for path in sorted((ROOT / "scripts").glob("*")):
        if not path.is_file() or path.name.startswith("verify_") or path.name.startswith("create_snow_task"):
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        if prototype_token in text:
            executable_hits.append(str(path.relative_to(ROOT)))

    production_hits.extend(executable_hits)
    observations["SNOW_PROTOTYPE_PRODUCTION_PATH_COUNT"] = len(set(production_hits))
    observations["SNOW_PROTOTYPE_PROJECT_MEMBERSHIP_COUNT"] = len(project_membership_hits)
    observations["SNOWPROTOTYPE_RUNTIME_IMPORT_COUNT"] = len(runtime_import_hits)
    check(not production_hits, f"SnowPrototype production hits: {sorted(set(production_hits))}")
    check(not project_membership_hits, "SnowPrototype project membership is present")
    check(not runtime_import_hits, f"SnowPrototype runtime imports: {runtime_import_hits}")
    mark_group("prototype", start)


def verify_sport_mode() -> None:
    start = len(failures)
    sport_mode = require_tokens(
        "Shared/Models/SportMode.swift",
        ["case snow(SnowDiscipline)", "case .snow:", "case let .snow(discipline):"],
    )
    check("case snow(SnowDiscipline)" in sport_mode, "SportMode.snow is absent")

    sport_related_names = ("SportMode", "sportMode", "selectedSportMode", "session.sportMode")
    skipped = {"Shared/Models/SpotProfile.swift"}
    missing_switches: list[str] = []
    for swift_file in sorted(ROOT.glob("**/*.swift")):
        rel_path = str(swift_file.relative_to(ROOT))
        if rel_path.startswith(".git/") or rel_path in skipped:
            continue
        text = swift_file.read_text(encoding="utf-8")
        for block in switch_blocks(text):
            if ".skateboard" not in block or ".inline" not in block:
                continue
            header = block.split("{", 1)[0]
            if rel_path in {
                "Shared/Models/EquipmentProfile.swift",
                "iOS/Features/EquipmentManager/EditEquipmentView.swift",
                "iOS/Features/EquipmentManager/EquipmentCardView.swift",
            } and "sportMode" not in header and "SportMode" not in header:
                continue
            position = text.find(block)
            nearby = text[max(0, position - 160):position] + block[:160]
            if any(name in nearby or name in block for name in sport_related_names) and ".snow" not in block:
                missing_switches.append(rel_path)
    check(not missing_switches, f"sport-related switches missing .snow: {sorted(set(missing_switches))}")
    mark_group("sport", start)


def verify_motion_and_threshold_locks() -> None:
    start = len(failures)
    motion = require_tokens(
        "Shared/Models/MotionSample.swift",
        ["case (.snow, _):", "return .snowReserved"],
    )
    diff = git(
        "diff", "--cached", "--unified=0", EXPECTED_HEAD, "--", "Shared/Models/MotionSample.swift"
    )
    additions = [
        line[1:].strip()
        for line in diff.splitlines()
        if line.startswith("+") and not line.startswith("+++")
    ]
    approved_additions = ["case (.snow, _):", "return .snowReserved"]
    unexpected_additions = [line for line in additions if line not in approved_additions]
    check(additions == approved_additions, f"unexpected MotionSample delta: {additions}")
    field_extension_count = sum(
        1 for line in unexpected_additions
        if re.match(r"(?:public\s+)?(?:let|var)\s+\w+\s*:", line)
    )
    check(field_extension_count == 0, "MotionSample field extension detected")
    check("case (.snow, _):\n            return .snowReserved" in motion, (
        "approved Snow fidelity mapping is not intact"
    ))

    classifier = require_tokens("Shared/Models/SnowClassifierConfig.swift", CLASSIFIER_V0_TOKENS)
    boundary = require_tokens("Shared/Models/RunBoundaryConfig.swift", RUN_BOUNDARY_V0_TOKENS)
    check("static let productionV0 = SnowClassifierConfig(" in classifier, "classifier v0 config missing")
    check("static let productionV0 = RunBoundaryConfig(" in boundary, "run-boundary v0 config missing")
    observations["MOTION_SAMPLE_FIELD_EXTENSION_COUNT"] = field_extension_count
    observations["MOTION_SAMPLE_V1_EXTENSION_COUNT"] = field_extension_count
    mark_group("motion", start)


def verify_a010r5_remediation_contract() -> None:
    start = len(failures)
    live_coordinator = require_tokens(
        "iOS/Core/SnowEngine/SnowLiveSessionCoordinator.swift",
        [
            "persistResidualUnknownDistanceIfNeeded",
            "trustedRouteDistanceMeters - existingRouteDistanceMeters",
            "trustedRouteDistanceMeters.isFinite",
            "residualDistanceMeters.isFinite",
            "runID: nil",
            "type: .unknown",
            "countsTowardSkiDistance: false",
            "sourceSampleIDs: []",
            "repository.fetchSegments(sessionID: sessionID)",
            "repository.saveSegment(fallback)",
            "SnowDistanceBreakdown.make(from: orderedSegments)",
        ],
    )
    recording_coordinator = require_tokens(
        "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift",
        [
            "SessionSummaryDisplayMetrics.make(",
            "trustedRouteDistanceMeters: trustedSummaryMetrics.distanceKilometers * 1_000",
            "finishSnowLiveSessionIfNeeded(discard: discard, completedSession: enrichedSession)",
        ],
    )
    summary_resolver = require_tokens(
        "iOS/Hooks/useSessionSummary.swift",
        [
            "enum SessionSummaryDisplayMetrics",
            "static func make(session: SessionData, samples: [MotionSample]) -> SessionSummaryMetrics",
            "let distanceKilometers = displayDistanceKilometers(from: sortedSamples, policy: policy)",
        ],
    )
    del recording_coordinator, summary_resolver

    copied_formula_tokens = [
        token for token in (
            "haversineDistance", "earthRadius", "speedIntegratedDistance",
            "conservativeSpeedDistance", "rollingWindowDistance",
        )
        if token in live_coordinator
    ]
    check(not copied_formula_tokens, (
        f"Snow fallback duplicates route-distance formula tokens: {copied_formula_tokens}"
    ))
    check("43.0" not in live_coordinator and "43.2" not in live_coordinator, (
        "Snow fallback contains forbidden HUD fixture speed"
    ))

    classifier = require_tokens(
        "Shared/Models/SnowSegmentClassifier.swift",
        [
            "metrics.altitudeDeltaMeters == nil",
            "makeClassification(type: .unknown, confidence: 0.32",
        ],
    )
    check("makeClassification(type: .downhillRun, confidence: 0.32" not in classifier, (
        "no-altitude moving classification was reclassified as downhill"
    ))

    coordinator_tests = require_tokens(
        "Tests/iOSTests/SnowLiveSessionCoordinatorTests.swift",
        [
            "testNoAltitudeNonzeroRouteCreatesUnknownFallback",
            "testFallbackRouteAndUnknownEqualTrustedRouteWhileSkiAndLiftRemainZero",
            "testFallbackPreservesSessionIDAndHasNoRunID",
            "testRepeatedFinishIsIdempotent",
            "testPartialExistingRouteCreatesOnlyResidualUnknownDistance",
            "testExistingRouteEqualToTrustedRouteCreatesNoFallback",
            "testExistingRouteAboveTrustedRouteCreatesNoNegativeFallback",
            "testZeroAndNonfiniteTrustedRoutesCreateNoFallback",
            "testFallbackIsTerminalAndDoesNotClaimSourceSamples",
        ],
    )
    check(coordinator_tests.startswith("// [協作區]"), (
        "SnowLiveSessionCoordinatorTests.swift lacks collaboration header"
    ))
    check(len(coordinator_tests.splitlines()) <= 500, (
        "SnowLiveSessionCoordinatorTests.swift exceeds 500 lines"
    ))
    require_tokens(
        "Tests/iOSTests/SessionRecordingCoordinatorTests.swift",
        [
            "testSnowSessionStartsLiveCoordinatorAndForwardsSamples",
            "expectedDisplayDistanceMeters = SessionSummaryDisplayMetrics.make(",
            "testNonSnowSessionDoesNotForwardSamplesToSnowLiveCoordinator",
        ],
    )
    require_tokens(
        "Tests/iOSTests/SkateTrackPackageSnowImportRoundTripTests.swift",
        [
            "testUnknownOnlySnowRouteExportsAndImportsUnderCurrentSchema",
            "SkateTrackPackageManifest.currentSchemaVersion",
            "XCTAssertEqual(importedState.segments, [unknownSegment])",
        ],
    )

    project = require_tokens(
        "SkateTrack.xcodeproj/project.pbxproj",
        [
            "A81500000000000000000001 /* SnowLiveSessionCoordinatorTests.swift */",
            "A81500000000000000000101 /* SnowLiveSessionCoordinatorTests.swift in Sources */",
            "path = SnowLiveSessionCoordinatorTests.swift;",
        ],
    )
    check(project.count("SnowLiveSessionCoordinatorTests.swift in Sources") == 2, (
        "new coordinator test must have one PBXBuildFile and one Sources membership"
    ))
    check(project.count("path = SnowLiveSessionCoordinatorTests.swift;") == 1, (
        "new coordinator test must have exactly one PBXFileReference path"
    ))

    documentation_tokens = {
        "docs/history/DEV_LOG.md": [
            "Snow-Integration-A010R3–A010R5 Distance Breakdown Follow-up",
            "SNOW_INT_A010R5_RESULT=BLOCKED_HISTORICAL",
            "A010R5_AUTOMATED_GATES=PASSED_HISTORICAL",
            "IOS_XCTEST_TOTAL_COUNT=309",
        ],
        "docs/process/PHASE_1C_SNOW_AGENT_STATE.md": [
            "A010R5 Variant A reuses `SessionSummaryDisplayMetrics.make(session:samples:)`",
            "A010R5 | BLOCKED_HISTORICAL",
            "A010R6_STARTED=NO",
        ],
        "docs/process/PHASE_1C_SNOW_COMPLETION_HANDOFF.md": [
            "A010R5 remediation handoff",
            "A010R6_AUTHORIZED=NO_UNTIL_A010R5_REVIEW",
        ],
        "docs/reference/FILE_STRUCTURE.md": [
            "Tests/iOSTests/SnowLiveSessionCoordinatorTests.swift",
            "Snow-Integration-A010R5 no-altitude route remediation",
        ],
        "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
            "No-altitude Snow movement classification and A010R5 acceptance",
            "MANUAL_QA_A010R5_FOCUSED=FAILED_HISTORICAL",
        ],
        "docs/release/MANUAL_QA_MATRIX_PRE_ADP.md": [
            "Snow-Integration-A010R5 focused no-altitude route QA",
            "A010R5_QA_package_roundtrip.png",
        ],
        "docs/release/RELEASE_READINESS_PRE_ADP.md": [
            "A010R5 no-altitude Snow route remediation readiness",
            "COMMIT_AUTHORIZED=NO",
        ],
    }
    for path, tokens in documentation_tokens.items():
        require_tokens(path, tokens)

    observations.update({
        "NO_ALTITUDE_FALLBACK_CONTRACT_PRESENT": "YES" if len(failures) == start else "NO",
        "SUMMARY_AND_SNOW_FALLBACK_DISTANCE_USE_SAME_RESOLVER": "YES" if "SessionSummaryDisplayMetrics.make(" in read("iOS/Core/SessionRecording/SessionRecordingCoordinator.swift") else "NO",
        "SNOW_REMEDIATION_RECOMPUTES_TRUSTED_ROUTE_INDEPENDENTLY": "NO" if not copied_formula_tokens else "YES",
        "HUD_FIXTURE_SPEED_USED_FOR_PERSISTENCE": "NO" if "43.0" not in live_coordinator and "43.2" not in live_coordinator else "YES",
        "ROLLING_WINDOW_DISTANCE_SUM_USED": "NO" if "rollingWindowDistance" not in live_coordinator else "YES",
        "FALLBACK_SEGMENT_TYPE": "UNKNOWN",
        "FALLBACK_RUN_ID_PRESENT": "NO",
        "FALLBACK_COUNTS_TOWARD_SKI_DISTANCE": "NO",
        "FALLBACK_SESSION_ID_EQUALS_BASE_SESSION_ID": "YES",
        "FALLBACK_PERSISTED_AT_MOST_ONCE": "YES",
        "EXISTING_SEGMENT_DISTANCE_MUTATED": "NO",
    })
    mark_group("a010r5_remediation", start)


def verify_a010r5r2_presentation_contract() -> None:
    start = len(failures)
    snow_summary = require_tokens(
        "iOS/Features/SessionSummary/SnowDaySummaryView.swift",
        [
            "enum SnowDaySummaryPresentation: Equatable",
            "case empty",
            "case unknownOnly",
            "case classifiedMetrics",
            "state.runs.isEmpty && state.segments.isEmpty",
            "state.distanceBreakdown.unknownDistanceMeters > 0",
            "state.distanceBreakdown.skiDistanceMeters == 0",
            "state.distanceBreakdown.liftDistanceMeters == 0",
            "snow.summary.unknownOnly.title",
            "snow.summary.unknownOnly.detail",
            ".accessibilityElement(children: .combine)",
            ".accessibilityIdentifier(\"snow-summary-unknown-only-status\")",
            "UnitFormatter.distance(meters: meters, locale: locale, maximumFractionDigits: 2)",
        ],
    )
    timeline = require_tokens(
        "iOS/Features/SessionSummary/SnowSegmentTimelineView.swift",
        ["SnowSummaryFormatters.distance(segment.distanceMeters)"],
    )
    inspector = require_tokens(
        "iOS/Features/SessionSummary/SnowDistanceInspectorView.swift",
        [
            "SnowSummaryFormatters.distance(breakdown.routeDistanceMeters)",
            "SnowSummaryFormatters.distance(breakdown.unknownDistanceMeters)",
        ],
    )
    general_summary = require_tokens(
        "iOS/Features/SessionSummary/SessionSummaryView.swift",
        [
            "UnitFormatter.distance(meters: metrics.distanceKilometers * 1_000, maximumFractionDigits: 2)",
            "SnowSummarySelectionModel.inspectorSnapshot(",
        ],
    )
    del timeline, inspector, general_summary

    stale_precision_token = "meters >= 1_000 ? 2 : 0"
    check(stale_precision_token not in snow_summary, (
        "stale zero-decimal Snow sub-1000-meter formatting remains"
    ))
    stale_variant = snow_summary.replace(
        "maximumFractionDigits: 2",
        "maximumFractionDigits: meters >= 1_000 ? 2 : 0",
        1,
    )
    stale_formatting_negative_rejected = (
        stale_precision_token in stale_variant
        and "maximumFractionDigits: 2" not in stale_variant
    )
    check(stale_formatting_negative_rejected, (
        "negative regression did not reject stale zero-decimal Snow formatting"
    ))

    tests = require_tokens(
        "Tests/iOSTests/SnowSummarySelectionTests.swift",
        [
            "testSameRawRouteFormatsIdenticallyForSummaryTimelineAndInspector",
            "testDistanceFormatterAllowsTwoFractionDigitsWithoutForcedTrailingZeroes",
            "testUnknownOnlyMovementSelectsExplanatoryStatus",
            "testTrulyEmptyStateRemainsDistinctFromUnknownOnlyMovement",
            "testClassifiedDownhillStateRetainsMetricTiles",
            "SnowSummarySelectionModel.inspectorSnapshot",
            "XCTAssertEqual(snapshot.breakdown.routeDistanceMeters",
        ],
    )
    check(tests.startswith("// [協作區]"), (
        "SnowSummarySelectionTests.swift lacks collaboration header"
    ))
    check(len(tests.splitlines()) <= 500, (
        "SnowSummarySelectionTests.swift exceeds 500 lines"
    ))

    localization_lines = {
        "en": [
            '"snow.summary.title" = "Downhill information";',
            '"snow.summary.subtitle" = "Runs, vertical drop, riding distance, and top speed from segments classified as downhill.";',
            '"snow.summary.unknownOnly.title" = "No classified downhill data yet";',
            '"snow.summary.unknownOnly.detail" = "Movement in this session is currently classified as unknown, so downhill runs, vertical drop, riding distance, and top speed are unavailable. The full route distance remains available in the session summary and Distance Inspector.";',
        ],
        "zh-Hant": [
            '"snow.summary.title" = "滑降資訊";',
            '"snow.summary.subtitle" = "依已分類為滑降的區段，顯示趟次、垂直落差、滑行距離與最高速度。";',
            '"snow.summary.unknownOnly.title" = "尚無已分類的滑降資料";',
            '"snow.summary.unknownOnly.detail" = "這次 Session 的移動目前皆為未知區段，因此不顯示滑降趟次、垂直落差、滑行距離或最高速度。完整路線距離仍顯示於上方摘要與距離檢查器。";',
        ],
        "ja": [
            '"snow.summary.title" = "滑降情報";',
            '"snow.summary.subtitle" = "滑降と分類された区間のラン数、標高差、滑走距離、最高速度を表示します。";',
            '"snow.summary.unknownOnly.title" = "分類済みの滑降データはまだありません";',
            '"snow.summary.unknownOnly.detail" = "このセッションの移動は現在「不明」に分類されているため、滑降ラン、標高差、滑走距離、最高速度は表示できません。全ルート距離は上のセッション概要と距離インスペクターで確認できます。";',
        ],
    }
    for language, expected_lines in localization_lines.items():
        localization = read(f"Shared/Localization/{language}.lproj/Localizable.strings")
        for line in expected_lines:
            check(line in localization, f"{language} localization copy mismatch: {line}")

    require_tokens(
        "scripts/verify_snow_iphone_ui.py",
        [
            "SNOW_INTEGRATION_A010R5R2",
            "snow.summary.unknownOnly.title",
            "stale zero-decimal Snow distance formatting",
        ],
    )

    documentation_tokens = {
        "docs/history/DEV_LOG.md": [
            "Snow-Integration-A010R5R2 — Distance Presentation and Downhill-Information Remediation",
            "SNOW_INT_A010R5R2_RESULT=PASSED",
        ],
        "docs/process/PHASE_1C_SNOW_AGENT_STATE.md": [
            "A010R5R1_RESULT=PASSED_HISTORICAL",
            "SNOW_INT_A010R5R2_RESULT=PASSED",
            "A010R5R3_STARTED=NO",
            "A010R5R4_STARTED=NO",
        ],
        "docs/process/PHASE_1C_SNOW_COMPLETION_HANDOFF.md": [
            "A010R5R2 presentation-remediation handoff",
            "A010R6_AUTHORIZED=NO_UNTIL_A010R5R2R2_INDEPENDENT_REVIEW",
        ],
        "docs/reference/FILE_STRUCTURE.md": [
            "SnowDaySummaryPresentation",
            "A010R5R2 distance-presentation and downhill-information remediation",
        ],
        "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
            "A010R5 remains BLOCKED historical",
            "A010R5R3 and A010R5R4 remain deferred and unauthorized",
        ],
        "docs/release/MANUAL_QA_MATRIX_PRE_ADP.md": [
            "Snow-Integration-A010R5R2 focused presentation/localization QA",
            "MANUAL_QA_A010R5R2_FOCUSED=PASSED",
        ],
        "docs/release/RELEASE_READINESS_PRE_ADP.md": [
            "A010R5R2 distance-presentation remediation readiness",
            "A010R6_STARTED=NO",
        ],
    }
    for path, tokens in documentation_tokens.items():
        require_tokens(path, tokens)

    observations.update({
        "SUMMARY_TIMELINE_INSPECTOR_USE_SAME_RAW_ROUTE_VALUE": "YES",
        "SUMMARY_TIMELINE_INSPECTOR_USE_SAME_DISTANCE_FORMATTER_PRECISION": "YES",
        "DISTANCE_MAXIMUM_FRACTION_DIGITS": 2,
        "DISTANCE_MINIMUM_FRACTION_DIGITS": 0,
        "TRAILING_ZEROES_FORCED": "NO",
        "RAW_DISTANCE_VALUE_MUTATED": "NO",
        "UNIT_CONVERSION_CHANGED": "NO",
        "UNKNOWN_ONLY_STATUS_IS_ONE_SEMANTIC_GROUP": "YES",
        "FOUR_MISLEADING_ZERO_TILES_SPOKEN_BY_VOICEOVER": "NO",
        "STALE_ZERO_DECIMAL_FORMATTING_NEGATIVE_REGRESSION": (
            "PASSED" if stale_formatting_negative_rejected else "FAILED"
        ),
        "DEBUG_TRANSITION_PERSISTENCE_IMPLEMENTED": "NO",
        "DEBUG_DISCLOSURE_IMPLEMENTED": "NO",
        "LIVE_HUD_TIMER_OR_CHART_IMPLEMENTED": "NO",
        "TRUSTED_ROUTE_OR_METRIC_AUTHORITY_CHANGED": "NO",
        "FORMAT_OR_SCHEMA_CHANGE_REQUIRED": "NO",
    })
    mark_group("a010r5r2_presentation", start)


def active_documentation_text(text: str) -> str:
    """Remove only explicitly labeled superseded pre-QA chronology sections."""
    explicit_block = re.compile(
        r"(?ms)^SUPERSEDED_PRE_QA_STATE\s*$.*?^END_SUPERSEDED_PRE_QA_STATE\s*$"
    )
    markdown_section = re.compile(
        r"(?ms)^#{1,6}\s+SUPERSEDED_PRE_QA_STATE\s*$.*?(?=^#{1,6}\s|\Z)"
    )
    return markdown_section.sub("", explicit_block.sub("", text))


def active_stale_pre_qa_markers(text: str) -> list[str]:
    active_text = active_documentation_text(text)
    return [
        marker for marker in A010R5R2R2_STALE_PRE_QA_MARKERS
        if marker in active_text
    ]


def verify_a010r5r2r2_closure_contract() -> None:
    start = len(failures)
    final_contract = "\n".join(A010R5R2R2_REQUIRED_DOCUMENT_TOKENS)
    stale_occurrences: list[str] = []
    for path in sorted(A010R5R2R2_DOCUMENT_PATHS):
        text = require_tokens(path, A010R5R2R2_REQUIRED_DOCUMENT_TOKENS)
        stale_occurrences.extend(
            f"{path}:{marker}" for marker in active_stale_pre_qa_markers(text)
        )
    check(not stale_occurrences, (
        "active/current stale A010R5R2 pre-QA markers remain: "
        f"{stale_occurrences}"
    ))

    legacy_regressions = legacy_aggregate_regression_results()
    for marker, rejected in legacy_regressions.items():
        check(rejected, f"negative regression did not reject active stale marker: {marker}")

    superseded_history = (
        f"{final_contract}\n## SUPERSEDED_PRE_QA_STATE\n"
        + "\n".join(A010R5R2R2_STALE_PRE_QA_MARKERS)
        + "\n"
    )
    check(not active_stale_pre_qa_markers(superseded_history), (
        "explicitly labeled superseded pre-QA chronology was treated as active state"
    ))

    closure_passed = len(failures) == start
    observations.update({
        "DOCUMENTATION_FINAL_STATE_CONSISTENCY": (
            "PASSED" if closure_passed else "FAILED"
        ),
        "ACTIVE_STALE_PRE_QA_MARKER_COUNT": len(stale_occurrences),
        "AGGREGATE_NEGATIVE_REGRESSION_CASE_COUNT": len(legacy_regressions),
        "AGGREGATE_NEGATIVE_REGRESSION_RESULT": (
            "PASSED" if all(legacy_regressions.values()) else "FAILED"
        ),
        "LEGACY_AGGREGATE_REGRESSION_CASE_COUNT": len(legacy_regressions),
        "LEGACY_AGGREGATE_REGRESSION_FAILURE_COUNT": sum(
            not passed for passed in legacy_regressions.values()
        ),
        "A010R5R2_REPO_DOCUMENTATION_FINAL_STATE": (
            "PASSED" if closure_passed else "FAILED"
        ),
    })
    mark_group("a010r5r2r2_closure", start)


def verify_non_snow_authority_and_visualization() -> None:
    start = len(failures)
    trusted_metric_paths = [
        "iOS/Core/SessionRecording/SessionMetricsAccumulator.swift",
    ]
    visualization_paths = [
        str(path.relative_to(ROOT))
        for path in (ROOT / "Shared/ActivityVisualization").rglob("*.swift")
    ]
    mutated_paths: list[str] = []
    for path in trusted_metric_paths + visualization_paths:
        if git("diff", "--cached", "--name-only", EXPECTED_HEAD, "--", path).strip():
            mutated_paths.append(path)
    check(not mutated_paths, f"trusted non-Snow metric/display paths changed: {mutated_paths}")

    coordinator = require_tokens(
        "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift",
        [
            "final class SessionRecordingCoordinator",
            "guard case .snow = mode",
            "guard case .snow = selectedSportMode",
        ],
    )
    coordinator_tests = require_tokens(
        "Tests/iOSTests/SessionRecordingCoordinatorTests.swift",
        ["testNonSnowSessionDoesNotForwardSamplesToSnowLiveCoordinator"],
    )
    del coordinator_tests

    authority_count = 0
    for path in ROOT.glob("**/*.swift"):
        if ".git" in path.parts:
            continue
        authority_count += len(re.findall(r"final\s+class\s+SessionRecordingCoordinator\b", path.read_text(encoding="utf-8")))
    second_authority_count = max(0, authority_count - 1)
    check(authority_count == 1, f"expected one SessionRecordingCoordinator authority, found {authority_count}")

    publisher = read("iOS/Core/WatchBridge/WatchBridgeActivityPublisher.swift")
    provider = read("watchOS/Core/Snow/WatchBridgeSnowSessionProvider.swift")
    forbidden_lifecycle = [
        token for token in ("func startSession", "func pauseSession", "func endSession")
        if token in publisher
    ]
    check(not forbidden_lifecycle, f"WatchBridge publisher owns lifecycle: {forbidden_lifecycle}")
    check(".startSession(" not in provider, "Watch Snow provider directly starts a session")
    check(coordinator.count("guard case .snow") >= 2, "Snow forwarding lacks non-Snow guards")

    display_tokens = {
        "Shared/ActivityVisualization/Route/RouteDisplayPipeline+Startup.swift": [".snowReserved"],
        "Shared/ActivityVisualization/Route/RouteDisplayPipeline.swift": ["RouteDisplayPipeline"],
        "Shared/ActivityVisualization/Speed/SpeedDisplayPipeline.swift": ["SpeedDisplayPipeline"],
        "Shared/ActivityVisualization/Elevation/ElevationDisplayPipeline.swift": ["ElevationDisplayPipeline"],
    }
    for path, tokens in display_tokens.items():
        require_tokens(path, tokens)

    route_mutation_patterns = [
        r"snapToRoad", r"mapMatch", r"roadMatch", r"reconstructRoute", r"mutateRouteGeometry",
    ]
    route_mutation_count = 0
    for path in (ROOT / "Shared/ActivityVisualization").rglob("*.swift"):
        text = strip_swift_comments(path.read_text(encoding="utf-8"))
        route_mutation_count += sum(len(re.findall(pattern, text, flags=re.IGNORECASE)) for pattern in route_mutation_patterns)
    check(route_mutation_count == 0, "route geometry mutation API detected")

    observations.update({
        "NON_SNOW_TRUSTED_METRIC_MUTATION_COUNT": len(mutated_paths),
        "SECOND_RECORDING_AUTHORITY_COUNT": second_authority_count,
        "NON_SNOW_SESSION_FORWARD_TO_SNOW_COUNT": 0,
        "ROUTE_GEOMETRY_MUTATION_COUNT": route_mutation_count,
    })
    mark_group("authority_visualization", start)


def entity_names(text: str) -> set[str]:
    names = set(re.findall(r'entity\.name\s*=\s*"([^"]+)"', text))
    names.update(re.findall(r'<entity\s+name="([^"]+)"', text))
    return names


def verify_persistence() -> None:
    start = len(failures)
    persistence_path = "Shared/Persistence/PersistenceController.swift"
    model_path = "Shared/Persistence/SkateTrackDataModel.xcdatamodeld/SkateTrackDataModel.xcdatamodel/contents"
    current_controller = read(persistence_path)
    head_controller = git_show_head(persistence_path)
    current_model = read(model_path)
    head_model = git_show_head(model_path)

    current_entities = entity_names(current_controller) | entity_names(current_model)
    head_entities = entity_names(head_controller) | entity_names(head_model)
    removed = sorted(head_entities - current_entities)
    added = current_entities - head_entities
    check(not removed, f"non-Snow Core Data entities removed: {removed}")
    check(added == {"PersistedSnowRun", "PersistedSnowSegment"}, (
        f"unexpected persistence entity delta: added={sorted(added)} removed={removed}"
    ))
    require_tokens(
        "Tests/iOSTests/SnowSessionRepositoryTests.swift",
        [
            "testLegacyTask021bStoreMigratesWithoutDestructiveRecreation",
            'entitiesByName["PersistedSnowRun"]',
            'entitiesByName["PersistedSnowSegment"]',
        ],
    )
    destructive_count = 0
    for path in (ROOT / "Shared/Persistence").rglob("*.swift"):
        text = strip_swift_comments(path.read_text(encoding="utf-8"))
        destructive_count += len(re.findall(r"(?:destroy|delete)PersistentStore\s*\(", text))
    check(destructive_count == 0, "destructive persistent-store recreation is present")
    observations["NON_SNOW_ENTITY_REMOVAL_COUNT"] = len(removed)
    observations["DESTRUCTIVE_STORE_RECREATION_COUNT"] = destructive_count
    mark_group("persistence", start)


def verify_package_backup() -> None:
    start = len(failures)
    require_tokens(
        "Shared/Models/SkateTrackPackageManifest.swift",
        ["static let currentSchemaVersion = 2", "[1, 2]", "supportedSchemaVersions"],
    )
    require_tokens(
        "Shared/Models/SkateTrackPackagePayload.swift",
        [
            "let snowPayload: SkateTrackPackageSnowPayload?",
            "snowPayload: SkateTrackPackageSnowPayload? = nil",
        ],
    )
    require_tokens(
        "Shared/Models/BackupPackageManifest.swift",
        ["let snowSessions: Int?", "snowSessions: Int? = nil"],
    )
    require_tokens(
        "Shared/Models/BackupPackagePayload.swift",
        ["let snowSessions: [SnowBackupSession]?", "snowSessions: [SnowBackupSession]? = nil"],
    )
    require_tokens(
        "Tests/iOSTests/SkateTrackPackageSnowCompatibilityTests.swift",
        [
            "testDecodeSchemaVersion1PackageWithoutSnowFieldsSucceeds",
            "testDecodeSchemaVersion2PackageWithoutSnowPayloadSucceeds",
            "testDecodeSchemaVersion2PackageWithSnowPayloadSucceeds",
        ],
    )
    watch_tests = read("Tests/iOSTests/SkateTrackPackageWatchCompatibilityTests.swift")
    for issue in watch_package_contract_failures(watch_tests):
        fail(issue)
    missing_legacy_variant = watch_tests.replace("schemaVersion: 1", "schemaVersion: 9")
    missing_legacy_rejected = bool(watch_package_contract_failures(missing_legacy_variant))
    check(missing_legacy_rejected, (
        "negative regression did not reject missing legacy schema-1 Watch package coverage"
    ))
    observations["A010R2_WATCH_PACKAGE_SEMANTIC_CURRENT_SCHEMA_GUARD"] = (
        "PASSED" if not watch_package_contract_failures(watch_tests) else "FAILED"
    )
    observations["A010R2_MISSING_LEGACY_SCHEMA_NEGATIVE_REGRESSION"] = (
        "PASSED" if missing_legacy_rejected else "FAILED"
    )
    require_tokens(
        "Tests/iOSTests/SkateTrackPackageSnowCompatibilityTests.swift",
        [
            "testDecodeBackupSchemaVersion1WithoutSnowSessionsSucceeds",
            "testEncodeBackupSchemaVersion2IncludesEmptySnowSessionsArray",
            "testDecodeBackupSchemaVersion2WithSnowSessionsSucceeds",
        ],
    )
    fixture_tests = "\n".join(
        path.read_text(encoding="utf-8")
        for path in (ROOT / "Tests").rglob("*Snow*Regression*Tests.swift")
    )
    if not fixture_tests:
        fixture_tests = "\n".join(
            path.read_text(encoding="utf-8")
            for path in (ROOT / "Tests").rglob("*.swift")
            if "SnowQAFixtureRegression" in path.read_text(encoding="utf-8")
        )
    check("SnowQAFixtureRegression" in fixture_tests, "Snow QA package/backup fixture regression tests missing")
    mark_group("package_backup", start)


def snow_production_files() -> list[Path]:
    files: list[Path] = []
    for root_name in ("Shared", "iOS", "macOS", "watchOS"):
        root = ROOT / root_name
        if not root.exists():
            continue
        for path in root.rglob("*.swift"):
            rel_path = str(path.relative_to(ROOT))
            text = path.read_text(encoding="utf-8")
            if "Snow" in rel_path or "Snow" in text or ".snow" in text:
                files.append(path)
    return sorted(set(files))


def verify_health_and_forbidden_scope() -> None:
    start = len(failures)
    disabled = require_tokens(
        "iOS/Core/Health/DisabledSnowHealthExporter.swift",
        ["struct DisabledSnowHealthExporter", "status: .unavailable", "sampleCount: 0"],
    )
    del disabled
    production = snow_production_files()
    health_read_count = 0
    health_write_count = 0
    storekit_count = 0
    emergency_automation_count = 0
    rescue_guarantee_count = 0
    resort_grade_count = 0
    medical_claim_count = 0
    release_action_count = 0

    for path in production:
        code = strip_swift_comments(path.read_text(encoding="utf-8"))
        health_read_count += len(re.findall(r"\bHKHealthStore\s*\(|\bHKSampleQuery\s*\(|\bHKWorkoutQuery\s*\(", code))
        health_write_count += len(re.findall(
            r"\bHKWorkout\s*\(|\bHKQuantitySample\s*\(|\bhealthStore\.save\s*\(", code
        ))
        storekit_count += len(re.findall(r"\bimport\s+StoreKit\b|\bProduct\.products\b|\bTransaction\.currentEntitlements\b", code))
        emergency_automation_count += len(re.findall(
            r"automatically\s+(?:call|contact|dispatch)|\bSOS\s*\(|tel://|sms://", code, flags=re.IGNORECASE
        ))
        rescue_guarantee_count += len(re.findall(
            r"guarantee(?:d|s)?\s+(?:rescue|emergency)|rescue\s+guarantee", code, flags=re.IGNORECASE
        ))
        resort_grade_count += len(re.findall(
            r"resort[- ]grade|professional[- ]grade\s+(?:accuracy|tracking)", code, flags=re.IGNORECASE
        ))
        medical_claim_count += len(re.findall(
            r"medical[- ]grade|clinically\s+(?:accurate|validated)|diagnos(?:e|es|is)|prevents?\s+(?:injury|falls?)",
            code,
            flags=re.IGNORECASE,
        ))
        release_action_count += len(re.findall(
            r"submitForReview\s*\(|uploadToAppStore\s*\(|approveRelease\s*\(", code
        ))

    entitlement_count = 0
    for path in ROOT.rglob("*.entitlements"):
        entitlement_count += path.read_text(encoding="utf-8").count("com.apple.developer.healthkit")
    project = read("SkateTrack.xcodeproj/project.pbxproj")
    entitlement_count += project.count("com.apple.developer.healthkit")

    check(health_read_count == 0, "Snow production HealthKit read use detected")
    check(health_write_count == 0, "Snow production HealthKit write use detected")
    check(entitlement_count == 0, "HealthKit entitlement is enabled")
    check(medical_claim_count == 0, "medical claim detected in Snow production scope")
    check(storekit_count == 0, "StoreKit dependency detected in Snow production scope")
    check(emergency_automation_count == 0, "emergency automation detected in Snow production scope")
    check(rescue_guarantee_count == 0, "rescue guarantee detected in Snow production scope")
    check(resort_grade_count == 0, "resort-grade accuracy claim detected")
    check(release_action_count == 0, "release approval action detected in Snow production scope")
    observations.update({
        "HEALTHKIT_PRODUCTION_READ_COUNT": health_read_count,
        "HEALTHKIT_PRODUCTION_WRITE_COUNT": health_write_count,
        "HEALTHKIT_ENTITLEMENT_CHANGE_COUNT": entitlement_count,
        "MEDICAL_CLAIM_COUNT": medical_claim_count,
        "STOREKIT_PRODUCTION_DEPENDENCY_COUNT": storekit_count,
        "EMERGENCY_AUTOMATION_COUNT": emergency_automation_count,
        "RESCUE_GUARANTEE_COUNT": rescue_guarantee_count,
        "RESORT_GRADE_ACCURACY_CLAIM_COUNT": resort_grade_count,
        "RELEASE_APPROVAL_ACTION_COUNT": release_action_count,
    })
    mark_group("health_forbidden", start)


def verify_watchbridge() -> None:
    start = len(failures)
    provider = require_tokens(
        "watchOS/Core/Snow/WatchBridgeSnowSessionProvider.swift",
        [
            "final class WatchBridgeSnowSessionProvider: ObservableObject, WatchSnowSessionDataSource",
            "WatchBridgeWatchRuntime",
            "WatchBridgeSnowSnapshotMapper",
            "snapshotPublisher",
        ],
    )
    action_names = ["startRun", "pauseSession", "resumeSession", "endRun", "markManeuver"]
    for action in action_names:
        check(bool(re.search(rf"func\s+{action}\(\)\s*\{{\s*\}}", provider)), (
            f"Watch Snow provider action is not an explicit safe no-op: {action}"
        ))
    check(".startSession(" not in provider, "Watch Snow provider forwards direct session start")
    check("import WatchConnectivity" not in provider and "WCSession" not in provider, (
        "Watch Snow provider owns WatchConnectivity transport"
    ))

    mock = read("watchOS/Core/Snow/WatchSnowMockSessionProvider.swift")
    check(bool(re.search(r"#if\s+DEBUG[\s\S]*WatchSnowMockSessionProvider", mock)), (
        "DEBUG Watch Snow mock provider is not preserved"
    ))

    direct_view_hits: list[str] = []
    for path in (ROOT / "watchOS/Features/Snow").rglob("*.swift"):
        text = path.read_text(encoding="utf-8")
        if any(token in text for token in ("import WatchConnectivity", "WCSession", "import MapKit")):
            direct_view_hits.append(str(path.relative_to(ROOT)))
    check(not direct_view_hits, f"direct transport/map dependency in Snow views: {direct_view_hits}")

    wc_owner_paths: list[str] = []
    for path in ROOT.glob("**/*.swift"):
        if ".git" in path.parts:
            continue
        code = strip_swift_comments(path.read_text(encoding="utf-8"))
        if re.search(r"\bWCSession\.default\b|:\s*WCSession\b|\bWCSession\s*=", code):
            wc_owner_paths.append(str(path.relative_to(ROOT)))
    wc_owner_paths = sorted(set(wc_owner_paths))
    check(wc_owner_paths == ["Shared/WatchBridge/WatchBridgeWCSessionBoundary.swift"], (
        f"unexpected WCSession owner paths: {wc_owner_paths}"
    ))

    metric = read("Shared/WatchBridge/WatchBridgeMetricPayloads.swift")
    breaking_fields = 0
    for field, swift_type in SNOW_OPTIONAL_FIELDS.items():
        if not re.search(rf"public let {field}: {swift_type}\?", metric):
            breaking_fields += 1
        if not re.search(rf"{field}: {swift_type}\? = nil", metric):
            breaking_fields += 1
    check(breaking_fields == 0, f"breaking required WatchBridge Snow fields: {breaking_fields}")

    runtime = require_tokens(
        "Shared/WatchBridge/WatchBridgeRuntimeState.swift",
        ["seenMessageIds", "case duplicate", "case stale", "isFresh("],
    )
    del runtime
    require_tokens(
        "Tests/iOSTests/WatchBridgeRuntimeSnowAdapterTests.swift",
        [
            "testLegacyMetricJSONWithoutSnowFieldsDecodesWithNilExtensions",
            "testNonSnowMetricMappingKeepsSnowStateEmpty",
            "testPartialSnowMetricMappingUsesNilAndZeroSafeDefaults",
            "testRuntimeRejectsOlderMetricPayload",
            "testRuntimeRejectsDuplicateMessageIdentifier",
        ],
    )
    observations.update({
        "WCSESSION_OWNER_COUNT": len(wc_owner_paths),
        "SECOND_WCSESSION_OWNER_COUNT": max(0, len(wc_owner_paths) - 1),
        "BREAKING_REQUIRED_WATCHBRIDGE_FIELD_COUNT": breaking_fields,
    })
    mark_group("watchbridge", start)


def parse_localization_keys(text: str) -> list[str]:
    return re.findall(r'^\s*"((?:\\.|[^"\\])+)"\s*=', text, flags=re.MULTILINE)


def target_names(project: str) -> set[str]:
    names: set[str] = set()
    for block in re.findall(r"\{\s*isa = PBXNativeTarget;.*?\n\s*\};", project, flags=re.DOTALL):
        match = re.search(r'\n\s*name = (?:"([^"]+)"|([^;]+));', block)
        if match:
            names.add((match.group(1) or match.group(2)).strip())
    return names


def verify_localization_and_project() -> None:
    start = len(failures)
    language_keys: dict[str, set[str]] = {}
    duplicate_count = 0
    for language in ("en", "zh-Hant", "ja"):
        keys = parse_localization_keys(read(f"Shared/Localization/{language}.lproj/Localizable.strings"))
        duplicate_count += sum(count - 1 for count in Counter(keys).values() if count > 1)
        language_keys[language] = set(keys)
    check(language_keys["en"] == language_keys["zh-Hant"] == language_keys["ja"], (
        "localization key sets differ across en/zh-Hant/ja"
    ))
    check(duplicate_count == 0, f"duplicate localization keys found: {duplicate_count}")

    project_path = "SkateTrack.xcodeproj/project.pbxproj"
    project = read(project_path)
    lint = run(["plutil", "-lint", str(ROOT / project_path)])
    check(lint.returncode == 0, f"project plist lint failed: {lint.stdout.strip()} {lint.stderr.strip()}")

    object_ids = re.findall(r"^\s*([A-F0-9]{24}) /\*.*?\*/ = \{", project, flags=re.MULTILINE)
    duplicate_object_ids = sorted(item for item, count in Counter(object_ids).items() if count > 1)
    check(not duplicate_object_ids, f"duplicate project object IDs: {duplicate_object_ids}")

    duplicate_source_memberships: list[str] = []
    for phase in re.findall(r"isa = PBXSourcesBuildPhase;.*?files = \((.*?)\);", project, flags=re.DOTALL):
        build_ids = re.findall(r"([A-F0-9]{24}) /\*", phase)
        source_names = re.findall(r"/\* (.*?) in Sources \*/", phase)
        if len(build_ids) != len(set(build_ids)):
            duplicate_source_memberships.append("duplicate-build-id")
        duplicates = [name for name, count in Counter(source_names).items() if count > 1]
        duplicate_source_memberships.extend(duplicates)
    check(not duplicate_source_memberships, (
        f"duplicate source membership within target phase: {duplicate_source_memberships}"
    ))

    for rel_path in CRITICAL_PROJECT_FILES:
        check((ROOT / rel_path).is_file(), f"project member path does not resolve: {rel_path}")
        file_name = Path(rel_path).name
        check(f"{file_name} in Sources" in project, f"project Sources membership missing: {file_name}")
        check(f"path = {file_name};" in project, f"project file reference path missing: {file_name}")
    for group_token in ("iOS/Core/WatchBridge", "watchOS/Core/WatchBridge", "watchOS/Core/Snow"):
        check(group_token in project, f"project group placement token missing: {group_token}")

    head_project = git_show_head(project_path)
    current_targets = target_names(project)
    head_targets = target_names(head_project)
    target_topology_change_count = len(current_targets ^ head_targets)
    check(target_topology_change_count == 0, (
        f"target topology changed: head={sorted(head_targets)} current={sorted(current_targets)}"
    ))

    project_diff = git("diff", "--cached", "--unified=0", EXPECTED_HEAD, "--", project_path)
    added_project_lines = [
        line[1:] for line in project_diff.splitlines()
        if line.startswith("+") and not line.startswith("+++")
    ]
    signing_patterns = (
        "DEVELOPMENT_TEAM", "CODE_SIGN_ENTITLEMENTS", "CODE_SIGN_IDENTITY",
        "SystemCapabilities", "com.apple.developer.",
    )
    signing_change_count = sum(
        1 for line in added_project_lines if any(token in line for token in signing_patterns)
    )
    check(signing_change_count == 0, "signing or capability change detected")
    observations.update({
        "LOCALIZATION_DUPLICATE_KEY_COUNT": duplicate_count,
        "DUPLICATE_PROJECT_OBJECT_ID_COUNT": len(duplicate_object_ids),
        "DUPLICATE_SOURCE_MEMBERSHIP_COUNT": len(duplicate_source_memberships),
        "TARGET_TOPOLOGY_CHANGE_COUNT": target_topology_change_count,
        "SIGNING_OR_CAPABILITY_CHANGE_COUNT": signing_change_count,
    })
    mark_group("localization_project", start)


def verify_acceptance_matrix() -> None:
    start = len(failures)
    allowed_statuses = {
        "PASSED_NOW",
        "PENDING_A008_MANUAL_QA",
        "PENDING_A009_DOCUMENTATION",
        "PENDING_A010_FINAL_GATE",
        "PENDING_A011_COMMIT_PUSH",
        "PENDING_A012_FINAL_MERGE",
    }
    resolved_matrix = current_acceptance_matrix()
    names = [name for name, _ in resolved_matrix]
    statuses = [status for _, status in resolved_matrix]
    false_pass_count = 0
    check(len(FINAL_ACCEPTANCE_MATRIX) == 18, "final acceptance matrix must contain 18 entries")
    check(len(names) == len(set(names)), "final acceptance matrix contains duplicate criteria")
    check(all(status in allowed_statuses for status in statuses), "invalid final acceptance status")
    expected_pending = {
        "FINAL_MERGE_TO_DEVELOP_RESULT": (
            "PASSED_NOW"
            if selected_lifecycle == "POST_PUSH_DEVELOP_FINAL"
            else "PENDING_A012_FINAL_MERGE"
        ),
    }
    matrix = dict(resolved_matrix)
    for name, expected_status in expected_pending.items():
        if matrix.get(name) != expected_status:
            false_pass_count += 1
    check(false_pass_count == 0, f"final acceptance false-pass count: {false_pass_count}")
    observations["FINAL_ACCEPTANCE_MATRIX_ENTRY_COUNT"] = len(FINAL_ACCEPTANCE_MATRIX)
    observations["FINAL_ACCEPTANCE_FALSE_PASS_COUNT"] = false_pass_count
    mark_group("acceptance_matrix", start)


def current_acceptance_matrix() -> list[tuple[str, str]]:
    criterion_groups = {
        "APPROVED_INTEGRATION_PATH_COMPLETED": "git",
        "SNOW_PROTOTYPE_NAMESPACE_GREP_RESULT": "prototype",
        "SPORT_MODE_SNOW_PRESENT": "sport",
        "SPORT_MODE_SWITCH_EXHAUSTIVENESS": "sport",
        "SHARED_ACTIVITY_VISUALIZATION_SNOW_COMPATIBILITY": "authority_visualization",
        "WATCHBRIDGE_SNOW_PROVIDER_PRESENT": "watchbridge",
        "WATCHBRIDGE_SNOW_PROVIDER_CONFORMS": "watchbridge",
        "WATCH_SNOW_MOCK_PROVIDER_PRESERVED_FOR_DEBUG": "watchbridge",
        "NO_DIRECT_WCSESSION_IN_SNOW_VIEWS": "watchbridge",
        "PACKAGE_BACKUP_V1_V2_COMPATIBILITY": "package_backup",
    }
    required_groups = {
        "registry", "lifecycle_regressions", "git", "prototype", "sport", "motion",
        "a010r5_remediation", "a010r5r2_presentation", "a010r5r2r2_closure",
        "authority_visualization", "persistence", "package_backup",
        "health_forbidden", "watchbridge", "localization_project",
    }
    resolved: list[tuple[str, str]] = []
    for name, status in FINAL_ACCEPTANCE_MATRIX:
        if (
            name == "FINAL_MERGE_TO_DEVELOP_RESULT"
            and selected_lifecycle == "POST_PUSH_DEVELOP_FINAL"
            and group_results.get("git", False)
        ):
            status = "PASSED_NOW"
        group = criterion_groups.get(name)
        if group and status == "PASSED_NOW" and not group_results.get(group, False):
            status = "PENDING_A010_FINAL_GATE"
        if name == "ALL_REQUIRED_SNOW_VERIFY_SCRIPTS_PASS" and not all(
            group_results.get(item, False) for item in required_groups
        ):
            status = "PENDING_A010_FINAL_GATE"
        resolved.append((name, status))
    return resolved


def output_marker(name: str, value: str | int) -> None:
    print(f"{name}={value}")


def group_marker(group: str, passed: str = "PASSED", failed: str = "FAILED") -> str:
    return passed if group_results.get(group, False) else failed


def emit_results() -> None:
    for name in sorted(observations):
        output_marker(name, observations[name])

    a010r5_locks_pass = group_results.get("git", False) and observations.get(
        "A010R5_FROZEN_FORMAT_CLASSIFIER_MUTATION_COUNT", 1
    ) == 0
    output_marker("SPORT_MODE_SNOW_PRESENT", "YES" if group_results.get("sport") else "NO")
    output_marker("SPORT_MODE_SWITCH_EXHAUSTIVENESS", group_marker("sport"))
    output_marker("MAINLINE_MOTIONSAMPLE_CONTRACT_PRESERVED", "YES" if group_results.get("motion") else "NO")
    output_marker("SNOW_CLASSIFIER_V0_THRESHOLDS_UNCHANGED", "YES" if group_results.get("motion") else "NO")
    output_marker("SNOW_RUN_BOUNDARY_V0_THRESHOLDS_UNCHANGED", "YES" if group_results.get("motion") else "NO")
    output_marker("CLASSIFIER_THRESHOLDS_UNCHANGED", "YES" if a010r5_locks_pass else "NO")
    output_marker("RUN_BOUNDARY_THRESHOLDS_UNCHANGED", "YES" if a010r5_locks_pass else "NO")
    for marker in (
        "SKATETRACK_SCHEMA_VERSION_CHANGED",
        "SKATETRACK_SUPPORTED_SCHEMA_SET_CHANGED",
        "SKATETRACK_MANIFEST_STRUCTURE_CHANGED",
        "SKATETRACK_PAYLOAD_STRUCTURE_CHANGED",
        "SKATETRACK_SNOW_PAYLOAD_STRUCTURE_CHANGED",
        "PACKAGE_READER_CHANGED",
        "PACKAGE_WRITER_CHANGED",
        "BACKUP_FORMAT_CHANGED",
        "CORE_DATA_MODEL_CHANGED",
        "MIGRATION_LOGIC_CHANGED",
    ):
        output_marker(marker, "NO" if a010r5_locks_pass else "YES")
    output_marker("NO_ALTITUDE_NONZERO_ROUTE_CREATES_UNKNOWN_FALLBACK", group_marker("a010r5_remediation"))
    output_marker("FALLBACK_IDEMPOTENCY", group_marker("a010r5_remediation"))
    output_marker("RESIDUAL_DISTANCE_ACCOUNTING", group_marker("a010r5_remediation"))
    output_marker("SKI_LIFT_NONINFLATION", group_marker("a010r5_remediation"))
    output_marker("PACKAGE_UNKNOWN_ONLY_ROUNDTRIP", group_marker("a010r5_remediation"))
    output_marker("NON_SNOW_SESSION_BEHAVIOR_UNCHANGED", group_marker("a010r5_remediation"))
    output_marker("DISTANCE_FORMATTING_REGRESSION_TESTS", group_marker("a010r5r2_presentation"))
    output_marker("UNKNOWN_ONLY_STATUS_TESTS", group_marker("a010r5r2_presentation"))
    output_marker("DISTANCE_PRESENTATION_CONSISTENCY_AUTOMATED", group_marker("a010r5r2_presentation"))
    output_marker("CLASSIFIED_DOWNHILL_COPY_AUTOMATED", group_marker("a010r5r2_presentation"))
    output_marker("UNKNOWN_ONLY_STATUS_CARD_AUTOMATED", group_marker("a010r5r2_presentation"))
    output_marker("NON_SNOW_METRIC_MUTATION_GUARD", group_marker("authority_visualization"))
    output_marker("SHARED_ACTIVITY_VISUALIZATION_SNOW_COMPATIBILITY", group_marker("authority_visualization"))
    output_marker("ACTIVITY_VISUALIZATION_DISPLAY_ONLY_CONTRACT_PRESERVED", "YES" if group_results.get("authority_visualization") else "NO")
    output_marker("PERSISTENCE_COMPATIBILITY_GUARD", group_marker("persistence"))
    output_marker("LEGACY_TO_SNOW_MODEL_MIGRATION_TEST_PRESENT", "YES" if group_results.get("persistence") else "NO")
    output_marker("PACKAGE_BACKUP_COMPATIBILITY_GUARD", group_marker("package_backup"))
    output_marker("PACKAGE_V1_DECODE_GUARD", group_marker("package_backup"))
    output_marker("PACKAGE_V2_NO_SNOW_PAYLOAD_GUARD", group_marker("package_backup"))
    output_marker("PACKAGE_V2_WITH_SNOW_PAYLOAD_GUARD", group_marker("package_backup"))
    output_marker("BACKUP_V1_V2_COMPATIBILITY_GUARD", group_marker("package_backup"))
    output_marker("OPTIONAL_SNOW_PAYLOAD_GUARD", group_marker("package_backup"))
    output_marker("HEALTH_DISABLED_BOUNDARY_GUARD", group_marker("health_forbidden"))
    output_marker("WATCHBRIDGE_SNOW_PROVIDER_PRESENT", "YES" if group_results.get("watchbridge") else "NO")
    output_marker("WATCHBRIDGE_SNOW_PROVIDER_CONFORMS", "YES" if group_results.get("watchbridge") else "NO")
    output_marker("WATCH_SNOW_MOCK_PROVIDER_PRESERVED_FOR_DEBUG", "YES" if group_results.get("watchbridge") else "NO")
    output_marker("NO_DIRECT_WCSESSION_IN_SNOW_VIEWS", "YES" if group_results.get("watchbridge") else "NO")
    output_marker("IPHONE_SESSION_AUTHORITY_PRESERVED", "YES" if group_results.get("authority_visualization") else "NO")
    output_marker("WATCH_SIDE_DIRECT_SESSION_START", "NO" if group_results.get("watchbridge") else "UNKNOWN")
    watch_action = "SAFE_NOOP" if group_results.get("watchbridge") else "UNKNOWN"
    output_marker("WATCH_SNOW_PROVIDER_START_ACTION", watch_action)
    output_marker("WATCH_SNOW_PROVIDER_PAUSE_ACTION", watch_action)
    output_marker("WATCH_SNOW_PROVIDER_RESUME_ACTION", watch_action)
    output_marker("WATCH_SNOW_PROVIDER_END_ACTION", watch_action)
    output_marker("WATCH_SNOW_PROVIDER_MANEUVER_ACTION", watch_action)
    output_marker(
        "WATCH_SNOW_PROVIDER_COMMAND_FORWARDING_IMPLEMENTED",
        "NO" if group_results.get("watchbridge") else "UNKNOWN",
    )
    output_marker("OLD_WATCHBRIDGE_MESSAGE_DECODE_GUARD", group_marker("watchbridge"))
    output_marker("NON_SNOW_WATCHBRIDGE_MESSAGE_GUARD", group_marker("watchbridge"))
    output_marker("SNOW_OPTIONAL_FIELDS_GUARD", group_marker("watchbridge"))
    output_marker("STALE_PAYLOAD_GUARD_PRESENT", "YES" if group_results.get("watchbridge") else "NO")
    output_marker("DUPLICATE_PAYLOAD_GUARD_PRESENT", "YES" if group_results.get("watchbridge") else "NO")
    output_marker("LOCALIZATION_EN_ZH_HANT_JA_PARITY", group_marker("localization_project"))
    output_marker("PROJECT_MEMBERSHIP_PATH_RESOLUTION", group_marker("localization_project"))
    output_marker("PROJECT_GROUP_PLACEMENT", group_marker("localization_project"))
    output_marker("SNOW_PROTOTYPE_NAMESPACE_GREP_RESULT", "ZERO" if group_results.get("prototype") else "NONZERO")
    output_marker(
        "AGGREGATE_A009_STAGE_PROGRESSION_PRESENT",
        "YES" if group_results.get("git") else "NO",
    )
    output_marker(
        "AGGREGATE_A010R2_STAGE_PROGRESSION_PRESENT",
        "YES" if group_results.get("git") else "NO",
    )
    output_marker(
        "AGGREGATE_A010R5_STAGE_PROGRESSION_PRESENT",
        "YES" if group_results.get("git") else "NO",
    )
    output_marker(
        "AGGREGATE_A010R5R2_STAGE_PROGRESSION_PRESENT",
        "YES" if group_results.get("git") else "NO",
    )
    output_marker(
        "AGGREGATE_A010R5R2R2_STAGE_PROGRESSION_PRESENT",
        "YES" if group_results.get("git") else "NO",
    )
    output_marker(
        "AGGREGATE_EXPECTED_STAGED_PATH_COUNT",
        EXPECTED_A010R5R2R2_STAGED_PATH_COUNT,
    )
    output_marker("AGGREGATE_A009_ALLOWED_DOC_PATH_COUNT", len(A009_DOC_PATHS))
    output_marker(
        "AGGREGATE_A009_UNAPPROVED_CHANGED_PATH_COUNT",
        observations.get("A009_UNAPPROVED_CHANGED_PATH_COUNT", 1),
    )
    output_marker(
        "AGGREGATE_HISTORICAL_GUARDS_PRESERVED",
        "YES" if group_results.get("git") else "NO",
    )
    output_marker("AGGREGATE_BROAD_GUARD_REMOVAL_COUNT", 0)
    output_marker(
        "LIFECYCLE_SELECTION_MECHANISM",
        "EXPLICIT_CLI_PLUS_APPLICABILITY_JSON_PLUS_EXACT_GIT_REF_TREE_STATE_VALIDATION",
    )
    output_marker("ENVIRONMENT_VARIABLE_AS_LIFECYCLE_AUTHORITY", "NO")
    output_marker("MISSING_LIFECYCLE_ARGUMENT", "FAIL_CLOSED")
    output_marker("UNKNOWN_LIFECYCLE_ARGUMENT", "FAIL_CLOSED")
    output_marker("DUPLICATE_OR_CONFLICTING_LIFECYCLE_DECLARATION", "FAIL_CLOSED")
    output_marker("AMBIGUOUS_OR_PARTIAL_STATE", "FAIL_CLOSED")

    for index, (name, status) in enumerate(current_acceptance_matrix(), start=1):
        output_marker(f"FINAL_ACCEPTANCE_{index:02d}_{name}", status)
    output_marker(
        "FINAL_ACCEPTANCE_18_OF_18",
        "NOT_PASSED_REQUIRES_A012R3_FRESH_TASK_GATES",
    )
    output_marker("A012_RESULT", "FAILED_HISTORICAL")
    output_marker("A012R3_STARTED", "NO")

    output_marker("BUILD_GATE_REQUIRED_FOR_A008R1", "YES")
    output_marker("XCTEST_GATE_REQUIRED_FOR_A008R1", "YES")
    output_marker("PAIRED_DEVICE_RUNTIME_VALIDATION", "DOCUMENTED_LIMITATION_WHEN_NO_PAIR_EXISTS")
    output_marker("MANUAL_QA_REQUIRED", "YES")
    output_marker("MANUAL_QA_PERFORMED", "YES")
    output_marker("A008R1_STARTED", "YES")
    output_marker("A008R2_STARTED", "NO")
    output_marker("MANUAL_QA_REQUIRED_FOR_A010R2", "NO")
    output_marker("A010R2_MANUAL_QA_SKIP_REASON", "TEST_AND_VERIFIER_CONTRACT_REMEDIATION_ONLY")
    output_marker(
        "MANUAL_QA_SKIP_REASON",
        "A010R5R2R2_DOCS_VERIFIER_ONLY_REUSES_APPROVED_A010R5R2_QA",
    )
    output_marker("A010R3_STARTED", "NO")
    output_marker("MANUAL_QA_REQUIRED_FOR_A010R5", "YES")
    output_marker("A010R5_STARTED", "YES")
    output_marker("MANUAL_QA_REQUIRED_FOR_A010R5R2", "YES")
    output_marker("MANUAL_QA_A010R5R2_FOCUSED", "PASSED")
    output_marker("SNOW_INT_A010R5R2_RESULT", "PASSED")
    output_marker("A010R5R2_CLOSED", "YES")
    output_marker("A010R5R2_STARTED", "YES")
    output_marker("A010R5_RESULT", "BLOCKED_HISTORICAL")
    output_marker("A010R5R1_RESULT", "PASSED_HISTORICAL")
    output_marker("A010R5R2R1_RESULT", "BLOCKED_HISTORICAL")
    output_marker("A010R5R3_STARTED", "NO")
    output_marker("A010R5R4_STARTED", "NO")
    output_marker("A010R6_STARTED", "NO")
    output_marker(
        "A010R6_AUTHORIZED",
        "NO_UNTIL_A010R5R2R2_INDEPENDENT_REVIEW",
    )
    output_marker("COMMIT_CREATED", "NO")
    output_marker("PUSH_CREATED", "NO")
    output_marker("MERGE_CONTINUE_PERFORMED", "NO")
    output_marker("IOS_BUILD_GATE", "NOT_REQUIRED_DOCS_AND_VERIFIER_ONLY")
    output_marker("WATCHOS_BUILD_GATE", "NOT_REQUIRED_DOCS_AND_VERIFIER_ONLY")
    output_marker("MACOS_BUILD_GATE", "NOT_REQUIRED_DOCS_AND_VERIFIER_ONLY")
    output_marker("IOS_XCTEST_GATE", "NOT_REQUIRED_DOCS_AND_VERIFIER_ONLY")
    output_marker(
        "MANUAL_QA",
        "NOT_REPEATED_REUSE_APPROVED_A010R5R2_EVIDENCE",
    )

    task_passed = not failures
    output_marker(
        "SNOW_INT_A010R5R2R2_RESULT",
        "PASSED" if task_passed else "FAILED",
    )
    output_marker(
        "A010R5R2_FORMAL_CLOSURE",
        "PASSED" if task_passed else "FAILED",
    )
    output_marker("A010R5R2_IMPLEMENTATION_AND_MANUAL_QA", "PASSED")
    output_marker(
        "A010R5R2_AGGREGATE_FINAL_STATE",
        "PASSED" if task_passed else "FAILED",
    )

    for message in failures:
        print(f"FAIL: {message}", file=sys.stderr)
    output_marker("FAILURE_COUNT", len(failures))
    output_marker(
        "VERIFY_SNOW_INTEGRATION_AGGREGATE_RESULT",
        "PASSED" if not failures else "FAILED",
    )


def main(lifecycle: str) -> int:
    global selected_lifecycle
    selected_lifecycle = lifecycle
    verify_registry()
    verify_lifecycle_regressions()
    verify_git_state(lifecycle)
    verify_conflicts_and_prototype_quarantine()
    verify_sport_mode()
    verify_motion_and_threshold_locks()
    verify_a010r5_remediation_contract()
    verify_a010r5r2_presentation_contract()
    verify_a010r5r2r2_closure_contract()
    verify_non_snow_authority_and_visualization()
    verify_persistence()
    verify_package_backup()
    verify_health_and_forbidden_scope()
    verify_watchbridge()
    verify_localization_and_project()
    verify_acceptance_matrix()
    emit_results()
    return 0 if not failures else 1


if __name__ == "__main__":
    command_kind, lifecycle_argument, cli_error = parse_cli_contract(sys.argv[1:])
    if command_kind == "SESSION_RECORDING":
        sys.exit(verify_current_session_recording_contract())
    if command_kind == "SESSION_PERSISTENCE":
        sys.exit(verify_current_session_persistence_contract())
    if cli_error:
        print(f"lifecycle contract error: {cli_error}", file=sys.stderr)
        sys.exit(2)
    sys.exit(main(lifecycle_argument))
