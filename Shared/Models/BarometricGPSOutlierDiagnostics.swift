// [協作區] Shared/Models/BarometricGPSOutlierDiagnostics.swift
// 用途：定義 GPS / barometer cross-validation 的 diagnostics-only 決策模型。
// 委派至：SensorFusionEngine barometric GPS outlier diagnostics、SessionData persistence 與後續 replay review。

import Foundation

enum BarometricGPSOutlierDiagnosticReason: String, Codable, Sendable, Equatable {
    case noPreviousGPSFix
    case horizontalJumpBelowThreshold
    case insufficientBarometricEvidence
    case gpsAltitudeUnavailable
    case barometricAltitudeConflict
    case noAltitudeConflict
}

struct BarometricGPSOutlierDiagnosticConfig: Codable, Sendable, Equatable {
    let minimumSuspiciousJumpMeters: Double
    let maxAltitudeDeltaDiscrepancyMeters: Double

    init(
        minimumSuspiciousJumpMeters: Double = 15,
        maxAltitudeDeltaDiscrepancyMeters: Double = 8
    ) {
        self.minimumSuspiciousJumpMeters = max(0, minimumSuspiciousJumpMeters)
        self.maxAltitudeDeltaDiscrepancyMeters = max(0, maxAltitudeDeltaDiscrepancyMeters)
    }

    static let diagnosticsOnly = BarometricGPSOutlierDiagnosticConfig()
}

struct BarometricGPSOutlierDecision: Codable, Sendable, Equatable {
    let productionRouteDecisionApplied: Bool
    let wouldRejectIfGateWereEnabled: Bool
    let diagnosticReason: BarometricGPSOutlierDiagnosticReason
    let previousFixTimestamp: Date?
    let previousFixTimestampMillisecondsSince1970: Int64?
    let candidateFixTimestamp: Date
    let candidateFixTimestampMillisecondsSince1970: Int64
    let candidateHorizontalJumpMeters: Double?
    let candidateGPSAltitudeDeltaMeters: Double?
    let barometerAltitudeDeltaMeters: Double?
    let discrepancyMeters: Double?
    let minimumSuspiciousJumpMeters: Double
    let maxAltitudeDeltaDiscrepancyMeters: Double

    init(
        wouldRejectIfGateWereEnabled: Bool,
        diagnosticReason: BarometricGPSOutlierDiagnosticReason,
        previousFixTimestamp: Date? = nil,
        previousFixTimestampMillisecondsSince1970: Int64? = nil,
        candidateFixTimestamp: Date,
        candidateFixTimestampMillisecondsSince1970: Int64,
        candidateHorizontalJumpMeters: Double? = nil,
        candidateGPSAltitudeDeltaMeters: Double? = nil,
        barometerAltitudeDeltaMeters: Double? = nil,
        discrepancyMeters: Double? = nil,
        minimumSuspiciousJumpMeters: Double,
        maxAltitudeDeltaDiscrepancyMeters: Double
    ) {
        // Task-030c-b16-B is diagnostics-only. Production route acceptance/rejection is not applied here.
        self.productionRouteDecisionApplied = false
        self.wouldRejectIfGateWereEnabled = wouldRejectIfGateWereEnabled
        self.diagnosticReason = diagnosticReason
        self.previousFixTimestamp = previousFixTimestamp
        self.previousFixTimestampMillisecondsSince1970 = previousFixTimestampMillisecondsSince1970
        self.candidateFixTimestamp = candidateFixTimestamp
        self.candidateFixTimestampMillisecondsSince1970 = candidateFixTimestampMillisecondsSince1970
        self.candidateHorizontalJumpMeters = candidateHorizontalJumpMeters.map { max(0, $0) }
        self.candidateGPSAltitudeDeltaMeters = candidateGPSAltitudeDeltaMeters.map { max(0, $0) }
        self.barometerAltitudeDeltaMeters = barometerAltitudeDeltaMeters.map { max(0, $0) }
        self.discrepancyMeters = discrepancyMeters.map { max(0, $0) }
        self.minimumSuspiciousJumpMeters = max(0, minimumSuspiciousJumpMeters)
        self.maxAltitudeDeltaDiscrepancyMeters = max(0, maxAltitudeDeltaDiscrepancyMeters)
    }

    private enum CodingKeys: String, CodingKey {
        case productionRouteDecisionApplied
        case wouldRejectIfGateWereEnabled
        case diagnosticReason
        case previousFixTimestamp
        case previousFixTimestampMillisecondsSince1970
        case candidateFixTimestamp
        case candidateFixTimestampMillisecondsSince1970
        case candidateHorizontalJumpMeters
        case candidateGPSAltitudeDeltaMeters
        case barometerAltitudeDeltaMeters
        case discrepancyMeters
        case minimumSuspiciousJumpMeters
        case maxAltitudeDeltaDiscrepancyMeters
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            wouldRejectIfGateWereEnabled: try container.decodeIfPresent(Bool.self, forKey: .wouldRejectIfGateWereEnabled) ?? false,
            diagnosticReason: try container.decodeIfPresent(BarometricGPSOutlierDiagnosticReason.self, forKey: .diagnosticReason) ?? .insufficientBarometricEvidence,
            previousFixTimestamp: try container.decodeIfPresent(Date.self, forKey: .previousFixTimestamp),
            previousFixTimestampMillisecondsSince1970: try container.decodeIfPresent(Int64.self, forKey: .previousFixTimestampMillisecondsSince1970),
            candidateFixTimestamp: try container.decode(Date.self, forKey: .candidateFixTimestamp),
            candidateFixTimestampMillisecondsSince1970: try container.decode(Int64.self, forKey: .candidateFixTimestampMillisecondsSince1970),
            candidateHorizontalJumpMeters: try container.decodeIfPresent(Double.self, forKey: .candidateHorizontalJumpMeters),
            candidateGPSAltitudeDeltaMeters: try container.decodeIfPresent(Double.self, forKey: .candidateGPSAltitudeDeltaMeters),
            barometerAltitudeDeltaMeters: try container.decodeIfPresent(Double.self, forKey: .barometerAltitudeDeltaMeters),
            discrepancyMeters: try container.decodeIfPresent(Double.self, forKey: .discrepancyMeters),
            minimumSuspiciousJumpMeters: try container.decodeIfPresent(Double.self, forKey: .minimumSuspiciousJumpMeters) ?? BarometricGPSOutlierDiagnosticConfig.diagnosticsOnly.minimumSuspiciousJumpMeters,
            maxAltitudeDeltaDiscrepancyMeters: try container.decodeIfPresent(Double.self, forKey: .maxAltitudeDeltaDiscrepancyMeters) ?? BarometricGPSOutlierDiagnosticConfig.diagnosticsOnly.maxAltitudeDeltaDiscrepancyMeters
        )
    }

}
