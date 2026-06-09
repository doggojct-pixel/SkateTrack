# Task-012 Prompt

Implement SkateTrack Task-012: Session Start Flow + Sport Mode Selection.

Create the iOS Session Start UI using the existing Task-011 session recording hook and Task-004 subscription hook. Show all eight modes. Free users can start all skateboard modes and Inline Urban / Freestyle. Inline Fitness / Speed, Inline Aggressive, and Inline Slalom must show locked subscriber states and must not start a session for free users.

Required files:
- iOS/App/RootNavigationView.swift
- iOS/Features/SessionRecording/SessionStartView.swift
- iOS/Features/SessionRecording/SportCategoryPickerView.swift
- iOS/Features/SessionRecording/BoardModeSelectorView.swift
- iOS/Features/SessionRecording/InlineModeSelectorView.swift
- iOS/Features/SessionRecording/PowerTypeToggleView.swift
- iOS/Features/SessionRecording/ModeSelectionCardView.swift
- iOS/Features/SessionRecording/StartSessionCTAView.swift

Rules:
- All user-facing text must be localized in English and Traditional Chinese.
- Every new Swift file must start with a `[協作區]` header.
- SwiftUI Views may use hooks but must not import CoreLocation or CoreMotion.
- Keep each file below 500 lines.
- Update FILE_STRUCTURE.md and DEV_LOG.md.
