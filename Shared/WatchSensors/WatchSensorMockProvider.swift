// [協作區] Shared/WatchSensors/WatchSensorMockProvider.swift

import Foundation

public struct WatchSensorMockProvider: WatchSensorProviding, Sendable {
    public let kind: WatchSensorProviderKind = .mock
    public let scriptedAvailability: WatchSensorProviderAvailability
    private let scriptedSamples: [WatchSensorSample]

    public init(
        scriptedAvailability: WatchSensorProviderAvailability? = nil,
        scriptedSamples: [WatchSensorSample] = [],
        reportedAt: Date = Date(timeIntervalSince1970: 0)
    ) {
        self.scriptedAvailability = scriptedAvailability ?? .available(
            at: reportedAt,
            explanation: "mock watch sensor provider"
        )
        self.scriptedSamples = scriptedSamples.sorted { lhs, rhs in
            lhs.timestamp < rhs.timestamp
        }
    }

    public func availability(at date: Date) -> WatchSensorProviderAvailability {
        WatchSensorProviderAvailability(
            status: scriptedAvailability.status,
            reason: scriptedAvailability.reason,
            checkedAt: date,
            explanation: scriptedAvailability.explanation
        )
    }

    public func snapshot(at date: Date, maximumSampleCount: Int) -> WatchSensorProviderSnapshot {
        let safeLimit = max(0, maximumSampleCount)
        let limitedSamples = Array(scriptedSamples.suffix(safeLimit))
        let currentAvailability = availability(at: date)
        return WatchSensorProviderSnapshot(
            providerKind: kind,
            availability: currentAvailability,
            capturedAt: date,
            samples: currentAvailability.canProvideWatchOriginatedData ? limitedSamples : []
        )
    }
}
