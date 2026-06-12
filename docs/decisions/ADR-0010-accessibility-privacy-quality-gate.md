# ADR-0010 — Accessibility, Privacy Copy, and UX Quality Gate

## Status

Accepted — Task-029b

## Context

By Task-029b, SkateTrack has active iOS session recording, local account and backup boundaries, portable `.skatetrack` export, macOS package preview, macOS read-only Session Viewer, lightweight route / speed visualization, and three active localizations: English, Traditional Chinese, and Japanese.

The project also still has explicit pre-Apple-Developer-Program constraints. Google Sign-In, Google Drive sync, CloudKit / iCloud, StoreKit production purchases, custom document association, Finder open-with behavior, MapKit route rendering, road matching, heat maps, report export, and persistent package import remain deferred. Accessibility and privacy copy must not imply those services are complete.

## Decision

Task-029b adds a quality gate focused on accessibility, privacy copy, and UX guardrails rather than new product features.

The gate requires:

- iOS Live HUD and DEBUG-only controls use localized accessibility labels instead of hard-coded English labels.
- macOS package-session summary, read-only Session detail dashboard, route preview, and speed chart expose localized accessibility labels / hints.
- The route preview accessibility value summarizes route sample count, changing route points, and derived distance while still describing the visualization as a lightweight preview.
- The macOS viewer keeps the layout principle learned in Task-028a: left sidebar is function navigation only; right side is the work area with a compact package-session summary and dashboard below.
- Privacy copy continues to state that package viewing is read-only and does not import, merge, restore, sync, upload, or write local storage.
- Verification scripts should catch regressions before Task-030 release readiness.

Task-029b introduces `scripts/verify_task029b_accessibility_privacy_gate.py` to check these requirements.

## Consequences

- Accessibility copy becomes part of localization parity across `en`, `zh-Hant`, and `ja`.
- Future macOS viewer additions must preserve the stacked dashboard layout unless a later ADR changes the layout strategy.
- Future route / chart work must not describe the current SwiftUI Path visualizations as MapKit maps, road-matched routes, heat maps, or full Charts views.
- The project still does not add custom UTType declarations, document association, cloud entitlements, production StoreKit, Google OAuth credentials, or Drive provider production behavior.

## Deferred

- Full VoiceOver walkthrough on physical iPhone and macOS hardware.
- Native Japanese accessibility-copy review before public App Store release.
- Dynamic Type / large-text visual QA across every screen.
- `pt-BR` Brazilian Portuguese localization.
- `es` Spanish localization.
- MapKit route rendering, road matching, heat maps, Swift Charts, multi-session comparison, report export, package library, and persistent import.
