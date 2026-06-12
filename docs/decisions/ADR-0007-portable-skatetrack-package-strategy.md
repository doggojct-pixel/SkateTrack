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

## Task-027b update — macOS read-only import preview

Task-027b implements the first macOS consumer for the portable export package while preserving the Task-027a safety boundaries.

- `macOS/App/MacRootView.swift` introduces an independent macOS `NavigationSplitView` shell. It does not import or reuse iOS `RootNavigationView`.
- `macOS/Features/Import/MacImportView.swift` uses `NSOpenPanel` and `UTType.data` to select a user-chosen file. The app still does not declare custom `.skatetrack` UTType metadata, document association, or Finder open-with behavior.
- `MacPackageImportViewModel` validates the `.skatetrack` extension, uses security-scoped access for the selected URL, and delegates decoding to `Shared/Export/SkateTrackPackageReader.swift`.
- `MacPackagePreviewView` displays manifest and session-preview information for `packageType = export` / `schemaVersion = 1` packages only. It does not import records into a local database, restore backups, merge sessions, or sync with cloud services.
- Locked cards are used for session browser, analytics, video overlay, and cloud sync so the macOS app can communicate the PRD direction without implying those features are complete.

### Deferred from Task-027b

- Full macOS viewer, route maps, advanced charts, session browser, Focus Mode, report export, drag-and-drop import, persistent security-scoped bookmarks, local storage import, package merge, custom UTType registration, document association, and Finder open-with behavior remain future tasks.
- Google Drive sync remains blocked by Task-026c. A `.skatetrack` package preview is a local user-initiated file workflow, not cloud sync.
- Task-028 may build on this read-only preview but must continue avoiding production signing, entitlement, iCloud, Google, and StoreKit assumptions until those tasks explicitly unlock them.

## Task-027b UI stability update — custom sidebar inside NavigationSplitView

Manual macOS testing found that the initial `List(selection:)` sidebar could jump to a selected locked destination, hide sibling rows, or make the sidebar feel non-scrollable after moving away from the import screen. The fix keeps the Task-027b architectural decision to use a macOS-native `NavigationSplitView`, but replaces the sidebar list with a small custom `ScrollView` / button sidebar.

Rationale:

- The sidebar destination set is intentionally small and static for Task-027b, so a custom sidebar is simpler and more stable than relying on `List(selection:)` behavior during early macOS shell work.
- The selected destination is now non-optional, preventing transient nil selection states from collapsing the detail view or changing the sidebar layout unexpectedly.
- Explicit top spacing keeps the sidebar content visually below macOS traffic-light window controls while preserving the standard macOS titlebar.
- The detail pane still uses user-initiated `NSOpenPanel` selection and `SkateTrackPackageReader`; no import, merge, restore, document association, or custom UTType behavior is added.

This update does not change package schema, iOS export behavior, signing, capabilities, entitlements, App Groups, iCloud, Google Drive, CloudKit, or StoreKit production boundaries.

## Task-028a update — macOS read-only Session Viewer foundation

Task-028a builds on Task-027b by making the macOS `Session Browser` sidebar destination usable while preserving the portable package boundaries established in Task-027a and Task-027b.

- `MacRootView` owns a shared `MacPackageImportViewModel`, so `MacImportView` and `MacSessionBrowserView` reference the same validated `.skatetrack` package state.
- `MacSessionBrowserView` lists sessions contained in the currently opened package and shows a read-only detail pane for the selected session.
- `MacSessionViewerModel` derives display metrics from motion samples when an older package has route / speed samples but empty summary metrics. This is a viewer-side presentation fallback only; it does not rewrite the package or import data.
- `MacSpeedSparklineView` uses lightweight SwiftUI drawing instead of introducing Swift Charts in Task-028a.
- Route support in Task-028a is limited to availability, start / finish coordinates, route point count, and derived distance. MapKit rendering and heat maps are deferred.

This update intentionally keeps the viewer read-only. It does not add Core Data import, package merge, backup restore, persistent security-scoped bookmarks, drag-and-drop import, custom UTType registration, document association, Finder open-with behavior, Google Drive, iCloud, CloudKit, StoreKit production behavior, or signing / entitlement changes.

Task-028b may extend the viewer with route / chart visualization after a dedicated macOS build and UX check, but must continue to keep storage import, document association, external cloud services, and production paid features out of scope until explicitly unlocked.

## Task-028a layout polish — compact macOS dashboard

Manual review of the first Task-028a viewer confirmed that the data flow was correct, but the visual density was still too close to the iOS card style. Task-028a now treats the macOS Session Browser as a compact macOS dashboard:

- The middle Session list is intentionally narrow and list-like.
- The right detail pane uses compact cards, a shorter hero header, a smaller speed sparkline, and grouped route / privacy sections.
- The viewer remains read-only and package-backed. It does not import, merge, restore, persist, or rewrite package contents.
- MapKit route rendering, Swift Charts, heat maps, multi-session comparison, report export, Finder document association, and custom UTType registration remain deferred to later tasks.

This polish does not alter the ADR-0007 package boundary: `.skatetrack` remains a user-selected portable export file, and macOS still performs only read-only preview / viewing in Task-028a.


## Task-028a layout restructure — right-side stacked layout

Manual UX review found that the first Task-028a macOS Session Browser used a separate middle `Package Sessions` column even though current iOS `.skatetrack` exports are single-session packages. That made the viewer feel empty and consumed space that should belong to the Session detail dashboard.

The Task-028a layout is therefore adjusted to a right-side stacked layout:

- The left sidebar remains the stable macOS function-area navigation.
- The main content top area shows the currently opened package session in a compact summary card.
- The main content bottom area contains the detailed read-only Session dashboard.
- If a future export package contains multiple sessions, selection can appear as a compact horizontal selector inside the top package-session summary rather than as a permanent middle column.

This is a presentation-only restructuring. It does not change package schema, reader / writer behavior, import persistence, document association, custom UTType registration, signing, entitlements, Google Drive, CloudKit, StoreKit production behavior, or iOS runtime.
