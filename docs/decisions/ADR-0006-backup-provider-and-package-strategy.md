# ADR-0006 — Backup Provider and Package Strategy

**Date:** 2026-06-12  
**Status:** Accepted  
**Related Tasks:** Task-026a, Task-026b, Task-027, Task-028  
**Decision Owner:** SkateTrack project development workflow

## Context

Task-026 introduces backup and future sync foundations after Task-025 established the account provider boundary. SkateTrack still has no production Google OAuth credentials, Drive API scope authorization, external service secrets, Apple Developer Program capabilities, or production cloud backend. The project therefore needs a safe local backup package format and a disabled Drive provider while keeping future restore, Drive sync, and AirDrop package work separable.

The Task-026～030 technical-risk notes are stored in `docs/Task026-030_TechRisk_Solutions.md` and should be consulted before continuing Task-026b through Task-030.

## Decision

Task-026a defines a local-first backup package and provider strategy:

- `BackupPackageManifest.schemaVersion` is an `Int` and currently supports only version `1`.
- Backup package payloads use `packageType = backup` to distinguish complete local backups from future Task-027 portable export packages.
- Store data is encoded independently by `BackupPackageEncoder` so one store failure can be recorded as an issue without pretending the whole provider is cloud sync.
- `LocalBackupProvider` is the only live provider in Task-026a and writes a user-initiated local `.skatetrack-backup.json` file.
- `DisabledDriveProvider` honestly reports Google Drive unavailable until Google OAuth credentials, Drive scopes, privacy review, and production token policy are ready.
- SwiftUI Views use `useBackupSync` and must not import Google SDKs, Drive APIs, providers directly, Core Data objects, or token storage details.
- Restore conflict policy is declared but not executed in Task-026a. Restore preview and any local overwrite behavior remain Task-026b.

## Backup package vs. portable export package

Task-026a backup package is for local backup and future restore preview. It can include sessions, equipment, spots, achievement unlocks, and weekly challenge completion records.

Task-027 `.skatetrack` export package is a separate portable sharing / AirDrop / macOS-viewer format. It should not inherit the backup format accidentally, and it should decide its own privacy redaction, package type, and import behavior.

## Non-goals for Task-026a

- No production Google Drive API.
- No OAuth client ID, reversed client ID URL scheme, Google SDK dependency, or `GoogleService-Info.plist`.
- No Drive scope authorization, remote upload, remote download, background sync, cross-device merge, or server verification.
- No restore preview, destructive local restore, automatic overwrite, `remoteWins`, or `mergeByDate` implementation.
- No signing, capabilities, entitlements, provisioning, Bundle ID, StoreKit production, CloudKit, watchOS UI, or macOS UI changes.
- No AirDrop `.skatetrack` package or macOS import viewer.

## Consequences

### Benefits

- Users can create a user-initiated local backup without external accounts.
- Future Drive integration can replace the disabled provider behind the existing boundary.
- Restore work is forced through preview and conflict policy rather than accidental destructive writes.
- Task-027 and Task-028 keep a clean package boundary.

### Trade-offs

- Task-026a is not cloud sync and does not solve cross-device backup.
- The backup file is a local JSON package rather than a final compressed archive format.
- Restore remains unavailable until Task-026b validates conflict policy and preview UX.

## Follow-up

Task-026b should implement local restore preview and explicit conflict-policy confirmation without silent overwrite. Task-026c / future Google work should only add a real Drive provider after Google OAuth credentials, minimum Drive scopes, privacy copy, token lifecycle, and signing review are ready.

## Task-026b addendum — Restore preview before restore execution

Task-026b extends the backup provider strategy with a non-destructive local restore preview. The decoder validates `schemaVersion == 1` and `packageType = backup`, then decodes each store independently to produce section counts and validation issues.

The preview is intentionally not a restore engine. It does not write to `SessionRepository`, `EquipmentRepository`, `SpotRepository`, `AchievementUnlockStore`, `WeeklyChallengeCompletionStore`, Core Data, or UserDefaults. SwiftUI continues to use `useBackupSync`; Views must not instantiate providers, repositories, or storage layers directly.

### Deferred from Task-026b

- Real restore execution and any local overwrite behavior.
- `remoteWins` and `mergeByDate` conflict-policy implementation.
- Backup-to-local-data merge rules, duplicate detection, and cross-device reconciliation.
- Google Drive download / restore, OAuth / Drive scopes, background sync, and server verification.
- AirDrop `.skatetrack` package import and macOS import viewer.
