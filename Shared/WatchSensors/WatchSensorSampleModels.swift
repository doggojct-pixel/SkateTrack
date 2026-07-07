// [協作區] Shared/WatchSensors/WatchSensorSampleModels.swift

import Foundation

public enum WatchSensorSampleKind: String, Codable, Equatable, Sendable {
    case motion
    case altitude
    case speed
    case cadence
    case generic
}

public struct WatchSensorSample: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let kind: WatchSensorSampleKind
    public let timestamp: Date
    public let numericValue: Double
    public let unitSymbol: String
    public let providerKind: WatchSensorProviderKind
    public let confidence: Double

    public init(
        id: UUID = UUID(),
        kind: WatchSensorSampleKind,
        timestamp: Date,
        numericValue: Double,
        unitSymbol: String,
        providerKind: WatchSensorProviderKind,
        confidence: Double = 1.0
    ) {
        self.id = id
        self.kind = kind
        self.timestamp = timestamp
        self.numericValue = numericValue
        self.unitSymbol = unitSymbol
        self.providerKind = providerKind
        self.confidence = max(0.0, min(1.0, confidence))
    }
}

public struct WatchSensorProviderSnapshot: Codable, Equatable, Sendable {
    public let providerKind: WatchSensorProviderKind
    public let availability: WatchSensorProviderAvailability
    public let capturedAt: Date
    public let samples: [WatchSensorSample]

    public init(
        providerKind: WatchSensorProviderKind,
        availability: WatchSensorProviderAvailability,
        capturedAt: Date,
        samples: [WatchSensorSample] = []
    ) {
        self.providerKind = providerKind
        self.availability = availability
        self.capturedAt = capturedAt
        self.samples = samples
    }

    public var isUsable: Bool {
        availability.canProvideWatchOriginatedData
    }

    public var sampleCount: Int {
        samples.count
    }
}
