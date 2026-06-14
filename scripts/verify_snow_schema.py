#!/usr/bin/env python3
"""Verify Snow-Task-002 production Snow session schema and repository boundary."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "Shared/Models/SnowSegmentType.swift",
    "Shared/Models/SnowSegment.swift",
    "Shared/Models/SnowRun.swift",
    "Shared/Models/SnowDistanceBreakdown.swift",
    "Shared/Models/SnowVerticalMetrics.swift",
    "Shared/Models/SnowSessionState.swift",
    "Shared/Persistence/SnowSessionRepository.swift",
    "Shared/Persistence/SnowSessionEntityMapper.swift",
    "iOS/Hooks/useSnowSession.swift",
    "Tests/iOSTests/SnowSessionRepositoryTests.swift",
]

REQUIRED_SNIPPETS = {
    "Shared/Models/SnowSegmentType.swift": [
        "enum SnowSegmentType",
        "case downhillRun",
        "case liftAscent",
        "case gondolaAscent",
        "case surfaceLiftAscent",
        "case flatTraverse",
        "case walking",
        "case stopped",
        "case unknown",
        "defaultCountsTowardSkiDistance",
    ],
    "Shared/Models/SnowSegment.swift": [
        "struct SnowSegment",
        "let sessionID: UUID",
        "let confidence: Double",
        "let countsTowardSkiDistance: Bool",
        "let manualOverride: Bool?",
    ],
    "Shared/Models/SnowRun.swift": [
        "struct SnowRun",
        "let runNumber: Int",
        "let skiDistanceMeters: Double",
        "let verticalDropMeters: Double",
        "let topSpeedMetersPerSecond: Double",
        "let segmentIDs: [UUID]",
        "let isManualEnd: Bool",
    ],
    "Shared/Models/SnowDistanceBreakdown.swift": [
        "struct SnowDistanceBreakdown",
        "skiDistanceMeters",
        "liftDistanceMeters",
        "routeDistanceMeters",
        "unknownDistanceMeters",
        "static func make(from segments: [SnowSegment])",
    ],
    "Shared/Models/SnowVerticalMetrics.swift": [
        "struct SnowVerticalMetrics",
        "totalVerticalDropMeters",
        "totalVerticalGainMeters",
        "static func make(from segments: [SnowSegment], runs: [SnowRun])",
    ],
    "Shared/Models/SnowSessionState.swift": [
        "struct SnowSessionState",
        "enum LoadState",
        "var runs: [SnowRun]",
        "var segments: [SnowSegment]",
    ],
    "Shared/Persistence/PersistenceController.swift": [
        "model.versionIdentifiers = [\"Phase1cSnowTask002\"]",
        "makePersistedSnowRunEntity()",
        "makePersistedSnowSegmentEntity()",
        "description.shouldMigrateStoreAutomatically = true",
        "description.shouldInferMappingModelAutomatically = true",
    ],
    "Shared/Persistence/SkateTrackDataModel.xcdatamodeld/SkateTrackDataModel.xcdatamodel/contents": [
        "userDefinedModelVersionIdentifier=\"Phase1cSnowTask002\"",
        "entity name=\"PersistedSnowRun\"",
        "entity name=\"PersistedSnowSegment\"",
    ],
    "Shared/Persistence/SnowSessionRepository.swift": [
        "protocol SnowSessionRepositoryProtocol",
        "final class SnowSessionRepository",
        "func saveRun(_ run: SnowRun)",
        "func saveSegment(_ segment: SnowSegment)",
        "func fetchState(sessionID: UUID)",
        "func deleteSnowData(sessionID: UUID)",
    ],
    "Shared/Persistence/SnowSessionEntityMapper.swift": [
        "static let snowRunEntityName = \"PersistedSnowRun\"",
        "static let snowSegmentEntityName = \"PersistedSnowSegment\"",
        "static func upsertRun",
        "static func upsertSegment",
        "static func makeRun",
        "static func makeSegment",
    ],
    "iOS/Hooks/useSnowSession.swift": [
        "final class SnowSessionViewModel",
        "SnowSessionRepositoryProtocol",
        "repository.fetchState",
        "save(segment: SnowSegment)",
        "save(run: SnowRun)",
    ],
    "SkateTrack.xcodeproj/project.pbxproj": [
        "SnowSegmentType.swift in Sources",
        "SnowSegment.swift in Sources",
        "SnowRun.swift in Sources",
        "SnowDistanceBreakdown.swift in Sources",
        "SnowVerticalMetrics.swift in Sources",
        "SnowSessionState.swift in Sources",
        "SnowSessionRepository.swift in Sources",
        "SnowSessionEntityMapper.swift in Sources",
        "useSnowSession.swift in Sources",
        "SnowSessionRepositoryTests.swift in Sources",
    ],
}

LOCALIZATION_KEYS = [
    "snow.segment.downhillRun",
    "snow.segment.liftAscent",
    "snow.segment.gondolaAscent",
    "snow.segment.surfaceLiftAscent",
    "snow.segment.flatTraverse",
    "snow.segment.walking",
    "snow.segment.stopped",
    "snow.segment.unknown",
    "snow.session.error.generic",
    "repository.error.snowRunNotFound",
    "repository.error.snowSegmentNotFound",
]

FORBIDDEN_PATH_PARTS = [
    "Shared/WatchBridge/",
]


def fail(message: str) -> None:
    print(f"[snow-task-002] FAIL: {message}", file=sys.stderr)
    sys.exit(1)


def rel(path: Path) -> str:
    return str(path.relative_to(ROOT))


def read(rel_path: str) -> str:
    path = ROOT / rel_path
    if not path.exists():
        fail(f"missing required file: {rel_path}")
    return path.read_text(encoding="utf-8")


def verify_required_files() -> None:
    for rel_path in REQUIRED_FILES:
        read(rel_path)


def verify_snippets() -> None:
    for rel_path, snippets in REQUIRED_SNIPPETS.items():
        text = read(rel_path)
        for snippet in snippets:
            if snippet not in text:
                fail(f"missing token in {rel_path}: {snippet}")


def verify_localization() -> None:
    for language in ["en", "zh-Hant", "ja"]:
        text = read(f"Shared/Localization/{language}.lproj/Localizable.strings")
        for key in LOCALIZATION_KEYS:
            if f'"{key}"' not in text:
                fail(f"missing localization key {key} in {language}")


def verify_no_prototype_swift() -> None:
    for path in ROOT.glob("**/*.swift"):
        path_text = rel(path)
        if any(part in path_text for part in FORBIDDEN_PATH_PARTS):
            fail(f"Snow-Task-002 must not touch WatchBridge path: {path_text}")
        text = path.read_text(encoding="utf-8")
        if "SnowPrototype" in text:
            fail(f"production Snow schema must not depend on SnowPrototype namespace: {path_text}")


def verify_no_skatetrack_samples() -> None:
    if list(ROOT.glob("**/*.skatetrack")):
        fail(".skatetrack sample package must not be included in Snow-Task-002")


def verify_entity_increment_is_additive() -> None:
    controller = read("Shared/Persistence/PersistenceController.swift")
    existing_entities = [
        "makePersistedSessionEntity()",
        "makePersistedFallEventEntity()",
        "makePersistedEquipmentEntity()",
        "makePersistedSpotEntity()",
        "makePersistedSpotVisitEntity()",
    ]
    for token in existing_entities:
        if token not in controller:
            fail(f"existing Core Data entity registration missing after Snow schema update: {token}")
    for token in ["makePersistedSnowRunEntity()", "makePersistedSnowSegmentEntity()"]:
        if controller.count(token) < 2:
            fail(f"Snow entity not both registered and implemented: {token}")


def main() -> None:
    verify_required_files()
    verify_snippets()
    verify_localization()
    verify_no_prototype_swift()
    verify_no_skatetrack_samples()
    verify_entity_increment_is_additive()
    print("[snow-task-002] PASS: production Snow session value types, Core Data schema, repository, and hook boundary are present and prototype-free.")


if __name__ == "__main__":
    main()
