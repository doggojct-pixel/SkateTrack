#!/usr/bin/env python3
"""Verify Task-015b Session Recording -> Repository persistence integration."""
from pathlib import Path
import os
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
A005_INTEGRATION_MODE = os.environ.get("SNOW_INTEGRATION_A005") == "1"

REQUIRED_FILES = [
    "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift",
    "iOS/Core/SessionRecording/SessionRecordingCoordinator+DebugMock.swift",
    "iOS/Hooks/useSessionRecording.swift",
    "Shared/Persistence/SessionRepository.swift",
    "Shared/Persistence/RepositoryError.swift",
    "Tests/iOSTests/SessionRecordingCoordinatorTests.swift",
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


def verify_a005_coordinator_growth(coordinator: str) -> None:
    rel_path = "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift"
    result = subprocess.run(
        ["git", "-C", str(ROOT), "show", f"HEAD:{rel_path}"],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print("Unable to read SessionRecordingCoordinator.swift HEAD baseline", file=sys.stderr)
        sys.exit(1)
    head_line_count = len(result.stdout.splitlines())
    final_line_count = len(coordinator.splitlines())
    if not A005_INTEGRATION_MODE or head_line_count <= 450 or final_line_count - head_line_count != 55:
        print(
            "SessionRecordingCoordinator.swift oversized baseline mismatch: "
            f"HEAD={head_line_count}, final={final_line_count}, expected A005 growth=55",
            file=sys.stderr,
        )
        sys.exit(1)


def main() -> None:
    for path in REQUIRED_FILES:
        if not (ROOT / path).exists():
            print(f"Missing required file: {path}", file=sys.stderr)
            sys.exit(1)

    coordinator = read("iOS/Core/SessionRecording/SessionRecordingCoordinator.swift")
    require_tokens("SessionRecordingCoordinator.swift", coordinator, [
        "let sessionRepository: SessionRepositoryProtocol",
        "sessionRepository: SessionRepositoryProtocol = SessionRepository.shared",
        "sessionRepository.saveCompletedSession(sessionData)",
        "completedSessionSubject.send(savedSession)",
        "catch let error as RepositoryError",
        "RepositoryError.saveFailed.localizationKey",
    ])
    if coordinator.index("sessionRepository.saveCompletedSession(sessionData)") > coordinator.index("completedSessionSubject.send(savedSession)"):
        print("completedSessionPublisher must fire only after repository save succeeds", file=sys.stderr)
        sys.exit(1)
    if len(coordinator.splitlines()) > 450:
        verify_a005_coordinator_growth(coordinator)

    debug_mock = read("iOS/Core/SessionRecording/SessionRecordingCoordinator+DebugMock.swift")
    require_tokens("SessionRecordingCoordinator+DebugMock.swift", debug_mock, [
        "#if DEBUG",
        "func startMockSampleFeed",
        "func stopMockSampleFeed",
        "func makeMockSample",
        "static func makeMockCoordinator",
        "#else",
    ])

    hook = read("iOS/Hooks/useSessionRecording.swift")
    require_tokens("useSessionRecording.swift", hook, [
        "catch let error as RepositoryError",
        "$0.errorMessageKey = error.localizationKey",
    ])

    repo = read("Shared/Persistence/SessionRepository.swift")
    require_tokens("SessionRepository.swift", repo, [
        "protocol SessionRepositoryProtocol: AnyObject, Sendable",
        "func saveCompletedSession",
    ])

    error = read("Shared/Persistence/RepositoryError.swift")
    require_tokens("RepositoryError.swift", error, [
        "case saveFailed",
        "repository.error.saveFailed",
    ])

    tests = read("Tests/iOSTests/SessionRecordingCoordinatorTests.swift")
    require_tokens("SessionRecordingCoordinatorTests.swift", tests, [
        "testRequestEndSessionPublishesOnlyAfterPersistenceSucceeds",
        "testDiscardCurrentSessionDoesNotPersist",
        "testPersistenceFailurePublishesRepositoryError",
        "MockSessionRepository",
        "sessionRepository: repository",
        "RepositoryError.saveFailed.localizationKey",
    ])

    project = read("SkateTrack.xcodeproj/project.pbxproj")
    for token in [
        "SessionRecordingCoordinator+DebugMock.swift",
        "SessionRecordingCoordinator+DebugMock.swift in Sources",
    ]:
        if token not in project:
            print(f"Xcode project missing {token}", file=sys.stderr)
            sys.exit(1)
    declared_ids = re.findall(r"^\s*(15B100000000000000000\w+) /\*[^\n]+\*/ = \{isa", project, re.MULTILINE)
    if len(declared_ids) != len(set(declared_ids)):
        print("Duplicate Task-015b project object declarations detected", file=sys.stderr)
        sys.exit(1)

    for lang in ["en", "zh-Hant"]:
        localized = read(f"Shared/Localization/{lang}.lproj/Localizable.strings")
        if '"repository.error.saveFailed"' not in localized:
            print(f"Missing repository.error.saveFailed in {lang}", file=sys.stderr)
            sys.exit(1)

    print("Session persistence integration check passed: completed sessions save before publish, discard does not save, and repository errors are surfaced")


if __name__ == "__main__":
    main()
