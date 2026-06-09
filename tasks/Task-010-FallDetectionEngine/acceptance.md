# Task-010 Acceptance Checklist

- [ ] Production impact threshold is 4g.
- [ ] Post-impact stationary confirmation is 3 seconds.
- [ ] DEBUG build includes a lower development threshold for simulator/testing.
- [ ] Engine publishes `FallEvent` with timestamp, peak G-force, coordinate, sport mode, and recovery duration.
- [ ] Engine starts a 15-second countdown after a fall event.
- [ ] `cancelFallAlert()` cancels the countdown.
- [ ] Countdown completion publishes an SOS trigger event instead of sending messages directly.
- [ ] No `SwiftUI`, `UIKit`, `AppKit`, or `WatchKit` imports.
- [ ] `FallDetectionEngine.swift` stays under 350 lines.
- [ ] `scripts/verify_fall_detection_engine.py` passes.
