# Task-008 Agent Prompt

Implement the iOS Barometer Provider according to Build Plan Task-008.

Constraints:
- Add `iOS/Core/SensorEngine/BarometerProvider.swift` as `[自主區]`.
- Use `CMAltimeter`.
- Expose raw `CMAltitudeData` publisher and normalized relative-altitude values.
- Guard with `CMAltimeter.isRelativeAltitudeAvailable()`.
- Do not crash on unsupported devices / simulators.
- Do not add product UI.
- Update living docs and add a local verification script.
