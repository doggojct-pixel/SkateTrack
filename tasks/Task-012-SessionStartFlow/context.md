# Task-012 Context — Session Start Flow + Sport Mode Selection

Task-012 is the first visible iOS UI task after the Task-011 session lifecycle layer. It connects the user-facing start flow to `useSessionRecording` and `useSubscriptionStatus` without directly touching sensor engines.

Primary references:
- Build Plan Task 011-020 detailed pack: Task-012
- PRD v1.2: session recording, skateboard / inline mode coverage, subscription differentiation
- UI mockups: iOS Screen 01 Home / Dashboard, Screen 02 Board Mode Selector, Screen 12 Inline Mode Selector
- DevProcess v1.0: localization, collaboration/autonomous zoning, living docs

Important boundaries:
- Do not implement Live HUD in this task.
- Do not implement Paywall / StoreKit; locked modes use a stub upgrade prompt.
- Do not call CoreLocation / CoreMotion from Views.
- Start session only through `SessionRecordingActions.startSession`.
