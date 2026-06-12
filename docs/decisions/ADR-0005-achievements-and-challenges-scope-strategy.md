# ADR-0005 — Achievements and Challenges Scope Strategy

**Date:** 2026-06-12  
**Status:** Accepted  
**Related Task:** Task-024 Achievements + Weekly Challenges  
**Decision Owner:** SkateTrack project development workflow

## Context

Task-024 adds SkateTrack's first retention layer after local session recording, history, summary, equipment, spots, weather rideability, and share-card export foundations. Achievements and weekly challenges can easily expand into social features, Game Center, push reminders, server verification, remote challenge configuration, or cloud-synced progress.

SkateTrack currently remains local-first and account-aligned. Production StoreKit, Google services, CloudKit, Game Center, push notification scheduling, and server-side services are not ready. The project also avoids reward mechanics that would encourage unsafe riding or misrepresent unreliable sensor data.

## Decision

Task-024 is implemented as a **local-first achievements and weekly challenges layer**:

- Task-024a establishes local achievement models, catalog, engine, unlock store, hook, and Achievements UI.
- Task-024b polishes weekly challenge completion, adds Ride-page dashboard entry, adds History / Gear / Spots related-stat links, and records deferred scope.
- Basic achievements are available from local Session, Equipment, and Spot data.
- Advanced challenges remain gated through `GatedFeature.advancedChallenges`, `FeatureFlagEngine`, `useSubscriptionStatus`, and DEBUG/local entitlement simulation.
- Unlock and completion state is stored locally with `UserDefaults` + Codable JSON. Task-024 intentionally avoids Core Data migration.

## Deferred Scope

Task-024 intentionally does not implement:

- Global leaderboards.
- Friend, team, or social challenges.
- Remote challenge configuration.
- Server-side challenge verification.
- Game Center.
- Push notifications or notification scheduling for challenges.
- Calendar integration.
- Cloud / cross-device challenge state sync.
- Google, iCloud, or CloudKit challenge sync.
- Production StoreKit or App Store Connect monetization.
- Trick-count-based achievements before a reliable trick engine exists.
- Indoor, ARKit, or UWB achievements before their recording modes become product-ready.
- Punitive daily streak mechanics that can create pressure or punish rest days.

## Future Placement

- **After Task-025 / Task-026:** revisit cross-device challenge state only after account / sync provider foundations exist.
- **After Task-027 / Task-028:** evaluate exporting achievement summaries with the portable archive / macOS viewer path.
- **Phase 1b / QA:** consider respectful challenge reminders only after privacy, accessibility, and notification policy review.
- **Phase 2:** evaluate trick-count achievements after reliable trick detection or AI analysis exists.
- **Phase 3:** evaluate ARKit coach-mode achievements after video analysis becomes a separate product mode.
- **Future / B2B:** evaluate venue leaderboards, UWB venue analytics, server-verified competitions, or Game Center only as separate product lines.

## Consequences

### Benefits

- Achievements work offline and remain testable with local repositories.
- No new developer-account, cloud, signing, capability, or server dependency is introduced.
- UI can provide progress motivation without pretending that remote services or unreliable sensor modes are ready.
- Deferred items are explicitly tracked so they do not disappear from the roadmap.

### Trade-offs

- Challenge progress is device-local until a future sync strategy exists.
- There is no leaderboard, social layer, or server-side anti-cheat validation.
- Advanced challenge monetization remains simulated until production StoreKit is implemented.
