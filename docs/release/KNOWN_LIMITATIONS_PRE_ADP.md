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

## L-012 Route Replay / Track Post-Processing Engine

- **Current status:** Deferred. Task-030c-a adds Core Location diagnostics and route-quality summary metadata only; it does not implement replay, smoothing, map matching, or skiing-specific analysis.
- **Blocked by:** Real-device high-accuracy outdoor recording validation, enough raw location diagnostics, route confidence rendering, and a separate post-processing design for smoothing / interpolation.
- **Current substitute:** `.skatetrack` packages can carry optional `locationDiagnostics`, millisecond timestamps, and `routeQualitySummary` with `location-diagnostics-v1` and `route-quality-summary-v1` capabilities.
- **Unlock condition:** Task-030c-b/c/d validate high-accuracy recording, speed freshness, and low-confidence route rendering on real devices.
- **Future task:** Route Replay & Track Post-Processing Engine after raw Core Location quality is stable; future Snow Mode / Skiing Mode must reuse generic route confidence logic rather than skateboard-only assumptions.
- **Do not claim:** Do not claim road snapping, map matching, navigation-grade route accuracy, precise real-road replay, or ski-app-grade replay before the post-processing engine exists and has real-device validation.

Task-030c-a verification token: simulator / compatibility reference, route-quality-summary-v1, road snapping deferred.
