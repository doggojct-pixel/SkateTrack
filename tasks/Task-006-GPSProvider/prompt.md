# Task-006 Agent Prompt

Implement the SkateTrack iOS GPS Provider according to Build Plan v1.0 Task-006.

Constraints:
- Use Build Plan as the primary source of truth.
- Use DevProcess as coding standard guidance.
- Keep implementation files in the autonomous zone.
- Do not import SwiftUI or UIKit in GPS provider files.
- Keep Swift files under 300 lines for this task.
- Expose filtered `CLLocation` data through Combine.
- Convert speed from meters per second to kilometers per hour.
- Filter out low-accuracy locations where `horizontalAccuracy > 20`.
- Add localized permission strings in both `Localizable.strings` and `InfoPlist.strings`.
- Do not build Live HUD UI or route map UI in this task.
