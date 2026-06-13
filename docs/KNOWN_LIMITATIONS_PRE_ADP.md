# Known Limitations Before Apple Developer Program / External Credentials

This document tracks features that are intentionally blocked until Apple Developer Program access, App Store Connect setup, Google Cloud credentials, or other external-service prerequisites are available. It complements ADR-0002 and should be checked again before Task-030 release readiness.

## B-001 StoreKit Production Subscription

- **Blocked by:** Apple Developer Program, App Store Connect subscription products, production receipt / transaction testing.
- **Current state:** `LocalSubscriptionEntitlementProvider` defaults to free access; DEBUG can use local entitlement simulation through the existing Task-016 provider boundary.
- **Unlock task:** Add a production StoreKit provider behind the existing entitlement provider boundary.
- **Files likely to change:** `iOS/Core/Subscription/*`, subscription verify scripts, StoreKit configuration / App Store Connect documentation.

## B-002 Google Sign-In Production

- **Blocked by:** Google Cloud project, OAuth client ID, reversed client ID URL scheme, privacy copy, logout / revocation policy, and production token-storage review.
- **Current state:** `DisabledGoogleAuthProvider` plus DEBUG-only `LocalAccountProvider` simulation.
- **Unlock task:** Implement a real Google provider behind `AuthProvider` / `GoogleSignInProviding`.
- **Files likely to change:** `iOS/Core/Account/*`, `iOS/Hooks/useAccount.swift`, Account UI, localization, verify scripts, privacy documentation.

## B-003 Google Drive Sync / Task-026c-blocked

- **Blocked by:** B-002, Drive API scope authorization, production token lifecycle, minimum-scope privacy copy, remote conflict policy, and signing / URL-scheme review.
- **Current state:** `DisabledDriveProvider`, local backup export, and non-destructive restore preview only.
- **Unlock task:** Add a real Google Drive provider behind `CloudBackupProvider` after credentials and scopes are ready.
- **Files likely to change:** `iOS/Core/Sync/*`, `iOS/Hooks/useBackupSync.swift`, Account backup UI, ADR-0006, verify scripts.
- **Not unlocked by Task-027a:** Portable `.skatetrack` export is local file sharing, not Drive sync.

## B-004 Custom `.skatetrack` Document Association

- **Blocked by:** Apple Developer Program / signing review, product decision on inbound file handling, and macOS import behavior.
- **Current state:** Task-027a shares `.skatetrack` as a normal file URL without custom UTType declaration.
- **Unlock task:** Add custom UTType / document association only after incoming-file UX and signing impact are reviewed.
- **Files likely to change:** Info.plist / project settings, package verify script, iOS/macOS import UI.

## B-005 WeatherKit Live Data

- **Blocked by:** Apple Developer Program, WeatherKit capability, privacy copy, and live provider QA.
- **Current state:** Weather work remains mock / disabled / local rideability only.
- **Unlock task:** Add a WeatherKit provider behind the existing weather provider boundary.

## B-006 TestFlight Upload

- **Blocked by:** Apple Developer Program, Bundle ID confirmation, App Store Connect app record, signing setup, and release checklist.
- **Current state:** Local simulator / development builds only.
- **Unlock task:** Task-030b or later release pipeline setup.

## B-007 CloudKit / iCloud Sync

- **Blocked by:** Apple Developer Program, iCloud / CloudKit capability review, data model sync policy, conflict strategy, privacy copy, and device-to-device QA.
- **Current state:** No CloudKit container, iCloud documents, or cloud entitlement is enabled.
- **Unlock task:** Add a replaceable cloud sync provider after local backup / package semantics are stable and capabilities are available.
- **Files likely to change:** Future cloud provider module, sync hooks, account / backup UI, ADR updates, verify scripts, project settings.

## B-008 Real-device Background GPS Release Validation

- **Blocked by:** Outdoor real-device QA with screen off and phone in pocket.
- **Current state:** Background GPS support and simulator moving-route validation are implemented, but simulator behavior does not replace real-device power / lock-screen / location scheduling behavior.
- **Unlock task:** Run iPhone 13 Pro or equivalent outdoor validation: start in foreground, lock screen, pocket carry, move 150–300 m for 3–5 minutes, then confirm non-zero distance, route samples, speed metrics, and route preview.
- **Files likely to change:** Usually none if validation passes; `iOS/Core/SensorEngine` / session metrics only if a blocking real-device bug is found.

## B-009 Fall Detection Diagnostics / Safe Test Mode

- **Blocked by:** Safe controlled test plan, diagnostics UI, and hardware / fixture validation strategy.
- **Current state:** Fall Detection engine and UI foundation exist, but public claims should not imply fully validated real-world crash detection. Human hard-fall testing is unsafe and not required for Task-030a.
- **Unlock task:** Add DEBUG diagnostics / safe test mode showing recent G-force, gyro, candidate impact, stationary confirmation, and alert state. Validate with controlled non-human tests.
- **Files likely to change:** `iOS/Core/SensorEngine`, `iOS/Features/Debug`, Fall Alert UI, verification scripts, ADR updates.

## B-010 Native Japanese Review

- **Blocked by:** Native Japanese copy review and App Store metadata review.
- **Current state:** `ja` is implemented as first-pass product localization with key and placeholder parity.
- **Unlock task:** Native review of product copy, privacy copy, accessibility copy, and App Store metadata before public Japanese-market release.
- **Files likely to change:** `Shared/Localization/ja.lproj/*`, App Store metadata docs.

## B-011 Deferred Localization Roadmap

- **Blocked by:** Localization QA capacity and product-market prioritization.
- **Current state:** English, Traditional Chinese, and Japanese are active. Additional languages are not included in Task-030a.
- **Unlock task:** Add `pt-BR` Brazilian Portuguese first, then `es` Spanish, with key parity, placeholder parity, privacy-copy review, and native review.
- **Files likely to change:** `Shared/Localization`, localization verify scripts, ADR-0009 / ADR-0011 updates.
