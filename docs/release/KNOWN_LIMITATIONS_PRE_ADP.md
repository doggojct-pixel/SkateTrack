# Known Limitations Before Apple Developer Program / External Credentials

**Status:** Active source of truth — Task-030b consolidation  
**Last Updated:** 2026-06-13  
**Scope:** Features intentionally blocked until Apple Developer Program enrollment, App Store Connect setup, Google Cloud credentials, production provider configuration, or additional release validation is available.

This file replaces scattered pre-ADP limitation notes from older ADRs. Each item states current status, why it is blocked, the current safe substitute, the unlock condition, the suggested future task, and what must not be claimed.

## L-001 StoreKit Production Subscription

- **Current status:** Local / DEBUG entitlement simulation only.
- **Blocked by:** Apple Developer Program, App Store Connect subscription products, production transaction testing, receipt / transaction validation policy, and App Store metadata.
- **Current substitute:** Replaceable entitlement-provider boundary and local simulation established in Task-016.
- **Unlock condition:** Apple Developer Program is active, App Store Connect products exist, and a production StoreKit provider can be added behind the existing entitlement boundary.
- **Future task:** Production StoreKit provider + App Store subscription QA.
- **Do not claim:** Do not claim production subscriptions, real App Store purchases, production restore purchases, or App Store receipt validation.

## L-002 Google Sign-In Production

- **Current status:** Disabled Google provider plus DEBUG-only local account simulation.
- **Blocked by:** Google Cloud project, OAuth client ID, reversed client ID URL scheme, token lifecycle, logout / revocation behavior, and privacy copy review.
- **Current substitute:** `AuthProvider` / `GoogleSignInProviding` boundary, `DisabledGoogleAuthProvider`, DEBUG `LocalAccountProvider`.
- **Unlock condition:** Production OAuth credentials and URL scheme are available and reviewed.
- **Future task:** Production Google auth provider behind the existing account-provider boundary.
- **Do not claim:** Do not claim real Google login, Google identity verification, or production token storage.

## L-003 Google Drive Sync / Task-026c-blocked

- **Current status:** Blocked; local backup export and non-destructive restore preview only.
- **Blocked by:** Google Sign-In production, Drive API scopes, production token lifecycle, remote conflict policy, and minimum-scope privacy copy.
- **Current substitute:** `DisabledDriveProvider`, local backup package export, restore preview without overwrite.
- **Unlock condition:** Google OAuth and Drive scopes are ready, token storage is reviewed, and conflict policy is designed.
- **Future task:** Real Drive provider behind `CloudBackupProvider`.
- **Do not claim:** Do not claim cloud sync, Google Drive backup, automatic restore, remote merge, or multi-device sync.

## L-004 CloudKit / iCloud Sync

- **Current status:** Not implemented.
- **Blocked by:** Apple Developer Program, CloudKit / iCloud capabilities, CloudKit container, data model sync policy, conflict strategy, and device-to-device QA.
- **Current substitute:** Local data, local backup package, portable `.skatetrack` export.
- **Unlock condition:** Apple Developer Program is active and a CloudKit provider plan is approved.
- **Future task:** Cloud sync provider boundary and CloudKit implementation after local package semantics are stable.
- **Do not claim:** Do not claim Apple cloud sync, iCloud backup, or cross-device automatic sync.

## L-005 WeatherKit Live Data

- **Current status:** Weather work remains mock / disabled / local rideability only.
- **Blocked by:** Apple Developer Program, WeatherKit capability, live provider QA, privacy copy, and fallback behavior.
- **Current substitute:** Mock / local rideability guidance.
- **Unlock condition:** WeatherKit entitlement and live provider design are available.
- **Future task:** WeatherKit provider behind the existing weather boundary.
- **Do not claim:** Do not claim live weather, live UV, live rain, or production WeatherKit forecasts.

## L-006 TestFlight / App Store Submission

- **Current status:** Local simulator / development-device build only.
- **Blocked by:** Apple Developer Program, App Store Connect app record, signing setup, provisioning, TestFlight metadata, privacy labels, screenshots, and review copy.
- **Current substitute:** Pre-ADP local release-readiness gate.
- **Unlock condition:** Apple Developer Program is active and release assets / metadata are prepared.
- **Future task:** TestFlight pipeline and App Store Connect readiness.
- **Do not claim:** Do not claim upload readiness, TestFlight availability, App Store readiness, or review readiness.

## L-007 Custom `.skatetrack` UTType / Finder Open-With / Document Association

- **Current status:** Not implemented; `.skatetrack` is shared / opened as a normal file URL.
- **Blocked by:** Apple Developer Program, signing review, product decision on inbound file handling, Finder open-with behavior, and document association QA.
- **Current substitute:** iOS export share sheet and macOS NSOpenPanel read-only package viewer.
- **Unlock condition:** Incoming-file UX and signing / capability impact are reviewed.
- **Future task:** Custom UTType + document association after package viewer and import semantics are mature.
- **Do not claim:** Do not claim Finder open-with, custom UTType registration, automatic file opening, or document association.

## L-008 Real-device Background GPS Release Validation

- **Current status:** Background GPS code and simulator moving-route validation exist; background GPS release confidence still depends on real-device validation; release-grade real-device validation remains open.
- **Blocked by:** Outdoor iPhone validation with screen off, phone in pocket, real device power management, and location scheduling behavior.
- **Current substitute:** Simulator route testing and manual real-device checklist.
- **Unlock condition:** Run iPhone 13 Pro or equivalent outdoor validation: start in foreground, lock screen, pocket carry, move 150–300 m for 3–5 minutes, then confirm non-zero distance, route samples, speed metrics, and summary / package export consistency.
- **Future task:** Real-device GPS release validation or targeted GPS bugfix if validation fails.
- **Do not claim:** Do not claim fully validated lock-screen background tracking until real-device validation is complete.

## L-009 Fall Detection Diagnostics / Safe Test Mode

- **Current status:** Fall Detection engine and UI foundation exist; real-world safety validation is not complete.
- **Blocked by:** Safe controlled test plan, diagnostics UI, non-human hardware / fixture validation, and safety-copy review.
- **Current substitute:** Existing engine thresholds and fall alert UI foundation.
- **Unlock condition:** Add DEBUG diagnostics / safe test mode showing recent G-force, gyro, candidate impact, stationary confirmation, and alert state; validate with safe controlled tests.
- **Future task:** Fall Detection diagnostics and safe validation protocol.
- **Do not claim:** Do not claim fully validated real-world crash detection; do not ask the user to test by hard-falling with their body.

## L-010 Native Japanese Review

- **Current status:** Japanese is implemented as first-pass product localization.
- **Blocked by:** Native Japanese product-copy, privacy-copy, accessibility-copy, and App Store metadata review.
- **Current substitute:** `ja` key parity, placeholder parity, and first-pass copy QA.
- **Unlock condition:** Native Japanese review is complete and issues are fixed.
- **Future task:** Japanese localization review pass.
- **Do not claim:** Do not claim final Japanese-market copy readiness before native review.

## L-011 Deferred Localization Roadmap

- **Current status:** Active languages are `en`, `zh-Hant`, and `ja`.
- **Blocked by:** Localization QA capacity, native review, and product-market prioritization.
- **Current substitute:** Three-language support.
- **Unlock condition:** Task scope explicitly approves another language and native / QA review is planned.
- **Future task:** Add `pt-BR` Brazilian Portuguese first, then `es` Spanish.
- **Do not claim:** Do not claim Brazilian Portuguese or Spanish support in the current build.

Task-030b verification token: consolidated pre-ADP limitations.
## Phase 1c Snow Mode Follow-up Boundary

Snow-Task-001 integrates the production sport enum and preflight state. Snow-Task-001a keeps the normal user-facing Snow entry DEBUG-only while the production snow data path is incomplete. Snow data schema, classifier logic, RunBoundaryDetector, package compatibility, HealthKit export, and real WatchBridge wiring remain deferred to later Snow tasks. This boundary prevents overclaiming Snow Mode support before Snow-Task-002 through Snow-Task-009 are complete.

Snow-Task-001 verification token: production snow sport enum integrated.
Snow-Task-001a verification token: snow mode public entry debug-gated and controlled by Debug Tools toggle.


### Snow-Task-001b Debug Entry Toggle
- Snow Mode remains production enum code, but the Ride start card is hidden unless the DEBUG Snow Mode entry toggle is enabled.
- Snow-Task-001b verification token: snow mode entry controlled by debug toggle.


## Phase 1c Snow Mode Production Status

- Snow-Task-001 / 001a / 001b: production `SportMode.snow(SnowDiscipline)` exists and the public Session Start entry remains gated behind a DEBUG toggle.
- Snow-Task-002: production Snow value types, additive Core Data schema, repository, and `useSnowSession` data boundary exist.
- Completed through Snow-Task-005: production Snow schema / repository, classifier, RunBoundaryDetector, iPhone Snow live HUD, Snow summary, segment timeline, and distance inspector. Still deferred: `.skatetrack` snow package compatibility, Snow QA fixture packages, macOS Snow viewer, HealthKit snow export, watchOS production wiring, and real WatchBridge snow wiring.
- Snow-Task-006b real WatchBridge wiring remains deferred until mainline Task-040.

### Snow-Task-003 v0 classifier input limitations

Snow-Task-003 v0 classifier intentionally uses the existing `MotionSample` shape without schema changes. `MotionSample` does not yet persist horizontalAccuracy, verticalAccuracy, heading/course, GPS altitude, or barometer source metadata. Because of that:

- Accuracy-aware classification cannot yet reject samples directly by per-sample horizontal / vertical accuracy.
- GPS altitude vs barometer cross-validation is not available in v0.
- Altitude smoothing uses the existing barometer-relative `altitudeMeters` stream.
- Heading is not stored on `MotionSample`; bearing is derived from consecutive GPS coordinates when coordinates are available.
- Gondola-like downhill movement with stable derived bearing and low IMU motion energy is classified as `unknown` instead of `downhillRun` to avoid inflating ski distance.

This limitation is intentional for Snow-Task-003. Future classifier calibration may add backward-compatible optional sensor metadata only after a separate design review.

### Snow-Task-004 v0 RunBoundaryDetector altitude endpoint limitation

Snow-Task-004 v0 intentionally leaves `SnowSegment.startAltitudeMeters` and `SnowSegment.endAltitudeMeters` as `nil` when converting `SnowSegmentClassification` windows into production `SnowSegment` values. `SnowSegmentClassification` currently stores `altitudeDeltaMeters` for the classified window, but it does not preserve raw absolute altitude at the start and end of the window.

As a result, the future Snow-Task-007 macOS elevation profile should treat Snow v0 elevation as an `altitudeDeltaMeters` accumulated estimate, not a true absolute-altitude profile. Absolute altitude start/end storage requires a later sensor-data design pass and should not be inferred in RunBoundaryDetector.

Snow-Task-004 verification token: run boundary detector v0 uses delta-only altitude segments.

Snow-Task-004 v0 explicit verification note: SnowSegment.startAltitudeMeters / endAltitudeMeters are nil in v0 RunBoundaryDetector output; Snow-Task-007 must use altitudeDeltaMeters accumulated estimate for Snow elevation preview until absolute altitude endpoints are added by a later approved task.

### Snow-Task-005 iPhone Snow UI v0 limitations and deferred items

Snow-Task-005 intentionally completes iPhone Snow UI wiring without expanding classifier, detector, sensor schema, package compatibility, or WatchBridge scope.

- Manual correction persistence is not implemented in Snow-Task-005. The live HUD may expose placeholder controls, but editing `SnowSegment.manualOverride` requires a separate UX and persistence task.
- WatchBridge real-data wiring is not implemented in Snow-Task-005. Any Watch low-confidence payload mapping remains deferred to Snow-Task-006b after mainline Task-040.
- True altitude confidence scoring is not implemented in Snow-Task-005 because `MotionSample` v0 still lacks vertical accuracy, GPS altitude, and altitude source metadata.
- Live provisional segment timeline before `RunBoundaryEvent.runEnded` is not implemented. v0 summary / timeline / inspector surfaces use repository-backed finalized Snow segments.
- Simulator-only Snow HUD testing cannot validate real downhill / lift classifier transitions. Real-world snow or controlled fixture replay remains a later QA task.

Snow-Task-005 verification token: production iPhone Snow UI wired to live Snow boundary without classifier/schema/WatchBridge scope creep.

### Snow-Task-006a Watch Snow UI v0 limitations and deferred items

Snow-Task-006a intentionally builds watchOS Snow UI before real WatchBridge transport is available.

- Watch Snow UI is mock-backed in DEBUG builds. It does not receive real iPhone Snow session metrics yet.
- Release builds use a neutral unavailable fallback instead of fake production Snow data.
- `WatchSnowSessionSnapshot` is the production-safe equivalent of the Addendum's prototype session field contract; future real payload mapping belongs in Snow-Task-006b.
- `Shared/WatchBridge/*`, WatchConnectivity, `WCSession`, and `WatchSessionCoordinator` are not modified or referenced by Snow-Task-006a.
- Mock fall-alert UI is not real fall detection, HealthKit, SOS, emergency-contact, or safety-service integration.
- Mock haptic intent text and local haptic boundaries are not a guarantee of final real-device haptic policy.
- Snow-Task-006b real WatchBridge wiring remains deferred until mainline Task-040 is complete and the Snow branch is rebased or merged onto post-Task-040 `develop`.

Snow-Task-006a verification token: mock-backed Watch Snow UI complete without WatchBridge real-data wiring.
