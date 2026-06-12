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


## Task-019a confirmation

Task-019a introduces the health reminder settings foundation as a subscriber-gated Phase 1a safety feature. It follows the project-wide paid feature rule by gating editable reminder settings with `GatedFeature.healthReminders`, `useSubscriptionStatus`, and the existing Task-016 entitlement provider architecture. Free users can preview the settings and open the existing Paywall; DEBUG/local entitlement simulation can unlock editable local settings during development. No production StoreKit purchase, App Store Connect product, sandbox tester flow, transaction validation, `AppStore.sync()`, WeatherKit, UserNotifications scheduling, or real weather-risk provider path is introduced.

## Task-019b Confirmation

Task-019b continues the same subscription strategy for health reminder runtime behavior. The Live HUD in-app reminder banner is gated through `useSubscriptionStatus` and `GatedFeature.healthReminders`; DEBUG/local entitlement simulation remains the only development-time unlock path. No production StoreKit, App Store Connect, AppStore.sync, or transaction-validation behavior is introduced by Task-019b.

## Task-019c Confirmation

Task-019c extends the subscriber-gated health reminder layer with mock weather suitability and detailed risk guidance. It follows the project-wide paid feature rule by gating detailed heat, UV, and rain guidance through `GatedFeature.healthReminders`, `useSubscriptionStatus`, and the existing Task-016 entitlement provider architecture. Free users can see a basic mock weather summary, while DEBUG/local entitlement simulation can unlock the detailed risk rows during development.

Task-019c intentionally does not implement production StoreKit, App Store Connect products, `AppStore.sync()`, transaction validation, real WeatherKit, network weather APIs, location permission requests, or background weather updates. Future real-weather integration should replace `MockWeatherProvider` behind the `WeatherProviding` boundary without rewriting the Ride-page suitability card or paid-access routing.

## Task-020a Confirmation

Task-020a introduces the subscriber-gated Equipment Manager foundation and CRUD UI. It follows the project-wide paid feature rule by gating real equipment creation, editing, deletion, and wheel / bearing mileage reset actions through `GatedFeature.equipmentManager`, `useSubscriptionStatus`, and the existing `FeatureFlagEngine` / DEBUG-local entitlement simulation architecture. Free users can see the Gear screen and sample equipment cards, while DEBUG/local entitlement simulation can unlock local gear management during development.

Task-020a intentionally does not implement production StoreKit, App Store Connect products, sandbox tester flows, `AppStore.sync()`, transaction validation, photo-library access, cloud sync, or automatic session mileage accumulation. Future Task-020b should connect selected equipment and session-completion mileage through the existing repository / recording-coordinator boundaries without bypassing the entitlement provider strategy.

## Task-020b Confirmation

Task-020b extends the subscriber-gated Equipment Manager into the Session Start and session-completion pipeline. Selecting current-session equipment and applying completed-session mileage to gear are gated through `GatedFeature.equipmentManager`, `useSubscriptionStatus`, and the existing `FeatureFlagEngine` / DEBUG-local entitlement simulation architecture.

Task-020b intentionally applies mileage only after `SessionRepository.saveCompletedSession(_:)` succeeds. Free users do not select sample gear for runtime tracking, discard / failed-save flows do not update mileage, and Views do not mutate `PersistedEquipment` directly. `EquipmentMileageTracker` remains the boundary between session completion and `EquipmentRepository` mileage accumulation.

Task-020b does not implement production StoreKit, App Store Connect products, sandbox tester flows, `AppStore.sync()`, transaction validation, photo-library access, cloud sync, History / Summary gear display, or archived deleted-equipment snapshots. Future production monetization should still replace the entitlement provider behind `FeatureFlagEngine` rather than rewriting the equipment picker or mileage-tracking UI.

## Task-020b compatibility follow-up

Task-020b also requires mode / power compatibility for subscriber-gated equipment tracking. Skateboard equipment must match the current board mode and human / electric power type before it can be selected for a runtime session. Inline equipment must match the current inline mode and remain human-powered. This keeps automatic mileage accumulation from applying to the wrong gear while preserving the same `GatedFeature.equipmentManager`, `useSubscriptionStatus`, `FeatureFlagEngine`, and DEBUG/local entitlement simulation boundary.

## Task-020c Confirmation

Task-020c adds archived equipment attribution for History and Session Summary. It continues the Task-020 subscriber-gated equipment strategy without introducing new monetization behavior. Runtime equipment selection and mileage tracking remain gated through `GatedFeature.equipmentManager`, `useSubscriptionStatus`, `FeatureFlagEngine`, and DEBUG/local entitlement simulation.

Completed sessions now store an optional `EquipmentSessionSnapshot` as `equipmentSnapshotData` on `PersistedSession`. This snapshot preserves the equipment name, type, sport mode, and power type used at ride time so History and Summary can render the original equipment attribution even if the mutable gear profile is later edited or deleted.

Task-020c intentionally does not implement production StoreKit, App Store Connect products, sandbox tester flows, `AppStore.sync()`, transaction validation, gear photos, photo-library access, cloud sync, Summary-to-Gear deep links, maintenance calendar scheduling, or report export. Future production monetization should still replace the entitlement provider behind `FeatureFlagEngine` rather than rewriting equipment attribution, History, or Summary UI.

## Task-021a Confirmation

Task-021a introduces local-first Spot Management and keeps paid-access behavior behind the existing project-wide entitlement strategy. Basic local spot CRUD is available for the foundation workflow, while the free favorite limit is enforced through `GatedFeature.spotManagement`, `useSubscriptionStatus`, and the existing `FeatureFlagEngine` / DEBUG-local entitlement simulation path.

Free users can favorite up to three local spots. Attempting to favorite a fourth spot routes to the existing Paywall through `SubscriptionPaywallView` and the `spotManagement` gated feature. DEBUG/local entitlement simulation can unlock unlimited favorites during development. Task-021a does not introduce production StoreKit, App Store Connect products, sandbox tester flows, `AppStore.sync()`, transaction validation, WeatherKit, Google services, cloud sync, or signing/capability changes.


## Task-021b Confirmation

Task-021b extends local Spot Management into Session Start selection, completed-session Spot snapshots, History attribution, Summary attribution, and local visit tracking. It does not introduce a new production monetization path or bypass the existing project-wide paid-feature rule.

Spot favorite limits remain governed by Task-021a through `GatedFeature.spotManagement`, `useSubscriptionStatus`, `FeatureFlagEngine`, and DEBUG/local entitlement simulation. Task-021b only associates a selected local Spot with a completed session and records a local `SpotVisit` after `SessionRepository.saveCompletedSession(_:)` succeeds. Discarded sessions and failed saves must not update Spot visit counts.

Task-021b intentionally does not implement production StoreKit, App Store Connect products, sandbox tester flows, `AppStore.sync()`, transaction validation, WeatherKit, Google services, cloud sync, public Spot discovery, route-to-Spot auto detection, signing, or capability changes. Future production monetization should still replace the entitlement provider behind `FeatureFlagEngine` rather than rewriting Session Start, History, Summary, or Spot visit tracking UI.


## Task-022 Confirmation

Task-022 extends the Task-019c weather suitability layer into local rideability guidance for Ride Start and Spot detail. Detailed weather, surface, crowd, and safety factors remain gated through `GatedFeature.healthReminders`, `useSubscriptionStatus`, `FeatureFlagEngine`, and DEBUG/local entitlement simulation. Free users can view the basic local rideability status, while Pro / DEBUG subscriber simulation unlocks detailed factor rows.

Task-022 intentionally does not implement production StoreKit, App Store Connect products, sandbox tester flows, `AppStore.sync()`, transaction validation, WeatherKit, external weather APIs, API keys, URLSession networking, current-location permission, background weather refresh, signing, capabilities, Google services, public spot discovery, cloud sync, watchOS UI, or macOS UI. Future production monetization should still replace the entitlement provider behind `FeatureFlagEngine` rather than rewriting weather or rideability UI.

## Task-023a Confirmation

Task-023a introduces the Session Share Card preview foundation as a subscriber-gated Phase 1a feature. It follows the project-wide paid feature rule by gating full share-card preview access with `GatedFeature.sessionShareCard`, `useSubscriptionStatus`, `FeatureFlagEngine`, and DEBUG/local entitlement simulation.

Free users can see a locked share-card preview and route to the existing Paywall. Pro / DEBUG-local subscriber simulation can view the full local preview. Task-023a intentionally does not implement production StoreKit, App Store Connect products, sandbox tester flows, `AppStore.sync()`, transaction validation, PNG rendering, `ImageRenderer`, `UIActivityViewController`, Photos write, AirDrop export package, Google Drive, cloud sync, signing, capabilities, watchOS UI, or macOS UI. Future production monetization should replace the entitlement provider behind `FeatureFlagEngine` rather than rewriting share-card preview, Summary, or export UI.


## Task-023b Confirmation

Task-023b turns the Task-023a Session Share Card preview into a local quick-export flow while preserving the project-wide paid-feature rule. Full share-card export remains gated through `GatedFeature.sessionShareCard`, `useSubscriptionStatus`, `FeatureFlagEngine`, and DEBUG/local entitlement simulation.

Pro / DEBUG-local subscriber simulation can render the share-card preview to a PNG, generate a lightweight summary text file and JSON file in temporary storage, and open the iOS system share sheet. Free users remain on the locked preview and Paywall route, and no export files are generated for them.

Task-023b intentionally does not implement production StoreKit, App Store Connect products, sandbox tester flows, `AppStore.sync()`, transaction validation, Photos write, Photo Library permission, AirDrop-specific export packages, Google Drive, cloud sync, signing, capabilities, watchOS UI, or macOS UI. Future production monetization should replace the entitlement provider behind `FeatureFlagEngine` rather than rewriting share-card export, Summary, or Paywall routing.

## Task-023c Confirmation

Task-023c extends the Task-023 share-card export flow with Save to Photos while preserving the project-wide paid-feature rule. Saving the generated share-card PNG to Photos remains gated through `GatedFeature.sessionShareCard`, `useSubscriptionStatus`, `FeatureFlagEngine`, and DEBUG/local entitlement simulation.

Pro / DEBUG-local subscriber simulation can render the share-card preview to PNG and save that image to Photos through add-only Photo Library authorization. Free users remain on the locked preview and Paywall route, and no Photos save attempt is started for them.

Task-023c intentionally does not implement production StoreKit, App Store Connect products, sandbox tester flows, `AppStore.sync()`, transaction validation, full Photo Library read access, `NSPhotoLibraryUsageDescription`, AirDrop-specific export packages, portable archives, Google Drive, cloud sync, signing, capabilities, watchOS UI, or macOS UI. Future production monetization should replace the entitlement provider behind `FeatureFlagEngine` rather than rewriting share-card export, Photos save, Summary, or Paywall routing.

## Task-024a Confirmation

Task-024a introduces local Achievements and Weekly Challenge foundation without adding production monetization or remote services. Basic achievements are local-first and are computed from saved Session, Equipment, and Spot repository data. Advanced achievements and advanced weekly challenge previews are gated through the new `GatedFeature.advancedChallenges`, `useSubscriptionStatus`, `FeatureFlagEngine`, and DEBUG/local entitlement simulation.

Task-024a intentionally does not implement production StoreKit, App Store Connect products, sandbox tester flows, `AppStore.sync()`, transaction validation, Game Center, remote leaderboards, server verification, cloud sync, push notifications, Google services, signing, or capability changes. Future production monetization should still replace the entitlement provider behind `FeatureFlagEngine` rather than rewriting achievement or weekly challenge UI.

## Task-024b Confirmation

Task-024b completes the local Task-024 achievements / weekly challenge scope without introducing production monetization or remote services. It adds local weekly challenge completion records, a Ride-page achievement dashboard card, related History / Gear / Spot stat links, and additional locally-derived achievement / challenge definitions.

Advanced challenges remain gated through `GatedFeature.advancedChallenges`, `useSubscriptionStatus`, `FeatureFlagEngine`, and DEBUG/local entitlement simulation. Free users can see basic achievements and weekly challenge progress, while advanced goals continue to route through the existing Paywall. Task-024b intentionally does not implement production StoreKit, App Store Connect products, sandbox tester flows, `AppStore.sync()`, transaction validation, Game Center, global leaderboards, social challenges, remote challenge configuration, server verification, push notifications, calendar integration, cloud sync, cross-device challenge state, signing, or capability changes.

ADR-0005 records the Task-024 deferred scope so future leaderboard, sync, trick-count, ARKit, UWB, Game Center, or notification-based challenge work is handled as explicit later tasks rather than being silently folded into the local achievement foundation.
