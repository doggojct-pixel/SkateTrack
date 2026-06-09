# Task-002 Prompt — Localization Infrastructure

You are implementing SkateTrack Task-002 according to Build Plan v1.0.

## Objective

Set up the full localization infrastructure so that Traditional Chinese is shown when the device or simulator locale is zh-TW / Traditional Chinese, and English is used otherwise.

## Required Files

Create:

- `Shared/Localization/en.lproj/Localizable.strings`
- `Shared/Localization/zh-Hant.lproj/Localizable.strings`
- `Shared/Utilities/UnitFormatter.swift`
- `Shared/Utilities/NumberFormatter+SkateTrack.swift`

Update:

- iOS, watchOS, and macOS app entry shells to use localization keys for the temporary placeholder text.
- `SkateTrack.xcodeproj/project.pbxproj` so both localization files are resources in all three targets, and both utility Swift files are sources in all three targets.
- `docs/FILE_STRUCTURE.md` and `docs/DEV_LOG.md`.

## Rules

- Follow DevProcess Principle A: no hardcoded user-visible strings outside localization files.
- Follow DevProcess Principle B: every new Swift file must declare its zone on line 1.
- Keep every Swift file below 500 lines.
- Do not add product features in this task.
- Do not start Task-003 data models.

## Validation

Run:

```bash
python3 scripts/verify_localization_keys.py
find Shared iOS watchOS macOS -name "*.swift" -print0 | xargs -0 wc -l | sort -rn | head -20
```

Then use Xcode simulators to verify:

- English locale shows `Ride. Track. Improve.`
- Traditional Chinese / Taiwan locale shows `滑行。記錄。進步。`
