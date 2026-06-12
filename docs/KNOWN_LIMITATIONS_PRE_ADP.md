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
