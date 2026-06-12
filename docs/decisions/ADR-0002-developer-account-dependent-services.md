# ADR-0002 — Developer Account Dependent Services Strategy

**Date:** 2026-06-12  
**Status:** Accepted  
**Related Tasks:** Task-021–030 Developer-Account Aligned v2.0  
**Decision Owner:** SkateTrack project development workflow

## Context

SkateTrack currently does not have an Apple Developer Program account or production external-service credentials. Several future tasks require Apple capabilities, App Store Connect products, WeatherKit entitlements, Google OAuth credentials, Google Drive API scopes, TestFlight access, provisioning profile changes, or external service secrets.

The project must continue feature development without polluting signing, capabilities, production keys, or user-facing claims. Task-016 already established the subscription entitlement provider boundary and DEBUG/local entitlement simulation. Task-019 established mock weather provider architecture. Task-021–030 must follow the same account-aligned strategy.

## Decision

Any feature that depends on an Apple, Google, or external-service account must first be implemented through a **Provider Boundary** and safe local development layer:

- Add a protocol / provider boundary before any real external SDK or entitlement is introduced.
- Use mock, disabled, or local-simulation providers until the relevant account, capability, entitlement, API key, and privacy copy are ready.
- Keep Views dependent on hooks / ViewModels rather than direct WeatherKit, StoreKit transaction, Google SDK, Drive API, signing, or capability APIs.
- Do not modify signing, provisioning, Bundle ID, capabilities, or entitlements unless a task explicitly says the developer-account integration is ready.
- Do not commit secrets, private keys, production tokens, Google client files, or production-like placeholder files that imply a service is live.

## Task-021a Confirmation

Task-021a Spot Management Foundation is account-safe because it is local-first. It adds local `SpotProfile` data, `SpotRepository`, `useSpots`, and iOS Spot list / map / detail / editor UI without requiring WeatherKit, Google services, public spot databases, location permissions, cloud sync, or signing/capability changes.

The Task-021a MapKit usage is limited to rendering user-entered local coordinates. It does not request device location, import `CLLocationManager`, query external places, publish user locations, or claim nearby public spot discovery. Future Task-022 rideability and Task-026 sync work must continue using provider boundaries before any WeatherKit or Google integration.

## Consequences

### Benefits

- Local product functionality can continue before Apple Developer Program enrollment.
- External-service work remains replaceable and testable.
- Signing and capabilities stay stable during local feature development.
- Mock providers cannot be mistaken for production integrations.

### Trade-offs

- Some UI may show local-only or disabled states before real external services are available.
- Production verification remains deferred to explicit integration tasks.
- Account-dependent tasks require a later replacement pass behind the same provider boundaries.

## Non-goals

- No production WeatherKit integration.
- No production StoreKit / App Store Connect integration.
- No Google OAuth or Google Drive API integration.
- No TestFlight upload or App Store Connect release workflow.
- No signing, provisioning, entitlement, or capability changes.


## Task-021b Confirmation

Task-021b remains account-safe. It adds local Session Start Spot selection, archived `SpotSessionSnapshot` persistence, local `SpotVisit` tracking, and History / Summary Spot attribution without requiring WeatherKit, Google services, public places APIs, cloud sync, background location, signing, capabilities, entitlements, or external secrets.

The `SessionSpotPickerView` only reads locally saved Spots from the app repository boundary. It does not request device location, query public places, import Google SDKs, or claim live rideability. Future Task-022 Weather Provider Upgrade and later cloud / Drive tasks must continue replacing providers behind explicit boundaries rather than changing this local Spot association path directly.


## Task-022 Weather Provider Confirmation

Task-022 applies this ADR to weather services. WeatherKit and external weather APIs remain developer-account / external-service dependent and are not enabled in the current local-first phase. The app now uses a `WeatherProviding` boundary with `MockWeatherProvider` for offline development and `DisabledWeatherProvider` for explicit live-service-unavailable fallback.

The new `WeatherRideabilityEngine` combines local mock weather with local Spot metadata, but it does not call WeatherKit, external APIs, URLSession, current-location services, background refresh, or any API-key based service. Future live weather work must add a provider behind the same boundary, keep credentials out of the client, update privacy copy, and perform a separate signing / capability review before integration. This Task-022 implementation is provider boundary + local simulation only, with no WeatherKit production service.

## Task-025a Account Provider Confirmation

Task-025a applies this ADR to account services. Google Sign-In production remains developer-account / external-service dependent and is not enabled in the current local-first phase. The app now has an `AuthProvider` boundary, a `GoogleSignInProviding` protocol, a DEBUG-only `LocalAccountProvider`, a `DisabledGoogleAuthProvider`, an `AuthTokenStore` placeholder, and `useAccount` as the SwiftUI-facing adapter.

This implementation does not import Google SDKs, configure OAuth client IDs, add a reversed client ID URL scheme, add `GoogleService-Info.plist`, request Drive scopes, save access / refresh / ID tokens, perform server verification, or change signing, capabilities, provisioning, Bundle ID, entitlements, StoreKit, WeatherKit, CloudKit, watchOS, or macOS targets.

### Deferred from Task-025a

- Task-025b should add the visible Account settings UI and root navigation entry using the existing `useAccount` boundary.
- Real `GoogleSignInProvider`, Google OAuth client ID, reversed client ID URL scheme, Google SDK dependency, `GoogleService-Info.plist`, real profile loading, token refresh, token revocation, and server verification remain future blocked work.
- Google Drive scope authorization and Google Drive sync remain Task-026 or later work and must use a separate backup / sync provider boundary.
- Production token persistence / Keychain policy must not be completed until the real provider, credentials, minimum OAuth scopes, logout / revocation behavior, and privacy copy are finalized.

## Task-025b Account Settings UI Confirmation

Task-025b applies this ADR to the visible account settings surface. The app now exposes a localized `帳號` / Account root navigation entry and `AccountSettingsView`, but the screen is intentionally backed only by `useAccount`, `LocalAccountProvider`, and `DisabledGoogleAuthProvider`.

The Account screen may show DEBUG-only local simulation sign-in / sign-out controls and a disabled Google provider state. It does not import Google SDKs, start OAuth, open Safari sign-in, add OAuth client IDs, add a reversed client ID URL scheme, add `GoogleService-Info.plist`, request Drive scopes, save production tokens, perform server verification, or change signing, capabilities, provisioning, Bundle ID, entitlements, StoreKit, WeatherKit, CloudKit, watchOS, or macOS targets.

### Deferred from Task-025b

- Real `GoogleSignInProvider`, Google OAuth client ID, reversed client ID URL scheme, Google SDK dependency, `GoogleService-Info.plist`, real profile loading, token refresh, token revocation, server verification, and production token persistence / Keychain policy remain future blocked work.
- Google Drive scope authorization and Google Drive sync remain Task-026 or later work and must use a separate backup / sync provider boundary rather than being hidden inside Task-025b UI.
- Production account deletion, cross-device account recovery, portable account migration, and cloud backup remain future account / sync design tasks.

## Task-026a Backup / Google Drive Confirmation

Task-026a applies this ADR to backup and Google Drive dependent services. The app now has a backup provider boundary, `LocalBackupProvider`, `DisabledDriveProvider`, and `useBackupSync`, but Google Drive production remains developer-account / external-service dependent and unavailable.

The Task-026a UI may create a user-initiated local backup package and present the iOS system share sheet. It does not import Google SDKs, configure OAuth client IDs, add a reversed client ID URL scheme, add `GoogleService-Info.plist`, request Drive scopes, upload to Google Drive, download from Google Drive, perform background sync, merge cross-device data, save production Drive tokens, perform server verification, or change signing, capabilities, provisioning, Bundle ID, entitlements, StoreKit, WeatherKit, CloudKit, watchOS, or macOS targets.

### Deferred from Task-026a

- Real Google Drive provider integration remains blocked until Google OAuth credentials, Drive scopes, privacy copy, token lifecycle, revocation behavior, and server verification are ready.
- Restore preview and conflict policy simulation remain Task-026b and must require explicit user confirmation before any local overwrite path exists.
- Portable AirDrop / `.skatetrack` package work remains Task-027 and must not be conflated with the complete local backup package.

## Task-026c-blocked and Task-027a local export note

Task-026c is formally blocked until Google OAuth credentials, Drive scope authorization, production token lifecycle, logout / revocation behavior, privacy copy, and signing / URL-scheme review are ready. The current implementation remains `DisabledDriveProvider` plus local backup export and non-destructive restore preview.

Task-027a adds a local `.skatetrack` portable session export package. This is a user-initiated local file share and does not integrate Google Drive, Google OAuth, external service secrets, cloud upload / download, background sync, or server verification.

Future production Google Drive work must replace only the provider behind `CloudBackupProvider`; Views must continue to use hooks and must not call Google SDKs, provider internals, token storage, or remote APIs directly.
