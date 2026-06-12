# ADR-0009 — Localization and Privacy Copy Strategy

## Status

Accepted — Task-029a

## Context

SkateTrack now has iOS and macOS user-facing flows for session recording, history, account status, backup preview, portable `.skatetrack` export, macOS package preview, and read-only macOS route / speed visualization. The project already ships English and Traditional Chinese localization resources. Task-029 begins the commercial-readiness quality pass, so localization expansion and privacy copy need to be treated as first-class product work rather than incidental strings.

The app also contains several pre-Apple-Developer-Program constraints: Google Sign-In, Google Drive sync, CloudKit / iCloud, StoreKit production purchases, document association, and some advanced macOS viewer features remain deferred. Localization must not accidentally imply that those services are production-ready.

## Decision

Task-029a adds Japanese localization as the third active language:

- `en`
- `zh-Hant`
- `ja`

The Japanese localization is added as a first-pass product localization and must keep the same key set as English and Traditional Chinese. It includes both `Localizable.strings` and `InfoPlist.strings` so permission prompts for location, background location, motion, and Photos are available in Japanese.

Localization resource files are not governed by the Swift 500-line guideline. The 500-line guideline applies to Swift implementation files where size affects readability, reviewability, and AI/human co-coding. Resource files such as `Localizable.strings`, `InfoPlist.strings`, documentation, and generated-style data are governed by key parity, placeholder parity, syntax validity, and privacy-copy correctness instead.

Task-029a also establishes a deferred localization roadmap:

- `pt-BR` — Brazilian Portuguese, deferred because Brazil is a strong skateboarding market but would add another full QA language surface.
- `es` — Spanish, deferred because it has broader market reach but should follow after the Japanese pass and native review flow are stable.

## Consequences

- `SkateTrack.xcodeproj/project.pbxproj` includes `ja` in `knownRegions` and adds Japanese variants for `Localizable.strings` and `InfoPlist.strings`.
- `scripts/verify_localization_keys.py` now checks English, Traditional Chinese, and Japanese key parity, placeholder parity, and basic project membership.
- `scripts/verify_task029_localization_privacy.py` checks the Task-029a quality gate: Japanese files exist, critical privacy / deferred-service keys are present, InfoPlist permission keys are present, docs include the deferred localization roadmap, and the project did not add document association or cloud capabilities.
- Japanese copy may require native review before production App Store submission; this is documented as a release-readiness item rather than hidden as completed native localization.

## Deferred

- Native Japanese copy review before public release.
- `pt-BR` Brazilian Portuguese localization.
- `es` Spanish localization.
- Migration to String Catalog (`.xcstrings`) or separate localization tables if key volume grows enough to justify a larger localization architecture migration.
- Full accessibility copy audit remains part of the broader Task-029 quality pass after Task-029a localization expansion.
