// [協作區] Shared/WatchSensors/WatchSensorProviderProtocols.swift

import Foundation

public enum WatchSensorProviderKind: String, Codable, Equatable, Sendable {
    case disabled
    case mock
    case futureWatchSensor
}

public enum WatchSensorProviderAvailabilityStatus: String, Codable, Equatable, Sendable {
    case available
    case disabled
    case unavailable
}

public enum WatchSensorProviderUnavailableReason: String, Codable, Equatable, Sendable {
    case providerDisabled
    case platformUnsupported
    case permissionNotRequested
    case permissionDenied
    case sensorUnavailable
    case runtimeUnavailable
    case notConfigured
}

public struct WatchSensorProviderAvailability: Codable, Equatable, Sendable {
    public let status: WatchSensorProviderAvailabilityStatus
    public let reason: WatchSensorProviderUnavailableReason?
    public let checkedAt: Date
    public let explanation: String?

    public init(
        status: WatchSensorProviderAvailabilityStatus,
        reason: WatchSensorProviderUnavailableReason? = nil,
        checkedAt: Date,
        explanation: String? = nil
    ) {
        self.status = status
        self.reason = reason
        self.checkedAt = checkedAt
        self.explanation = explanation
    }

    public var canProvideWatchOriginatedData: Bool {
        status == .available
    }

    public static func available(
        at checkedAt: Date,
        explanation: String? = nil
    ) -> WatchSensorProviderAvailability {
        WatchSensorProviderAvailability(
            status: .available,
            checkedAt: checkedAt,
            explanation: explanation
        )
    }

    public static func disabled(
        at checkedAt: Date,
        explanation: String? = nil
    ) -> WatchSensorProviderAvailability {
        WatchSensorProviderAvailability(
            status: .disabled,
            reason: .providerDisabled,
            checkedAt: checkedAt,
            explanation: explanation
        )
    }

    public static func unavailable(
        reason: WatchSensorProviderUnavailableReason,
        at checkedAt: Date,
        explanation: String? = nil
    ) -> WatchSensorProviderAvailability {
        WatchSensorProviderAvailability(
            status: .unavailable,
            reason: reason,
            checkedAt: checkedAt,
            explanation: explanation
        )
    }
}

public protocol WatchSensorProviding: Sendable {
    var kind: WatchSensorProviderKind { get }
    func availability(at date: Date) -> WatchSensorProviderAvailability
    func snapshot(at date: Date, maximumSampleCount: Int) -> WatchSensorProviderSnapshot
}
