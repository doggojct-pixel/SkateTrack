// [協作區] Shared/WatchSensors/WatchHealthKitDisabledProvider.swift

import Foundation

public struct WatchHealthKitDisabledProvider: WatchHealthKitBoundaryProviding, WatchSensorProviding, Sendable {
    public let kind: WatchSensorProviderKind = .disabled
    public let isProductionAccessEnabled: Bool = false
    public let explanation: String

    public init(explanation: String = WatchHealthKitCopy.disabledExplanation) {
        self.explanation = explanation
    }

    public func boundaryAvailability(at date: Date) -> WatchHealthKitBoundaryAvailability {
        WatchHealthKitBoundaryAvailability.disabled(
            at: date,
            explanation: explanation
        )
    }

    public func availability(at date: Date) -> WatchSensorProviderAvailability {
        WatchSensorProviderAvailability.disabled(
            at: date,
            explanation: explanation
        )
    }

    public func snapshot(at date: Date, maximumSampleCount: Int) -> WatchSensorProviderSnapshot {
        WatchSensorProviderSnapshot(
            providerKind: kind,
            availability: availability(at: date),
            capturedAt: date,
            samples: []
        )
    }
}
