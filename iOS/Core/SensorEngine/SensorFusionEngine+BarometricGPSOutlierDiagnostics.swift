// [自主區] iOS/Core/SensorEngine/SensorFusionEngine+BarometricGPSOutlierDiagnostics.swift
// 用途：隔離 b16-B barometric GPS outlier diagnostics wiring，避免擴大 SensorFusionEngine 主檔。
// 委派至：BarometricGPSOutlierGuard 與 LocationFixDiagnostics。

import CoreLocation
import Foundation

extension SensorFusionEngine {
    func makeBarometricGPSOutlierDecision(
        previousAnchor: BarometricGPSOutlierAnchor?,
        candidateLocation: CLLocation,
        candidateBarometerAltitudeMeters: Double?
    ) -> BarometricGPSOutlierDecision {
        BarometricGPSOutlierGuard.evaluate(
            previousAnchor: previousAnchor,
            candidateLocation: candidateLocation,
            candidateBarometerAltitudeMeters: candidateBarometerAltitudeMeters
        )
    }
}
