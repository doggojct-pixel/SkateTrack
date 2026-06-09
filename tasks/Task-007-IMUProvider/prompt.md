# Task-007 Agent Prompt

Implement the iOS IMU Provider according to Build Plan Task-007.

Constraints:
- Add `iOS/Core/SensorEngine/IMUProvider.swift` as `[自主區]`.
- Use `CMMotionManager`.
- Set both accelerometer and gyroscope intervals to 50Hz.
- Expose raw CoreMotion publishers for accelerometer and gyroscope.
- Provide graceful unavailable-device behavior without UI imports.
- Do not add product UI.
- Update living docs and add a local verification script.
