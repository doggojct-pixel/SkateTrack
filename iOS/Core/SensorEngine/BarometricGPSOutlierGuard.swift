// [自主區] iOS/Core/SensorEngine/BarometricGPSOutlierGuard.swift
// 用途：以 barometer-relative altitude cross-validation 診斷可疑 GPS 跳點。
// 委派至：SensorFusionEngine+BarometricGPSOutlierDiagnostics.swift。

import CoreLocation
import Foundation

struct BarometricGPSOutlierAnchor {
    let location: CLLocation
    let barometerAltitudeMeters: Double?

    init(location: CLLocation, barometerAltitudeMeters: Double?) {
        self.location = location
        self.barometerAltitudeMeters = barometerAltitudeMeters
    }
}

enum BarometricGPSOutlierGuard {
    static func evaluate(
        previousAnchor: BarometricGPSOutlierAnchor?,
        candidateLocation: CLLocation,
        candidateBarometerAltitudeMeters: Double?,
        config: BarometricGPSOutlierDiagnosticConfig = .diagnosticsOnly
    ) -> BarometricGPSOutlierDecision {
        let candidateTimestamp = candidateLocation.timestamp
        let candidateTimestampMilliseconds = candidateTimestamp.b16bMillisecondsSince1970

        guard let previousAnchor else {
            return BarometricGPSOutlierDecision(
                wouldRejectIfGateWereEnabled: false,
                diagnosticReason: .noPreviousGPSFix,
                candidateFixTimestamp: candidateTimestamp,
                candidateFixTimestampMillisecondsSince1970: candidateTimestampMilliseconds,
                minimumSuspiciousJumpMeters: config.minimumSuspiciousJumpMeters,
                maxAltitudeDeltaDiscrepancyMeters: config.maxAltitudeDeltaDiscrepancyMeters
            )
        }

        let previousLocation = previousAnchor.location
        let horizontalJumpMeters = candidateLocation.distance(from: previousLocation)
        guard horizontalJumpMeters >= config.minimumSuspiciousJumpMeters else {
            return BarometricGPSOutlierDecision(
                wouldRejectIfGateWereEnabled: false,
                diagnosticReason: .horizontalJumpBelowThreshold,
                previousFixTimestamp: previousLocation.timestamp,
                previousFixTimestampMillisecondsSince1970: previousLocation.timestamp.b16bMillisecondsSince1970,
                candidateFixTimestamp: candidateTimestamp,
                candidateFixTimestampMillisecondsSince1970: candidateTimestampMilliseconds,
                candidateHorizontalJumpMeters: horizontalJumpMeters,
                minimumSuspiciousJumpMeters: config.minimumSuspiciousJumpMeters,
                maxAltitudeDeltaDiscrepancyMeters: config.maxAltitudeDeltaDiscrepancyMeters
            )
        }

        guard let previousBarometerAltitude = previousAnchor.barometerAltitudeMeters,
              let candidateBarometerAltitude = candidateBarometerAltitudeMeters,
              previousBarometerAltitude.isFinite,
              candidateBarometerAltitude.isFinite else {
            return BarometricGPSOutlierDecision(
                wouldRejectIfGateWereEnabled: false,
                diagnosticReason: .insufficientBarometricEvidence,
                previousFixTimestamp: previousLocation.timestamp,
                previousFixTimestampMillisecondsSince1970: previousLocation.timestamp.b16bMillisecondsSince1970,
                candidateFixTimestamp: candidateTimestamp,
                candidateFixTimestampMillisecondsSince1970: candidateTimestampMilliseconds,
                candidateHorizontalJumpMeters: horizontalJumpMeters,
                minimumSuspiciousJumpMeters: config.minimumSuspiciousJumpMeters,
                maxAltitudeDeltaDiscrepancyMeters: config.maxAltitudeDeltaDiscrepancyMeters
            )
        }

        guard let previousGPSAltitude = normalizedGPSAltitude(from: previousLocation),
              let candidateGPSAltitude = normalizedGPSAltitude(from: candidateLocation) else {
            return BarometricGPSOutlierDecision(
                wouldRejectIfGateWereEnabled: false,
                diagnosticReason: .gpsAltitudeUnavailable,
                previousFixTimestamp: previousLocation.timestamp,
                previousFixTimestampMillisecondsSince1970: previousLocation.timestamp.b16bMillisecondsSince1970,
                candidateFixTimestamp: candidateTimestamp,
                candidateFixTimestampMillisecondsSince1970: candidateTimestampMilliseconds,
                candidateHorizontalJumpMeters: horizontalJumpMeters,
                barometerAltitudeDeltaMeters: abs(candidateBarometerAltitude - previousBarometerAltitude),
                minimumSuspiciousJumpMeters: config.minimumSuspiciousJumpMeters,
                maxAltitudeDeltaDiscrepancyMeters: config.maxAltitudeDeltaDiscrepancyMeters
            )
        }

        let gpsAltitudeDeltaMeters = abs(candidateGPSAltitude - previousGPSAltitude)
        let barometerAltitudeDeltaMeters = abs(candidateBarometerAltitude - previousBarometerAltitude)
        let discrepancyMeters = abs(gpsAltitudeDeltaMeters - barometerAltitudeDeltaMeters)
        let wouldRejectIfEnabled = discrepancyMeters >= config.maxAltitudeDeltaDiscrepancyMeters
        let reason: BarometricGPSOutlierDiagnosticReason = wouldRejectIfEnabled
            ? .barometricAltitudeConflict
            : .noAltitudeConflict

        return BarometricGPSOutlierDecision(
            wouldRejectIfGateWereEnabled: wouldRejectIfEnabled,
            diagnosticReason: reason,
            previousFixTimestamp: previousLocation.timestamp,
            previousFixTimestampMillisecondsSince1970: previousLocation.timestamp.b16bMillisecondsSince1970,
            candidateFixTimestamp: candidateTimestamp,
            candidateFixTimestampMillisecondsSince1970: candidateTimestampMilliseconds,
            candidateHorizontalJumpMeters: horizontalJumpMeters,
            candidateGPSAltitudeDeltaMeters: gpsAltitudeDeltaMeters,
            barometerAltitudeDeltaMeters: barometerAltitudeDeltaMeters,
            discrepancyMeters: discrepancyMeters,
            minimumSuspiciousJumpMeters: config.minimumSuspiciousJumpMeters,
            maxAltitudeDeltaDiscrepancyMeters: config.maxAltitudeDeltaDiscrepancyMeters
        )
    }

    private static func normalizedGPSAltitude(from location: CLLocation) -> Double? {
        guard location.verticalAccuracy >= 0, location.altitude.isFinite else { return nil }
        return location.altitude
    }
}

private extension Date {
    var b16bMillisecondsSince1970: Int64 {
        Int64((timeIntervalSince1970 * 1000).rounded())
    }
}
