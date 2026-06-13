# ADR-0011 — Pre-ADP Release Readiness Strategy

## Status

Accepted — Task-030a

## Context

By Task-030a, SkateTrack has completed a large local-first development arc: subscription entitlement simulation, session history and summary, local weather / rideability boundaries, achievements, account provider boundaries, backup export and restore preview, portable `.skatetrack` export, macOS package import preview, macOS read-only Session Viewer, background GPS preflight, Japanese localization, and accessibility / privacy quality gates.

However, the project still does not have Apple Developer Program enrollment or production external-service credentials. That blocks TestFlight upload, App Store Connect subscription products, WeatherKit capability, production Google OAuth / Drive sync, cloud entitlements, and final App Store review flows.

Task-030 must therefore be a release-readiness and limitation-alignment gate rather than another feature-expansion task.

## Decision

Task-030a defines a Pre-ADP release-readiness gate with these rules:

- No new production services are added.
- No signing, provisioning, Bundle ID, entitlement, custom UTType, or document-association change is introduced.
- Existing local-first and provider-boundary architecture is documented as the current shipping posture.
- Verify scripts become the first line of defense before Task-030b handoff.
- Known limitations are explicit and user-facing copy must not overclaim production capabilities.
- macOS viewer layout remains constrained by the Task-028a / Task-028b design rule: left sidebar for functions, right-side stacked dashboard for work content.
- Three-language localization is kept active for English, Traditional Chinese, and Japanese, with `pt-BR` and `es` deferred.
- Real-device background GPS testing is promoted to a release-blocking manual QA item before any public release claim.
- Fall Detection must not be validated through unsafe human-impact tests; a future safe diagnostics mode / controlled protocol is required.

Task-030a adds:

- `docs/RELEASE_READINESS_PRE_ADP.md`
- `docs/MANUAL_QA_MATRIX_PRE_ADP.md`
- `scripts/verify_task030_release_readiness.py`

## Consequences

- Task-030 is allowed to add release-readiness scripts and documentation, but should not add major product features.
- Future production-service tasks must explicitly unlock blocked items from `docs/KNOWN_LIMITATIONS_PRE_ADP.md` instead of silently changing behavior.
- TestFlight / App Store submission remains out of scope until Apple Developer Program enrollment and signing / capability review are complete.
- The `develop` branch can be assessed as a Pre-ADP local development release candidate only when Task-030 verification and manual QA gates pass.

## Deferred

- Task-030b final handoff package and next-phase unlock checklist.
- Apple Developer Program enrollment.
- TestFlight / App Store Connect configuration.
- Production StoreKit provider.
- Production Google Sign-In and Google Drive providers.
- CloudKit / iCloud sync.
- WeatherKit live provider.
- `.skatetrack` custom UTType and document association.
- MapKit route rendering, road matching, heat maps, Swift Charts, report export, package library, and persistent macOS import.
- Real-device background GPS outdoor validation if weather or safety prevents immediate testing.
- Safe Fall Detection diagnostics / controlled test protocol.
- Native Japanese review and future `pt-BR` / `es` localization.

Task-030a verification token: pre-ADP release readiness strategy.
