// [自主區] iOS/Core/SessionRecording/SessionRecordingCoordinator+DebugMock.swift
// 用途：集中 DEBUG-only demo speed sample feed，避免正常 App runtime 使用 mock speed。
// 委派至：Debug Tools Demo Speed Session、SwiftUI previews、Task-015 persistence tests。

import Foundation

#if DEBUG
extension SessionRecordingCoordinator {
    func startMockSampleFeed(for mode: SportMode) {
        stopMockSampleFeed()

        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .userInitiated))
        timer.schedule(deadline: .now() + 1, repeating: 1)
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            handleMotionSample(makeMockSample(for: mode))
        }
        mockSampleTimer = timer
        timer.resume()
    }

    func stopMockSampleFeed() {
        mockSampleTimer?.cancel()
        mockSampleTimer = nil
    }

    func makeMockSample(for _: SportMode) -> MotionSample {
        mockSampleIndex += 1
        let speedKmh = 12 + Double(mockSampleIndex % 5)
        let latitude = 25.033 + (Double(mockSampleIndex) * 0.00005)
        let longitude = 121.565 + (Double(mockSampleIndex) * 0.00005)

        return MotionSample(
            timestamp: Date(),
            gpsCoordinate: GeoCoordinate(latitude: latitude, longitude: longitude),
            speedKmh: speedKmh,
            accelerometerG: ThreeAxisValue(x: 0.05, y: 0.1, z: 0.98),
            gyroscopeRadPS: ThreeAxisValue(x: 0.02, y: 0.03, z: 0.01),
            altitudeMeters: 20 + Double(mockSampleIndex)
        )
    }

    static func makeMockCoordinator() -> SessionRecordingCoordinator {
        let coordinator = SessionRecordingCoordinator(
            sensorEngine: SensorFusionEngine(),
            fallDetectionEngine: FallDetectionEngine()
        )
        coordinator.setDataSource(.mock)
        return coordinator
    }
}
#else
extension SessionRecordingCoordinator {
    func stopMockSampleFeed() {}
}
#endif
