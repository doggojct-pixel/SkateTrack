# SkateTrack Pre-ADP Release Readiness Report

**Status:** Task-030b consolidated release-readiness gate  
**Last Updated:** 2026-06-13  
**Scope:** iOS, macOS, shared models, localization, local backup / package export, pre-Apple-Developer-Program service boundaries

This report is the Task-030b consolidated release-readiness source of truth. It does not claim App Store readiness, TestFlight readiness, production subscription readiness, Google Drive readiness, or production cloud readiness. It records what can be verified before Apple Developer Program enrollment and external production credentials are available.

## 0. Documentation source-of-truth gate

Before opening a new task, read the consolidated documentation in this order:

1. `docs/DOCUMENTATION_INDEX.md`
2. `docs/DEVELOPMENT_RULES.md`
3. `docs/KNOWN_LIMITATIONS_PRE_ADP.md`
4. `docs/RELEASE_READINESS_PRE_ADP.md`
5. `docs/MANUAL_QA_MATRIX_PRE_ADP.md`
6. `docs/decisions/ADR-INDEX.md`

The old per-topic ADR files and `docs/Task026-030_TechRisk_Solutions.md` were consolidated during Task-030b and must not reappear as active source-of-truth files. `docs/DEV_LOG.md` remains historical, not the daily rules source.

## 1. Release posture

SkateTrack is currently a **Pre-ADP local-first development build**.

The current build is suitable for:

- Local simulator and development-device QA.
- iOS ride-recording verification.
- macOS `.skatetrack` package preview and read-only Session Viewer verification.
- Three-language localization QA for English, Traditional Chinese, and Japanese.
- Local backup export and non-destructive restore preview testing.
- Verification-script quality gates.

The current build is not suitable for public claims that require production services:

- Production App Store subscription purchases.
- Production Google Sign-In.
- Production Google Drive sync.
- CloudKit / iCloud sync.
- WeatherKit live data.
- TestFlight / App Store submission.
- Finder open-with / document association for `.skatetrack`.

## 2. Required verification scripts

Run these before treating Task-030a as passing:

```bash
python3 scripts/verify_task030_release_readiness.py
python3 scripts/verify_localization_keys.py
python3 scripts/verify_task029_localization_privacy.py
python3 scripts/verify_task029b_accessibility_privacy_gate.py
python3 scripts/verify_macos_session_viewer.py
python3 scripts/verify_macos_route_chart_viewer.py
python3 scripts/verify_macos_package_preview.py
python3 scripts/verify_skatetrack_package.py
python3 scripts/verify_backup_sync.py
python3 scripts/verify_backup_restore_preview.py
python3 scripts/verify_account_provider.py
python3 scripts/verify_gps_background_recording.py
python3 scripts/verify_shared_models.py
python3 scripts/verify_macos_appiconset.py
```

If any script fails, do not proceed to Task-030b handoff or a release-candidate branch.

## 3. Required build commands

Run both platform builds before closing Task-030a:

```bash
xcodebuild \
  -workspace SkateTrack.xcworkspace \
  -scheme SkateTrack-iOS \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build
```

```bash
xcodebuild \
  -workspace SkateTrack.xcworkspace \
  -scheme SkateTrack-macOS \
  -destination 'platform=macOS' \
  build
```

Do not commit if Xcode reports new warnings. Simulator / platform console noise can be ignored only when it is clearly unrelated to SkateTrack source code.

## 4. Source-control gate

Before commit, the working tree should contain only Task-030a documentation and verify-script changes.

Check for signing and capability drift:

```bash
git --no-pager diff -- SkateTrack.xcodeproj/project.pbxproj | grep -n "DEVELOPMENT_TEAM\|CODE_SIGN\|PROVISIONING\|PRODUCT_BUNDLE_IDENTIFIER" || true
```

Expected output: none.

Check for document association / custom UTType / entitlement drift:

```bash
git --no-pager diff -- SkateTrack.xcodeproj/project.pbxproj | grep -n "UTExportedTypeDeclarations\|CFBundleDocumentTypes\|com.apple.developer" || true
```

Expected output: none.

Check shared Xcode schemes for local test pollution:

```bash
git --no-pager diff -- SkateTrack.xcodeproj/xcshareddata/xcschemes
```

Expected output: none, unless the task explicitly changes a shared scheme. Local App Language, App Region, System Language overrides, and Location Scenario settings should not be committed.

## 5. Localization gate

Active languages:

- English (`en`)
- Traditional Chinese (`zh-Hant`)
- Japanese (`ja`)

Rules:

- `Localizable.strings` keys must match across all active languages.
- Placeholder counts must match across all active languages.
- `InfoPlist.strings` must include privacy-sensitive permission copy for active languages.
- Japanese is a first-pass localization and needs native review before public App Store release.
- `Localizable.strings` is not subject to the Swift 500-line guideline; key parity and placeholder parity are the quality standards.

Deferred localization roadmap:

- `pt-BR` Brazilian Portuguese
- `es` Spanish

## 6. Service-boundary gate

The current codebase must not claim or enable production services that remain blocked:

| Area | Current state | Release gate |
|---|---|---|
| StoreKit | DEBUG / local entitlement simulation only | Do not claim production subscriptions. |
| Google Sign-In | Provider boundary + disabled provider + DEBUG local simulation | Do not claim real Google login. |
| Google Drive | Disabled provider, local backup only | Do not claim cloud sync. |
| CloudKit / iCloud | Not connected | Do not claim Apple cloud sync. |
| WeatherKit | Mock / disabled / local guidance only | Do not claim live WeatherKit. |
| `.skatetrack` document association | Normal file export / NSOpenPanel selection only | Do not claim Finder open-with or custom UTType. |
| TestFlight / App Store | Blocked by Apple Developer Program | Do not claim upload readiness. |

## 7. GPS and safety gate

Task-027-preflight enabled background GPS recording; real-device background GPS validation remains required and simulator validation has passed with a moving route package. This is not enough for public release claims.

Required before any public release candidate:

- iPhone 13 Pro or equivalent real-device outdoor test.
- App starts a ride in foreground.
- Screen is turned off and phone is placed in a pocket.
- Movement continues for at least 150–300 meters and at least 3–5 minutes.
- Completed session shows non-zero distance, route points, speed metrics, and route preview.

Fall Detection remains a safety-sensitive feature. Do not use unsafe human impact testing. Task-030 keeps Fall Detection as a guarded local feature and records that a future safe diagnostics mode / controlled test protocol is required before stronger claims.

## 8. macOS viewer gate

The macOS app is a read-only `.skatetrack` package viewer.

Required layout rule:

- Left sidebar is function navigation only.
- Right side is the work area.
- Right top area is a compact package-session summary.
- Right lower area is the main dashboard.
- No full-height middle column with a single session card.

The viewer currently supports:

- NSOpenPanel selection of `.skatetrack` files.
- Package manifest preview.
- Read-only Session Viewer.
- Lightweight SwiftUI Path route preview.
- Lightweight SwiftUI Path speed chart.
- Route quality / empty-state handling.

The viewer does not support:

- Database import.
- Merge / restore.
- Package library.
- Finder open-with.
- Custom UTType / document association.
- MapKit map rendering.
- Road matching / heat maps.
- Swift Charts dashboards.
- Report export.

## 9. Task-030a pass condition

Task-030a passes only when:

- The Task-030a verify script passes.
- Localization, privacy, accessibility, package, backup, GPS, and shared-model verify scripts pass.
- iOS and macOS builds pass without new warnings.
- `KNOWN_LIMITATIONS_PRE_ADP.md`, `MANUAL_QA_MATRIX_PRE_ADP.md`, ADR-0011, and this document are aligned.
- No signing, custom UTType, document association, cloud entitlement, production credential, or local scheme-test-state drift is introduced.

Task-030a verification token: pre-ADP release readiness gate
Task-030b verification token: consolidated release readiness documentation..
