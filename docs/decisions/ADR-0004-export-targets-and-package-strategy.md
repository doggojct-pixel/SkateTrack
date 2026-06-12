# ADR-0004 — Export Targets and Package Strategy

**Date:** 2026-06-12  
**Status:** Accepted  
**Related Tasks:** Task-023b, Task-023c, Task-027, Task-028  
**Decision Owner:** SkateTrack project development workflow

## Context

Task-023 adds Session Share Card export from the local Session Summary flow. The project already completed Task-023b as a local quick-export path that renders the Pro-gated share card to PNG, writes a lightweight text summary and JSON file into temporary storage, and opens the iOS system share sheet.

Several export-related capabilities are easy to confuse but have different product, privacy, and architecture implications:

- Saving the generated share-card image to Photos.
- Sharing files through the iOS system share sheet.
- Sending files through AirDrop as one possible system share destination.
- Designing a SkateTrack-specific portable archive package for cross-device import or macOS viewing.
- Uploading or syncing exports through Google Drive, iCloud, CloudKit, or other services.

Photos and AirDrop are iPhone built-in capabilities, but they should still be staged carefully. Photos write requires privacy copy, authorization UX, and QA. AirDrop-specific packages and portable archives require a stable file format, manifest versioning, privacy trimming, import behavior, and future macOS viewer compatibility.

## Decision

Task-023c is limited to saving the generated Session Share Card PNG to Photos through add-only Photo Library permission.

Task-023c may:

- Request add-only Photo Library authorization with `PHPhotoLibrary.requestAuthorization(for: .addOnly)`.
- Save only the generated share-card PNG to Photos.
- Add `NSPhotoLibraryAddUsageDescription` and localized InfoPlist copy.
- Surface local success, denied-permission, and failed-save UI.
- Keep the feature gated behind `GatedFeature.sessionShareCard`, `useSubscriptionStatus`, `FeatureFlagEngine`, and DEBUG/local entitlement simulation.

Task-023c must not:

- Request full Photo Library read/write access through `NSPhotoLibraryUsageDescription`.
- Read the user's photo library.
- Use `UIImageWriteToSavedPhotosAlbum` directly from Views.
- Create an AirDrop-specific package.
- Define the final portable archive format.
- Add Google Drive, iCloud, CloudKit, or external service upload.
- Change signing, capabilities, entitlements, Bundle ID, or provisioning.

Task-027 remains responsible for the AirDrop / Export Package workstream. It should define a portable SkateTrack export package only after considering manifest versioning, privacy trimming, route / motion sample inclusion, Spot and equipment snapshots, import compatibility, and future Task-028 macOS viewer needs.

Task-028 remains responsible for macOS import-viewer behavior and must not be pre-empted by a Task-023 quick-export shortcut.

## Consequences

### Benefits

- Users get the practical and familiar ability to save a polished share-card image to Photos before the full export package task.
- Task-023 remains focused on Session Summary sharing instead of becoming the long-term archive format task.
- Photo permission copy and UX are reviewed separately from AirDrop / portable package design.
- Task-027 can design the export package correctly instead of inheriting an accidental Task-023 format.

### Trade-offs

- Task-023c does not provide a complete SkateTrack backup / transfer package.
- AirDrop can still appear as a system share-sheet destination for Task-023b files, but there is no SkateTrack-specific AirDrop archive yet.
- Users who need full session data transfer must wait for Task-027 / Task-028.

## Non-goals for Task-023c

- No AirDrop-specific package.
- No full portable archive.
- No import flow.
- No macOS viewer.
- No Google Drive, iCloud, CloudKit, or external upload.
- No full Photo Library read access.
- No production StoreKit / App Store Connect work.
- No signing, capability, entitlement, Bundle ID, or provisioning changes.

## Follow-up

Task-027 should explicitly decide the portable export package format and determine whether it contains:

- Manifest version and source app version.
- Session metadata.
- Summary metrics.
- Route samples.
- Motion samples or only reduced samples.
- Fall events.
- Spot and equipment snapshots.
- Share-card image.
- Privacy redaction or location trimming options.

Task-028 should consume that format for a macOS shell / import viewer without forcing Task-023 quick-export files to become the canonical archive format.

## Task-026a Backup Package Clarification

Task-026a introduces a complete local backup package for user-initiated backup, not a portable share / AirDrop package. The backup package uses `packageType = backup` and may contain local account-adjacent data such as achievements and weekly challenge completion records so a future restore preview can validate complete local state.

Task-027 remains responsible for the portable `.skatetrack` export package. That future export package should choose its own `packageType = export`, privacy redaction rules, file extension / UTType strategy, and macOS viewer compatibility. Task-026a local backup output must not be treated as the final AirDrop or macOS import format.

## Task-027a Portable `.skatetrack` Export Addendum

Task-027a establishes the first portable SkateTrack package format for a single Session Summary export. This is separate from Task-023 quick share-card files and separate from Task-026 local backup packages.

The Task-027a package uses `packageType = export`, `schemaVersion = 1`, and the `.skatetrack` filename extension. It is shared as a normal file URL through the iOS system share sheet. Task-027a does not declare a custom UTType, does not add document association, and does not modify signing / capabilities / entitlements / provisioning / Bundle ID.

The package intentionally excludes account session data, tokens, Google provider state, Drive provider state, achievements, and weekly challenge completion records. Those remain backup / account-adjacent data and must not be accidentally included in a portable session share file.

Deferred from Task-027a: macOS Import Stub, inbound package handling, custom UTType declaration, batch export, raw motion sample inclusion controls, privacy trimming UI, import / restore into local storage, package merge, and cloud upload / download remain future tasks.
