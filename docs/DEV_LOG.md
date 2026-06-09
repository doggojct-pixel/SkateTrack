# SkateTrack Development Log

This log is append-only. Do not delete or overwrite old entries.

## 2026-06-09 Phase 0 — Task-001 Project Scaffold Completed

### Completed
- Created the root Xcode workspace and Xcode project shell.
- Added iOS, watchOS, and macOS app entry points with empty SwiftUI shells.
- Created the DevProcess folder structure: `Shared/`, `iOS/`, `watchOS/`, `macOS/`, `Tests/`, `docs/`, and `tasks/`.
- Added `Shared/Constants/AppConstants.swift` for global deployment and naming constants.
- Added `.swiftlint.yml` with `file_length` warning at 450 lines and error at 500 lines.
- Added `README.md`, `.gitignore`, and this live documentation set.
- Initialized Git with an initial commit on `main` and created `develop` locally.

### Reason / Context
- Build Plan v1.0 defines Task-001 as the foundation for all later work.
- DevProcess v1.0 requires all files to follow the hybrid co-coding structure, 500-line limit, semantic naming, and live documentation protocol from the start.
- App entry points intentionally use `EmptyView()` so no feature or localization work leaks into Task-001.

### Known Issues / Follow-up
- GitHub remote still requires the real repository URL. Use `scripts/set_github_remote.sh` after creating the GitHub repository.
- SwiftLint SPM package is referenced in the Xcode project; Xcode may resolve packages on first open.
- Task-002 should add the actual localization resources and replace any future user-visible text with localization keys.

### 2026-06-09 — Task-001 hotfix

- Fixed malformed empty build setting in `SkateTrack.xcodeproj/project.pbxproj`.
- Changed `SWIFT_ACTIVE_COMPILATION_CONDITIONS = ;` to `SWIFT_ACTIVE_COMPILATION_CONDITIONS = "";` so Xcode can parse the project file.
- No product feature scope was added; this remains Task-001 scaffold only.

## 2026-06-09 Phase 0 — Task-002 Localization Infrastructure Completed

### Completed
- Added `Shared/Localization/en.lproj/Localizable.strings` as the English base localization file.
- Added `Shared/Localization/zh-Hant.lproj/Localizable.strings` as the Traditional Chinese localization file.
- Added matching key sets for app general strings, sport modes, subscription labels, and unit formatting support keys.
- Added `Shared/Utilities/UnitFormatter.swift` to centralize distance, temperature, and pace formatting.
- Added `Shared/Utilities/NumberFormatter+SkateTrack.swift` to centralize number formatting presets.
- Updated iOS, watchOS, and macOS app entry shells to display `app.name` and `app.tagline` through SwiftUI localization keys.
- Updated the Xcode project so localization resources and shared utility files are included in all three targets.
- Added `scripts/verify_localization_keys.py` for local localization key parity checks.
- Added the Task-002 prompt pack under `tasks/Task-002-Localization/`.
- Updated `docs/FILE_STRUCTURE.md` for the new localization, utilities, script, and task files.

### Reason / Context
- Build Plan v1.0 defines Task-002 as the localization infrastructure task.
- DevProcess v1.0 Principle A requires all user-visible strings, units, and locale-specific values to pass through the localization and formatter layers.
- The localized placeholder shells exist only to verify Task-002 in the simulator; product features still begin in later tasks.

### Validation Notes
- Localization keys were checked with `python3 scripts/verify_localization_keys.py`.
- Swift source file line counts remain below the 500-line hard limit.
- Xcode simulator validation should focus on verifying the tagline changes between English and Traditional Chinese.

### Known Issues / Follow-up
- This task does not add real product screens, GPS, session recording, or data models.
- Task-003 should add shared data models without hardcoded user-visible strings.
