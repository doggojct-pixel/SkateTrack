#!/usr/bin/env python3
"""
Task-026b static verification for Local Restore Preview + Conflict Policy Simulation.

Scope: verifies non-destructive preview boundaries, localization, project membership,
documentation, and absence of production Google Drive / OAuth configuration.
It does not run simulator UI tests and does not validate runtime VoiceOver behavior.
"""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "Shared/Models/BackupRestorePreview.swift",
    "iOS/Core/Sync/BackupPackageDecoder.swift",
    "iOS/Features/Settings/BackupRestorePreviewView.swift",
    "scripts/verify_backup_restore_preview.py",
]

REQUIRED_LOCALIZATION_KEYS = [
    "backup.restore.preview.title",
    "backup.restore.preview.subtitle",
    "backup.restore.preview.status.ready",
    "backup.restore.preview.status.ready_with_warnings",
    "backup.restore.preview.action_choose",
    "backup.restore.policy.title",
    "backup.restore.policy.local_wins_preview",
    "backup.restore.policy.deferred",
    "backup.restore.policy.note",
    "backup.restore.store.status.decoded",
    "backup.restore.store.status.missing",
    "backup.restore.store.status.failed",
    "backup.restore.error.invalid_package",
    "backup.restore.error.file_import",
]

PROJECT_MEMBERSHIP = [
    "BackupRestorePreview.swift in Sources",
    "BackupPackageDecoder.swift in Sources",
    "BackupRestorePreviewView.swift in Sources",
]

FORBIDDEN_DESTRUCTIVE_TOKENS = [
    "saveCompletedSession(",
    "deleteSession(",
    "saveEquipment(",
    "deleteEquipment(",
    "saveSpot(",
    "deleteSpot(",
    "mergeUnlockedRecords(",
    "mergeCompletedRecords(",
    "UserDefaults.standard.removeObject",
    "destroyPersistentStore",
    "NSBatchDeleteRequest",
]

FORBIDDEN_GOOGLE_TOKENS = [
    "GoogleService-Info.plist",
    "GIDSignIn",
    "GTLRDrive",
    "DriveService",
    "com.googleusercontent.apps",
    "reversed_client_id",
    "client_secret",
    "refresh_token",
    "access_token",
    "com.apple.developer.icloud",
]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def fail(message: str) -> None:
    print(f"❌ {message}")
    sys.exit(1)


def assert_files() -> None:
    missing = [path for path in REQUIRED_FILES if not (ROOT / path).exists()]
    if missing:
        fail("Missing required files:\n" + "\n".join(f"  - {item}" for item in missing))


def assert_decoder_boundaries() -> None:
    decoder = read("iOS/Core/Sync/BackupPackageDecoder.swift")
    manifest = read("Shared/Models/BackupPackageManifest.swift")
    provider = read("iOS/Core/Sync/CloudBackupProvider.swift")
    local = read("iOS/Core/Sync/LocalBackupProvider.swift")
    hook = read("iOS/Hooks/useBackupSync.swift")
    view = read("iOS/Features/Settings/BackupSyncSettingsView.swift")
    preview_view = read("iOS/Features/Settings/BackupRestorePreviewView.swift")

    if "BackupPackageManifest.currentSchemaVersion" not in decoder or "unsupportedSchemaVersion" not in decoder:
        fail("BackupPackageDecoder must validate schemaVersion before preview.")
    if "BackupPackageType.backup.rawValue" not in decoder or "unsupportedPackageType" not in decoder:
        fail("BackupPackageDecoder must reject non-backup package types.")
    if "for key in BackupPackageStoreKey.allCases" not in decoder:
        fail("BackupPackageDecoder must iterate store sections independently.")
    if "static func validate" not in manifest:
        fail("BackupPackageManifest must expose validate(_:) for strict preview validation.")
    if "previewRestorePackage(from fileURL: URL)" not in provider:
        fail("CloudBackupProvider must expose restore preview through the provider boundary.")
    if "BackupPackageDecoder().preview" not in local:
        fail("LocalBackupProvider must delegate preview decoding to BackupPackageDecoder.")
    if "previewRestorePackage(from fileURL: URL)" not in hook:
        fail("useBackupSync must expose previewRestorePackage to Views.")
    if ".fileImporter" not in view or "BackupRestorePreviewView" not in view:
        fail("BackupSyncSettingsView must expose local file selection and preview UI.")
    forbidden_imports = ["LocalBackupProvider", "DisabledDriveProvider", "SessionRepository", "UserDefaults"]
    for token in forbidden_imports:
        if token in preview_view:
            fail(f"BackupRestorePreviewView must not directly access provider/storage token: {token}")


def assert_non_destructive() -> None:
    checked_paths = [
        ROOT / "iOS/Core/Sync/BackupPackageDecoder.swift",
        ROOT / "iOS/Hooks/useBackupSync.swift",
        ROOT / "iOS/Features/Settings/BackupRestorePreviewView.swift",
        ROOT / "iOS/Features/Settings/BackupSyncSettingsView.swift",
    ]
    offenders = []
    for path in checked_paths:
        text = path.read_text(encoding="utf-8")
        for token in FORBIDDEN_DESTRUCTIVE_TOKENS:
            if token in text:
                offenders.append(f"{path.relative_to(ROOT)} contains destructive token {token}")
    if offenders:
        fail("Restore preview must remain non-destructive:\n" + "\n".join(offenders))


def assert_localization() -> None:
    for locale in ["en.lproj", "zh-Hant.lproj"]:
        content = read(f"Shared/Localization/{locale}/Localizable.strings")
        missing = [key for key in REQUIRED_LOCALIZATION_KEYS if f'"{key}"' not in content]
        if missing:
            fail(f"Missing localization keys in {locale}:\n" + "\n".join(f"  - {key}" for key in missing))


def assert_project_membership() -> None:
    project = read("SkateTrack.xcodeproj/project.pbxproj")
    missing = [token for token in PROJECT_MEMBERSHIP if token not in project]
    if missing:
        fail("Missing Xcode project source membership:\n" + "\n".join(f"  - {token}" for token in missing))


def assert_docs() -> None:
    required_tokens = [
        ("docs/history/DEV_LOG.md", "Task-026b — Local Restore Preview"),
        ("docs/reference/FILE_STRUCTURE.md", "Task-026b Local Restore Preview"),
        ("docs/adr/ADR-INDEX.md", "Backup Provider and Package Strategy"),
        ("docs/reference/FILE_STRUCTURE.md", "Conflict Policy"),
    ]
    for path, token in required_tokens:
        if token not in read(path):
            fail(f"Documentation token missing: {path} -> {token}")


def assert_no_production_google_or_signing() -> None:
    offenders = []
    for base in [ROOT / "iOS", ROOT / "Shared", ROOT / "SkateTrack.xcodeproj"]:
        for path in base.rglob("*"):
            if not path.is_file() or path.suffix not in {".swift", ".pbxproj", ".plist", ".strings"}:
                continue
            text = path.read_text(encoding="utf-8", errors="ignore")
            for token in FORBIDDEN_GOOGLE_TOKENS:
                if token in text:
                    offenders.append(f"{path.relative_to(ROOT)} contains {token}")
    if offenders:
        fail("Forbidden production Google / signing tokens found:\n" + "\n".join(offenders[:40]))


def assert_file_lengths() -> None:
    long_files = []
    for path in REQUIRED_FILES:
        if path.endswith(".swift"):
            count = len(read(path).splitlines())
            if count >= 500:
                long_files.append(f"{path}: {count} lines")
    if long_files:
        fail("Swift files must stay below 500 lines:\n" + "\n".join(long_files))


def main() -> None:
    assert_files()
    assert_decoder_boundaries()
    assert_non_destructive()
    assert_localization()
    assert_project_membership()
    assert_docs()
    assert_no_production_google_or_signing()
    assert_file_lengths()
    print("✅ Task-026b restore preview verification passed")


if __name__ == "__main__":
    main()
