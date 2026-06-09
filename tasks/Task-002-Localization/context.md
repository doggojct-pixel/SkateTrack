# Task-002 Context — Localization Infrastructure

## Source Priority

1. Build Plan v1.0 is the primary task source.
2. DevProcess v1.0 is the secondary engineering rule source.
3. PRD v1.2 and UI prototypes define product direction but do not expand Task-002 beyond localization infrastructure.

## Build Plan Reference

Task-002: Localization Infrastructure

Objective: Set up the full localization system so that Traditional Chinese is shown when system locale is zh-TW, and English otherwise. All subsequent tasks add keys here simultaneously.

## DevProcess Reference

Principle A — Soft-Coding & Multilingual Architecture

- No user-visible string, label, unit, or locale-specific value may appear as a literal outside localization files.
- All user-facing strings are stored in `Shared/Localization/en.lproj/Localizable.strings` and `Shared/Localization/zh-Hant.lproj/Localizable.strings`.
- Unit display is handled by `Shared/Utilities/UnitFormatter.swift`.
- Numeric formatting is handled by `NumberFormatter` presets.
- All new localization keys must be added to both language files simultaneously.

## UI Scope

Task-002 applies to all future UI screens, but it does not implement real iOS, watchOS, or macOS product screens yet. The app entry shells display only localized placeholder text so language switching can be verified in a simulator.
