// [協作區] Shared/WatchSensors/WatchSensorDisabledProvider.swift

import Foundation

public struct WatchSensorDisabledProvider: WatchSensorProviding, Sendable {
    public let kind: WatchSensorProviderKind = .disabled
    public let explanation: String

    public init(explanation: String = "watch sensor provider is disabled") {
        self.explanation = explanation
    }

    public func availability(at date: Date) -> WatchSensorProviderAvailability {
        WatchSensorProviderAvailability(
            status: .disabled,
            reason: .providerDisabled,
            checkedAt: date,
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
