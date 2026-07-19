#!/usr/bin/env python3
"""
Task-026a static verification for Backup Package Export Foundation + Disabled Drive Status.
Checks file presence, provider-boundary rules, localization keys, documentation, project membership,
and absence of production Google Drive / OAuth configuration.
"""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "Shared/Models/BackupPackageManifest.swift",
    "Shared/Models/BackupPackagePayload.swift",
    "iOS/Core/Sync/CloudBackupProvider.swift",
    "iOS/Core/Sync/BackupPackageEncoder.swift",
    "iOS/Core/Sync/LocalBackupProvider.swift",
    "iOS/Core/Sync/DisabledDriveProvider.swift",
    "iOS/Hooks/useBackupSync.swift",
    "iOS/Features/Settings/BackupSyncSettingsView.swift",
    "docs/process/DEVELOPMENT_RULES.md",
    "docs/adr/ADR-INDEX.md",
]

REQUIRED_LOCALIZATION_KEYS = [
    "backup.provider.local_package",
    "backup.provider.google_drive",
    "backup.status.export_ready",
    "backup.status.export_ready_with_warnings",
    "backup.drive.status.credentials_missing",
    "backup.drive.access.pro_required",
    "backup.local.title",
    "backup.local.action_create",
    "backup.local.action_share",
    "backup.drive.title",
    "backup.drive.deferred_note",
    "backup.restore.deferred.title",
    "backup.restore.deferred.note",
    "backup.error.file_write",
    "backup.error.drive_unavailable",
]

PROJECT_MEMBERSHIP = [
    "BackupPackageManifest.swift in Sources",
    "BackupPackagePayload.swift in Sources",
    "CloudBackupProvider.swift in Sources",
    "BackupPackageEncoder.swift in Sources",
    "LocalBackupProvider.swift in Sources",
    "DisabledDriveProvider.swift in Sources",
    "useBackupSync.swift in Sources",
    "BackupSyncSettingsView.swift in Sources",
]

FORBIDDEN_PATTERNS = [
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


def assert_file_exists() -> None:
    missing = [path for path in REQUIRED_FILES if not (ROOT / path).exists()]
    if missing:
        fail("Missing required files:\n" + "\n".join(f"  - {item}" for item in missing))


def assert_schema_version() -> None:
    manifest = read("Shared/Models/BackupPackageManifest.swift")
    if "static let currentSchemaVersion = 2" not in manifest:
        fail("BackupPackageManifest must pin schemaVersion as Int = 2.")
    if "static let supportedSchemaVersions: Set<Int> = [1, 2]" not in manifest:
        fail("BackupPackageManifest must keep schema versions 1 / 2 decode support.")
    if "static func validate" not in manifest or "supportedSchemaVersions.contains" not in manifest or "unsupportedSchemaVersion" not in manifest:
        fail("BackupPackageManifest.decode(from:) must reject unsupported schema versions.")
    payload = read("Shared/Models/BackupPackagePayload.swift")
    if "case backup" not in manifest or "packageType" not in manifest:
        fail("Backup manifest must include packageType = backup.")
    if "weeklyChallengeCompletions" not in payload:
        fail("Backup payload must include weekly challenge completion section support.")


def assert_provider_boundary() -> None:
    cloud = read("iOS/Core/Sync/CloudBackupProvider.swift")
    hook = read("iOS/Hooks/useBackupSync.swift")
    view = read("iOS/Features/Settings/BackupSyncSettingsView.swift")
    encoder = read("iOS/Core/Sync/BackupPackageEncoder.swift")
    local = read("iOS/Core/Sync/LocalBackupProvider.swift")
    disabled = read("iOS/Core/Sync/DisabledDriveProvider.swift")

    if "protocol CloudBackupProvider" not in cloud:
        fail("CloudBackupProvider protocol is missing.")
    if "BackupConflictPolicy" not in cloud or "mergeByDate" not in cloud:
        fail("Conflict policy enum must be declared for future restore design.")
    if "useSubscriptionStatus()" not in hook or "hasAccess(to: .googleDriveSync)" not in hook:
        fail("useBackupSync must use subscription hook / GatedFeature.googleDriveSync boundary.")
    if "LocalBackupProvider" in view or "DisabledDriveProvider" in view or "SessionRepository" in view:
        fail("BackupSyncSettingsView must not import or instantiate providers / repositories directly.")
    if "BackupSyncSettingsView()" not in read("iOS/Features/Settings/AccountSettingsView.swift"):
        fail("AccountSettingsView must include BackupSyncSettingsView.")
    if re.search(r"^import\s+CoreData", encoder, flags=re.MULTILINE):
        fail("BackupPackageEncoder must not import CoreData directly.")
    if "GTLR" in local or "URLSession" in local:
        fail("LocalBackupProvider must remain local-only and not use Drive/network implementation APIs.")
    if "throw BackupPackageError.googleDriveUnavailable" not in disabled:
        fail("DisabledDriveProvider must throw googleDriveUnavailable for backup attempts.")


def assert_localization() -> None:
    for locale in ["en.lproj", "zh-Hant.lproj"]:
        content = read(f"Shared/Localization/{locale}/Localizable.strings")
        missing = [key for key in REQUIRED_LOCALIZATION_KEYS if f'"{key}"' not in content]
        if missing:
            fail(f"Missing localization keys in {locale}:\n" + "\n".join(f"  - {key}" for key in missing))


def assert_docs() -> None:
    required_tokens = [
        ("docs/history/DEV_LOG.md", "Task-026a Backup Package Export Foundation"),
        ("docs/reference/FILE_STRUCTURE.md", "BackupSyncSettingsView.swift"),
        ("docs/release/KNOWN_LIMITATIONS_PRE_ADP.md", "Google Drive Sync / Task-026c-blocked"),
        ("docs/adr/ADR-INDEX.md", "Backup Provider and Package Strategy"),
        ("docs/history/DEV_LOG.md", "packageType = backup"),
        ("docs/release/RELEASE_READINESS_PRE_ADP.md", "Task-030a"),
    ]
    for path, token in required_tokens:
        if token not in read(path):
            fail(f"Documentation token missing: {path} -> {token}")


def assert_project_membership() -> None:
    project = read("SkateTrack.xcodeproj/project.pbxproj")
    missing = [token for token in PROJECT_MEMBERSHIP if token not in project]
    if missing:
        fail("Missing Xcode project source membership:\n" + "\n".join(f"  - {token}" for token in missing))


def assert_no_production_google_or_signing() -> None:
    search_roots = [ROOT / "iOS", ROOT / "Shared", ROOT / "SkateTrack.xcodeproj"]
    offenders = []
    for base in search_roots:
        for path in base.rglob("*"):
            if not path.is_file() or path.suffix not in {".swift", ".pbxproj", ".plist", ".strings"}:
                continue
            text = path.read_text(encoding="utf-8", errors="ignore")
            for pattern in FORBIDDEN_PATTERNS:
                if pattern in text:
                    rel = path.relative_to(ROOT)
                    offenders.append(f"{rel}: contains {pattern}")
    if offenders:
        fail("Forbidden production Google / signing tokens found:\n" + "\n".join(offenders[:40]))


def assert_file_lengths() -> None:
    long_files = []
    for path in REQUIRED_FILES:
        if not path.endswith(".swift"):
            continue
        count = len(read(path).splitlines())
        if count >= 500:
            long_files.append(f"{path}: {count} lines")
    if long_files:
        fail("Swift files must stay below 500 lines:\n" + "\n".join(long_files))


def main() -> None:
    assert_file_exists()
    assert_schema_version()
    assert_provider_boundary()
    assert_localization()
    assert_docs()
    assert_project_membership()
    assert_no_production_google_or_signing()
    assert_file_lengths()
    print("✅ Task-026a backup sync verification passed")


if __name__ == "__main__":
    main()
