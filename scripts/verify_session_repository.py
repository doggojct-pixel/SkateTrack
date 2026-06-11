#!/usr/bin/env python3
"""Verify Task-015a Local Persistence + Session Repository foundation."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "Shared/Persistence/PersistenceController.swift",
    "Shared/Persistence/RepositoryError.swift",
    "Shared/Persistence/SessionRepository.swift",
    "Shared/Persistence/SessionEntityMapper.swift",
    "Shared/Persistence/MotionSampleFileStore.swift",
    "Shared/Persistence/FallEventRepository.swift",
    "Shared/Persistence/SkateTrackDataModel.xcdatamodeld/SkateTrackDataModel.xcdatamodel/contents",
    "Tests/iOSTests/SessionRepositoryTests.swift",
]

PROJECT_FILES = [
    "PersistenceController.swift",
    "RepositoryError.swift",
    "SessionRepository.swift",
    "SessionEntityMapper.swift",
    "MotionSampleFileStore.swift",
    "FallEventRepository.swift",
    "SkateTrackDataModel.xcdatamodeld",
    "SessionRepositoryTests.swift",
]

REQUIRED_SESSION_REPOSITORY_TOKENS = [
    "protocol SessionRepositoryProtocol",
    "func saveCompletedSession",
    "func fetchRecentSessions",
    "func fetchSession",
    "func loadMotionSamples",
    "func deleteSession",
    "func exportSessionBundle",
    "final class SessionRepository",
    "@unchecked Sendable",
]

REQUIRED_PERSISTENCE_TOKENS = [
    "import CoreData",
    "NSPersistentContainer",
    "makeManagedObjectModel",
    "PersistedSession",
    "PersistedFallEvent",
    "PersistedEquipment",
    "PersistedSpot",
]

REQUIRED_FILE_STORE_TOKENS = [
    "final class MotionSampleFileStore",
    "func save(_ samples: [MotionSample]",
    "func load(fileName: String?)",
    "func delete(fileName: String?)",
    "motionSamples.json",
]

REQUIRED_MODEL_TOKENS = [
    "entity name=\"PersistedSession\"",
    "entity name=\"PersistedFallEvent\"",
    "entity name=\"PersistedEquipment\"",
    "entity name=\"PersistedSpot\"",
    "attribute name=\"sampleFileName\"",
    "attribute name=\"sportModeData\"",
]


def read(path: str) -> str:
    target = ROOT / path
    if not target.exists():
        print(f"Missing required file: {path}", file=sys.stderr)
        sys.exit(1)
    return target.read_text(encoding="utf-8")


def require_tokens(name: str, text: str, tokens: list[str]) -> None:
    missing = [token for token in tokens if token not in text]
    if missing:
        print(f"{name} missing required tokens: {missing}", file=sys.stderr)
        sys.exit(1)


def verify_files_exist() -> None:
    for path in REQUIRED_FILES:
        if not (ROOT / path).exists():
            print(f"Missing required file: {path}", file=sys.stderr)
            sys.exit(1)


def verify_project_membership() -> None:
    project = read("SkateTrack.xcodeproj/project.pbxproj")
    for file_name in PROJECT_FILES:
        if file_name not in project:
            print(f"Project file missing reference to {file_name}", file=sys.stderr)
            sys.exit(1)
    declared_ids = re.findall(r"^\s*(15A100000000000000000\w+) /\*[^\n]+\*/ = \{isa", project, re.MULTILINE)
    if len(declared_ids) != len(set(declared_ids)):
        print("Duplicate Task-015a project object declarations detected", file=sys.stderr)
        sys.exit(1)
    if "SessionRepositoryTests.swift in Sources" not in project:
        print("SessionRepositoryTests.swift is not in the iOS test Sources phase", file=sys.stderr)
        sys.exit(1)


def verify_no_task015b_integration_yet() -> None:
    coordinator = read("iOS/Core/SessionRecording/SessionRecordingCoordinator.swift")
    if "saveCompletedSession" in coordinator or "SessionRepository" in coordinator:
        print("Task-015a must not auto-save from SessionRecordingCoordinator yet", file=sys.stderr)
        sys.exit(1)


def verify_localization_keys() -> None:
    en = read("Shared/Localization/en.lproj/Localizable.strings")
    zh = read("Shared/Localization/zh-Hant.lproj/Localizable.strings")
    keys = [
        "repository.error.storeUnavailable",
        "repository.error.sessionNotFound",
        "repository.error.motionSampleFileMissing",
        "repository.error.encodingFailed",
        "repository.error.decodingFailed",
        "repository.error.exportFailed",
        "repository.error.deleteFailed",
    ]
    for key in keys:
        if f'"{key}"' not in en or f'"{key}"' not in zh:
            print(f"Missing localization key: {key}", file=sys.stderr)
            sys.exit(1)


def main() -> None:
    verify_files_exist()
    require_tokens("SessionRepository.swift", read("Shared/Persistence/SessionRepository.swift"), REQUIRED_SESSION_REPOSITORY_TOKENS)
    require_tokens("PersistenceController.swift", read("Shared/Persistence/PersistenceController.swift"), REQUIRED_PERSISTENCE_TOKENS)
    require_tokens("MotionSampleFileStore.swift", read("Shared/Persistence/MotionSampleFileStore.swift"), REQUIRED_FILE_STORE_TOKENS)
    require_tokens("Core Data model", read("Shared/Persistence/SkateTrackDataModel.xcdatamodeld/SkateTrackDataModel.xcdatamodel/contents"), REQUIRED_MODEL_TOKENS)
    require_tokens("SessionRepositoryTests.swift", read("Tests/iOSTests/SessionRepositoryTests.swift"), [
        "testSaveFetchLoadExportAndDeleteCompletedSession",
        "PersistenceController(inMemory: false",
        "saveCompletedSession",
        "fetchRecentSessions",
        "exportSessionBundle",
        "deleteSession",
        "XCTUnwrap(fetchedSession.summaryMetrics)",
    ])
    verify_project_membership()
    verify_no_task015b_integration_yet()
    verify_localization_keys()
    print("Session repository check passed: Task-015a persistence foundation, Core Data model, motion sample file store, repository API, and tests are present")


if __name__ == "__main__":
    main()
