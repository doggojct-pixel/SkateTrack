# ADR-0001 — Subscription Entitlement Strategy

**Date:** 2026-06-11
**Status:** Accepted
**Related Task:** Task-016a Subscription Entitlement Simulation Architecture
**Decision Owner:** SkateTrack project development workflow

## Context

SkateTrack is planned as a free-download app with subscription-gated Phase 1a features. The project currently does not have an Apple Developer Program account, so real App Store Connect in-app purchase products, sandbox purchase testing, and production subscription validation cannot be completed yet.

Before Task-016a, the project already had `FeatureFlagEngine` and `useSubscriptionStatus` from Task-004, with real StoreKit entitlement reading intentionally stubbed until Task-016. DEBUG-only subscription override support also already existed for gated-mode testing.

The project still needs subscription-gated UI and paywall flows before real monetization is available. Those flows should not be coupled directly to DEBUG flags or to temporary local simulation state.

## Decision

Task-016 will not implement production App Store Connect subscription yet. Instead, Task-016a establishes a replaceable subscription entitlement architecture:

- `FeatureFlagEngine` remains the single source of truth for gated feature access.
- SwiftUI Views must continue to consume subscription state through `useSubscriptionStatus` rather than reading DEBUG flags directly.
- Entitlement reading is delegated to `SubscriptionEntitlementStore` and `SubscriptionEntitlementProviding`.
- Task-016a uses local/free simulation as the default entitlement provider until real App Store setup exists.
- DEBUG subscription override is represented as a DEBUG-only entitlement provider path, not as production app state.
- Product identifiers are centralized in `PurchaseProductCatalog` so future App Store Connect product IDs are not scattered through Views.
- Future production monetization should add an `AppStoreSubscriptionProvider` that conforms to the same provider boundary.

Core rule:

> SkateTrack Task-016 currently does not directly implement production App Store Connect subscription because the project does not have an Apple Developer Program account. Task-016a must first establish a replaceable entitlement provider architecture: DEBUG/local simulation now, AppStoreSubscriptionProvider later, while keeping FeatureFlagEngine and useSubscriptionStatus as the only app-facing subscription boundaries.

## Consequences

### Benefits

- Current development can continue without an Apple Developer Program account.
- Paywall and locked feature UI can be built against stable app-facing subscription APIs.
- Future StoreKit 2 integration can replace the provider layer without rewriting gating logic or Views.
- DEBUG override remains useful for development while being excluded from Release builds by `#if DEBUG`.
- The project avoids pretending that local simulation is production monetization readiness.

### Trade-offs

- The app is not production-monetization-ready after Task-016a.
- Real purchase, restore, transaction updates, App Store receipt / transaction validation, sandbox testing, and App Store Connect product setup remain deferred.
- Product price display must not be treated as final until StoreKit product metadata is available.

## Deferred Work

Create a later task, likely Task-016c or a monetization-readiness task, to implement:

- Apple Developer Program setup.
- App Store Connect subscription group and products.
- Real product loading through StoreKit 2.
- Purchase and restore flows backed by App Store transactions.
- `Transaction.currentEntitlements` and `Transaction.updates` handling.
- Sandbox and TestFlight validation.
- Final Terms / Privacy / subscription disclosure copy.

## Non-goals for Task-016a

- No real App Store purchase flow.
- No App Store Connect setup.
- No production subscription claim.
- No History UI or unlimited-history enforcement.
- No Session Summary / charts implementation.
- No changes to GPS, IMU, Sensor Fusion, Fall Detection, Launch Screen, AppIcon, bottom dock, watchOS, or macOS.

## Project-wide paid feature rule after Task-017a

Task-017a extends this decision from Task-016-specific subscription work into a project-wide rule for Phase 1a paid features. Any future task that touches paid access, subscriber-only UI, feature limits, or upgrade prompts must keep using the same replaceable entitlement strategy:

- Do not implement production App Store Connect / StoreKit monetization until the Apple Developer Program account and App Store Connect products are ready.
- Do not hardcode paid access in Views, repositories, or feature modules.
- Route feature access through `FeatureFlagEngine` and SwiftUI state through `useSubscriptionStatus`.
- Use DEBUG/local simulation only through the entitlement provider boundary during development.
- When production monetization begins, add or swap in `AppStoreSubscriptionProvider` behind the existing `SubscriptionEntitlementProviding` boundary instead of rewriting History, Paywall, locked-feature, or other subscriber UI.

Task-017a therefore implements the free 5-session History limit and unlimited-history subscriber behavior using `GatedFeature.unlimitedHistory`, `useSubscriptionStatus`, and the existing Task-016b Paywall. Real App Store purchase, restore, transaction, and subscription validation remain deferred.


## Task-017b confirmation

Task-017b continues the same rule while preparing the History-to-Summary handoff. Locked older History entries still open the existing Paywall, unlocked entries open only a local Summary handoff placeholder, and no production StoreKit purchase or restore path is introduced. Future Task-018 Summary UI must consume the same selected-session handoff without bypassing `FeatureFlagEngine`, `useSubscriptionStatus`, or the replaceable entitlement provider strategy.

## Task-018a confirmation

Task-018a introduces the first real Session Summary foundation and core local metrics, but it does not introduce paid chart gating or production monetization. Route maps, advanced charts, and health/calorie data remain deferred. When Task-018c adds subscriber-only advanced charts, it must continue using the project-wide paid feature rule: `FeatureFlagEngine` and `useSubscriptionStatus` are the app-facing boundaries, DEBUG/local entitlement simulation remains the development path, and production App Store monetization is still deferred until a future `AppStoreSubscriptionProvider` task.

## Task-018b confirmation

Task-018b adds the local Summary route map, safety recap, and share-entry stub without introducing subscriber-only chart access or production monetization. Advanced charts remain deferred to Task-018c and must continue following the project-wide paid feature rule: use `FeatureFlagEngine` and `useSubscriptionStatus` as the app-facing boundaries, keep DEBUG/local entitlement simulation as the development path, and defer production App Store monetization until a future `AppStoreSubscriptionProvider` task.


## Task-018c confirmation

Task-018c is the first Summary task that introduces subscriber-only advanced chart UI. It follows the project-wide paid feature rule by gating chart access with `GatedFeature.advancedCharts`, `useSubscriptionStatus`, and the existing Task-016b Paywall. Free users receive a locked advanced-chart preview; DEBUG/local entitlement simulation can unlock the full speed and elevation charts during development. No production StoreKit purchase, App Store Connect product, sandbox tester flow, transaction validation, or `AppStore.sync()` path is introduced.
