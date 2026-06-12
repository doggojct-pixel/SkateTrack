# ADR-0007 — Portable `.skatetrack` Package Strategy

**Date:** 2026-06-12  
**Status:** Accepted  
**Related Tasks:** Task-026c-blocked, Task-027a, Task-027b, Task-028  
**Decision Owner:** SkateTrack project development workflow

## Context

Task-026a / Task-026b introduced a complete local backup path with `packageType = backup`, restore preview, and disabled Google Drive status. Task-027 begins the separate AirDrop / Files / future macOS viewer workstream. The two formats must not be conflated: backups are for local data preservation and future restore, while portable exports are for sharing or viewing selected session data.

The Task-026～030 technical-risk notes recommend that Task-027 avoid custom UTType declarations before the Apple Developer Program and that `Shared/Export` writer / reader code accept caller-provided URLs instead of hardcoding iOS or macOS paths.

## Decision

Task-027a introduces a portable `.skatetrack` export package foundation with these rules:

- The portable package uses `packageType = export` and `schemaVersion = 1`.
- Task-027a exports a single completed Session from Session Summary.
- The v1 `.skatetrack` file is a JSON package envelope using the `.skatetrack` extension. It is shared as a normal file URL through the existing iOS system share sheet.
- The package can include the exported `SessionData`, effective motion samples, summary metrics, route samples, fall events, trick events, equipment snapshot, and spot snapshot already attached to the session domain model.
- The package must not include account session data, tokens, Google provider state, Drive provider state, achievements, or weekly challenge completion records.
- `Shared/Export/SkateTrackPackageWriter.swift` and `Shared/Export/SkateTrackPackageReader.swift` accept caller-provided URLs. They do not choose iOS temporary paths, macOS sandbox paths, or platform-specific import UI.
- iOS-specific temporary-file creation lives in `iOS/Core/Export/SkateTrackPackageExportProvider.swift`.
- SwiftUI uses `useSkateTrackPackageExport` and `SessionPackageExportActionView`, not the writer directly.

## UTType / signing strategy

Task-027a intentionally does not declare custom UTType metadata. The app shares the generated `.skatetrack` file as a normal file URL through the iOS system share sheet. The filename extension identifies the file for users and future SkateTrack tooling, but there is no document association or incoming open-in-place behavior in this task.

This avoids any accidental signing, entitlement, capability, Bundle ID, or provisioning changes before the Apple Developer Program and document association review are ready.

## Task-026c-blocked alignment

Task-026c remains blocked. The current live state for cloud work is still `DisabledDriveProvider` plus local backup / restore preview. A future real provider must be added behind the existing `CloudBackupProvider` boundary only after OAuth credentials, minimum Drive scope decisions, privacy copy, token lifecycle, logout / revocation behavior, and signing review are ready.

Task-027a does not unblock or replace Task-026c. A `.skatetrack` export is a user-initiated local file share, not cloud sync.

## Consequences

### Benefits

- Task-027a gives users a useful portable session file without external accounts or capabilities.
- The export package is separated from the complete backup package by `packageType = export`.
- Future Task-027b / Task-028 can reuse the reader foundation without inheriting iOS path assumptions.
- Account, achievement, and weekly challenge privacy boundaries remain intact.

### Trade-offs

- Task-027a does not create an inbound document association, custom file type registration, or macOS UI.
- The v1 package is JSON-based and not yet a compressed multi-file archive.
- AirDrop may appear as one destination in the system share sheet, but SkateTrack does not yet implement a receiving/import flow.

## Deferred from Task-027a

- macOS Import Stub, macOS package preview UI, drag-and-drop import, and `NSOpenPanel` import move to Task-027b / Task-028.
- Custom UTType declaration, document association, and incoming file handling remain deferred until signing / capability impact is reviewed.
- Batch session export, raw motion sample inclusion controls, package privacy trimming UI, paid batch-export gating, import / restore into the local database, package merge, and cross-device transfer remain later work.
- Google Drive upload / download, OAuth scope authorization, external-service secrets, production token lifecycle, and server verification remain blocked by Task-026c.
- The package does not include achievements or weekly challenge completion records; future achievement summaries should be separately reviewed.
