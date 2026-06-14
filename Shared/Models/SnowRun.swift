// [協作區] Shared/Models/SnowRun.swift
// 用途：定義 Snow Mode 生產資料層的單趟滑行 run value type。
// 委派至：RunBoundaryDetector、SnowSessionRepository、Snow UI 與 package compatibility。

import Foundation

struct SnowRun: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    let sessionID: UUID
    let runNumber: Int
    let startDate: Date
    let endDate: Date?
    let skiDistanceMeters: Double
    let verticalDropMeters: Double
    let topSpeedMetersPerSecond: Double
    let averageSpeedMetersPerSecond: Double?
    let segmentIDs: [UUID]
    let isManualEnd: Bool

    init(
        id: UUID = UUID(),
        sessionID: UUID,
        runNumber: Int,
        startDate: Date,
        endDate: Date? = nil,
        skiDistanceMeters: Double = 0,
        verticalDropMeters: Double = 0,
        topSpeedMetersPerSecond: Double = 0,
        averageSpeedMetersPerSecond: Double? = nil,
        segmentIDs: [UUID] = [],
        isManualEnd: Bool = false
    ) {
        self.id = id
        self.sessionID = sessionID
        self.runNumber = max(1, runNumber)
        self.startDate = startDate
        self.endDate = endDate
        self.skiDistanceMeters = max(0, skiDistanceMeters)
        self.verticalDropMeters = max(0, verticalDropMeters)
        self.topSpeedMetersPerSecond = max(0, topSpeedMetersPerSecond)
        self.averageSpeedMetersPerSecond = averageSpeedMetersPerSecond.map { max(0, $0) }
        self.segmentIDs = segmentIDs
        self.isManualEnd = isManualEnd
    }

    var durationSeconds: TimeInterval? {
        guard let endDate else { return nil }
        return max(0, endDate.timeIntervalSince(startDate))
    }
}
