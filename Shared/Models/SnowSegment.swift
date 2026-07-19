// [協作區] Shared/Models/SnowSegment.swift
// 用途：定義 Snow Mode 生產資料層的單一 segment value type。
// 委派至：SnowSessionRepository、SnowSegmentClassifier、RunBoundaryDetector、Snow UI 與 package compatibility。

import Foundation

struct SnowSegment: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    let sessionID: UUID
    let runID: UUID?
    let type: SnowSegmentType
    let startDate: Date
    let endDate: Date?
    let distanceMeters: Double
    let verticalDeltaMeters: Double?
    let startAltitudeMeters: Double?
    let endAltitudeMeters: Double?
    let averageSpeedMetersPerSecond: Double?
    let maxSpeedMetersPerSecond: Double?
    let confidence: Double
    let countsTowardSkiDistance: Bool
    let manualOverride: Bool?
    let sourceSampleIDs: [UUID]

    init(
        id: UUID = UUID(),
        sessionID: UUID,
        runID: UUID? = nil,
        type: SnowSegmentType,
        startDate: Date,
        endDate: Date? = nil,
        distanceMeters: Double = 0,
        verticalDeltaMeters: Double? = nil,
        startAltitudeMeters: Double? = nil,
        endAltitudeMeters: Double? = nil,
        averageSpeedMetersPerSecond: Double? = nil,
        maxSpeedMetersPerSecond: Double? = nil,
        confidence: Double,
        countsTowardSkiDistance: Bool? = nil,
        manualOverride: Bool? = nil,
        sourceSampleIDs: [UUID] = []
    ) {
        self.id = id
        self.sessionID = sessionID
        self.runID = runID
        self.type = type
        self.startDate = startDate
        self.endDate = endDate
        self.distanceMeters = max(0, distanceMeters)
        self.verticalDeltaMeters = verticalDeltaMeters
        self.startAltitudeMeters = startAltitudeMeters
        self.endAltitudeMeters = endAltitudeMeters
        self.averageSpeedMetersPerSecond = averageSpeedMetersPerSecond
        self.maxSpeedMetersPerSecond = maxSpeedMetersPerSecond
        self.confidence = min(max(confidence, 0), 1)
        self.countsTowardSkiDistance = countsTowardSkiDistance ?? type.defaultCountsTowardSkiDistance
        self.manualOverride = manualOverride
        self.sourceSampleIDs = sourceSampleIDs
    }

    var durationSeconds: TimeInterval? {
        guard let endDate else { return nil }
        return max(0, endDate.timeIntervalSince(startDate))
    }

    var liftDistanceMeters: Double {
        type.countsTowardLiftDistance ? distanceMeters : 0
    }

    var skiDistanceMeters: Double {
        countsTowardSkiDistance ? distanceMeters : 0
    }

    var unknownDistanceMeters: Double {
        type == .unknown ? distanceMeters : 0
    }
}
