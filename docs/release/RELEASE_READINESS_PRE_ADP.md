# SkateTrack Pre-ADP Release Readiness Report

**Status:** Task-030e macOS package-viewer manual QA gate sync
**Last Updated:** 2026-07-04
**Scope:** iOS, macOS, shared models, localization, local backup / package export, Task-030e macOS multi-package viewer, pre-Apple-Developer-Program service boundaries

This report is the Task-030b consolidated release-readiness source of truth. It does not claim App Store readiness, TestFlight readiness, production subscription readiness, Google Drive readiness, or production cloud readiness. It records what can be verified before Apple Developer Program enrollment and external production credentials are available.

## 0. Documentation source-of-truth gate

Before opening a new task, read the consolidated documentation in this order:

1. `docs/DOCUMENTATION_INDEX.md`
2. `docs/process/DEVELOPMENT_RULES.md`
3. `docs/release/KNOWN_LIMITATIONS_PRE_ADP.md`
4. `docs/release/RELEASE_READINESS_PRE_ADP.md`
5. `docs/release/MANUAL_QA_MATRIX_PRE_ADP.md`
6. `docs/adr/ADR-INDEX.md`

The old per-topic ADR single files and the previous Task 026–030 technical-risk notes were consolidated during Task-030b and must not reappear as active source-of-truth files. `docs/history/DEV_LOG.md` remains historical, not the daily rules source.

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

Run these before treating Task-030b as passing:

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
python3 scripts/verify_task030e_macos_multi_package_viewer.py
python3 scripts/verify_task030e_documentation_sync.py
python3 scripts/verify_task030e_manual_qa_gate.py
bash scripts/run_task030e_macos_multi_package_viewer_oneclick.sh
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

<!-- TASK040B_ARCHIVE_READINESS_START -->
## Task-040b Archive Readiness Checks

Task-040b prepares archive-readiness evidence without doing release work. It documents no-signing build gates and signing/capability boundaries only. No Apple Developer Program enrollment, no TestFlight release, no signing team change, no entitlement/capability change, no bundle identifier change, no production HealthKit capability, and no production StoreKit or Snow work is included.

Required no-signing build gates:

```bash
xcodebuild -project SkateTrack.xcodeproj -list -json
xcodebuild -project SkateTrack.xcodeproj -scheme SkateTrack-iOS -destination generic/platform=iOS -configuration Debug CODE_SIGNING_ALLOWED=NO -skipPackagePluginValidation -skipMacroValidation build
xcodebuild -project SkateTrack.xcodeproj -scheme SkateTrack-watchOS -destination generic/platform=watchOS -configuration Debug CODE_SIGNING_ALLOWED=NO -skipPackagePluginValidation -skipMacroValidation build
xcodebuild -project SkateTrack.xcodeproj -scheme SkateTrack-macOS -destination platform=macOS -configuration Debug CODE_SIGNING_ALLOWED=NO -skipPackagePluginValidation -skipMacroValidation build
```

Build settings documented for Task-040b:

- Existing app/test targets keep `CODE_SIGN_STYLE = Automatic`.
- Existing `DEVELOPMENT_TEAM` values remain empty.
- No `CODE_SIGN_ENTITLEMENTS` setting is present.
- No `.entitlements` file is present.
- No `SystemCapabilities`, `UTExportedTypeDeclarations`, `CFBundleDocumentTypes`, or `com.apple.developer.*` capability token is introduced.
- Existing bundle identifiers remain local development identifiers: `com.jjf.skatetrack`, `com.jjf.skatetrack.watchkitapp`, `com.jjf.skatetrack.mac`, and `com.jjf.skatetrack.tests`.

```text
VERIFY_TASK040B_ARCHIVE_READINESS_RESULT=PASSED
NO_SIGNING_BUILD_GATES=PASSED
SIGNING_CAPABILITY_CHANGE_COUNT=0
PRE_ADP_LIMITATIONS_DOCUMENTED=YES
BUILD_SETTINGS_DOCUMENTED=YES
No Apple Developer Program enrollment
No TestFlight release
No signing team change
No production HealthKit capability
FAILURE_COUNT=0
```
<!-- TASK040B_ARCHIVE_READINESS_END -->

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

The macOS app is a read-only `.skatetrack` package viewer. After Task-030e-MacViewer-013, the release-readiness documentation and manual QA gate describe the completed Task-030e chain through verifier / documentation sync / manual signoff while preserving remaining Pre-ADP limitations.

Required layout rule:

- Left sidebar is function navigation only.
- Right side is the work area.
- Right top area is a compact package-session summary.
- Right lower area is the main dashboard.
- No full-height middle column with a single session card.

The viewer currently supports:

- Browser-first package opening from Session Browser.
- Multi-file `.skatetrack` selection through `NSOpenPanel`.
- Independent package validation with partial-success reporting.
- In-memory multi-package package cards and batch summary.
- Selected package session list and selected session detail layout.
- Read-only MapKit route context using existing package route samples.
- iOS route visual parity for route-quality segment colors.
- Expanded route inspection in a resizable macOS window.
- Display-only speed chart, elevation profile, and total ascent display.
- Duplicate / attention warnings for duplicate file paths and duplicate session identifiers.
- Transient duplicate-file-path warning acknowledgement without delete / merge / winner selection.
- English, Traditional Chinese, and Japanese localization plus focused accessibility labels / hints / identifiers.
- Source-controlled consolidated verifier and one-click verification runner.
- Source-controlled manual QA gate checklist for Task-030e final-merge readiness.

The viewer does not support:

- Database import or local-history import.
- Merge / restore / winner selection.
- Package library persistence, recent-file persistence, or bookmarks.
- Drag-and-drop package opening.
- Finder open-with, custom UTType, or document association.
- Cloud sync or Google Drive sync.
- Road matching, snap-to-road, route reconstruction, route correction, or heat maps.
- Route geometry mutation, trusted metric mutation, package schema changes, or Core Data writes.
- Location permission prompts or user-location blue-dot display.
- Watch, WatchBridge, or Task-031 shared visualization pipeline work.

Task-030e verification commands before closing a Task-030e stage:

```bash
python3 scripts/verify_task030e_macos_multi_package_viewer.py
python3 scripts/verify_task030e_documentation_sync.py
python3 scripts/verify_task030e_manual_qa_gate.py
bash scripts/run_task030e_macos_multi_package_viewer_oneclick.sh
```

The one-click runner must package logs into a zip, delete its temporary run directory after zip creation, and record `ONECLICK_RUN_DIR_REMOVED=YES` in the postpack log.

Task-030e-MacViewer-013 manual QA closure additionally requires:

- `docs/release/TASK030E_MANUAL_QA_GATE.md` checklist coverage.
- 013 apply log and one-click zip uploaded for review.
- Explicit operator confirmation that manual QA passed.
- Confirmation that `ONECLICK_RUN_DIR_REMOVED=YES` is present after postpack cleanup.
- No UI behavior, package import, merge, duplicate deletion, route mutation, trusted metric mutation, schema change, Core Data write, location permission, user-location display, Watch / WatchBridge, or Task-031 change in the diff.


Task-030e macOS package-viewer documentation sync remains the 012 documentation baseline.

Task-030e-MacViewer-012 release-readiness token: macOS multi-package viewer gate, read-only `.skatetrack` review, documentation sync, one-click cleanup, no import / merge / route mutation.

Task-030e-MacViewer-013 release-readiness token: Manual QA Gate, TASK030E_MANUAL_QA_GATE.md, operator signoff required, task030e_013_oneclick, no UI / schema / route mutation.

## 9. Task-030a pass condition

Task-030a passes only when:

- The Task-030a verify script passes.
- Localization, privacy, accessibility, package, backup, GPS, and shared-model verify scripts pass.
- iOS and macOS builds pass without new warnings.
- `KNOWN_LIMITATIONS_PRE_ADP.md`, `MANUAL_QA_MATRIX_PRE_ADP.md`, ADR-0011, and this document are aligned.
- No signing, custom UTType, document association, cloud entitlement, production credential, or local scheme-test-state drift is introduced.

Task-030a verification token: pre-ADP release readiness gate
Task-030b verification token: consolidated release readiness documentation..


## Task-030e-MacViewer-014 final merge gate

Task-030e may be considered ready for merge back to `develop` only after `docs/release/TASK030E_FINAL_MERGE_GATE.md` and `scripts/verify_task030e_final_merge_gate.py` pass. The 014 gate requires `task030e_014_oneclick`, manual QA carry-forward from Task-030e-MacViewer-013, develop merge readiness, branch ancestry checks, clean working tree review, and final no-scope-expansion review.

The 014 final merge gate is a merge-readiness checklist and verifier only. It does not implement product behavior and must preserve no import / merge / route mutation, no package schema change, no Core Data write, no location permission, no user-location display, and no Task-031-prep implementation.

Task-030e-MacViewer-014 verification token: Task-030e-MacViewer-014 final merge gate, TASK030E_FINAL_MERGE_GATE.md, verify_task030e_final_merge_gate.py, develop merge readiness.
