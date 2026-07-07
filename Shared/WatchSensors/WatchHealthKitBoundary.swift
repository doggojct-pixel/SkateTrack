// [協作區] Shared/WatchSensors/WatchHealthKitBoundary.swift

import Foundation

public enum WatchHealthKitBoundaryState: String, Codable, Equatable, Sendable {
    case disabled
    case unavailable
}

public enum WatchHealthKitBoundaryReason: String, Codable, Equatable, Sendable {
    case notEnabledForThisBuild
    case platformCapabilityNotEnabled
    case productionAccessUnavailable
}

public struct WatchHealthKitBoundaryAvailability: Codable, Equatable, Sendable {
    public let state: WatchHealthKitBoundaryState
    public let reason: WatchHealthKitBoundaryReason
    public let checkedAt: Date
    public let explanation: String

    public init(
        state: WatchHealthKitBoundaryState,
        reason: WatchHealthKitBoundaryReason,
        checkedAt: Date,
        explanation: String
    ) {
        self.state = state
        self.reason = reason
        self.checkedAt = checkedAt
        self.explanation = explanation
    }

    public var canRequestProductionAccess: Bool {
        false
    }

    public static func disabled(
        at checkedAt: Date,
        explanation: String = WatchHealthKitCopy.disabledExplanation
    ) -> WatchHealthKitBoundaryAvailability {
        WatchHealthKitBoundaryAvailability(
            state: .disabled,
            reason: .notEnabledForThisBuild,
            checkedAt: checkedAt,
            explanation: explanation
        )
    }
}

public protocol WatchHealthKitBoundaryProviding: Sendable {
    var isProductionAccessEnabled: Bool { get }
    func boundaryAvailability(at date: Date) -> WatchHealthKitBoundaryAvailability
}
