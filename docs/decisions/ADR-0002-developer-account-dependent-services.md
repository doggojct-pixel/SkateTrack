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
