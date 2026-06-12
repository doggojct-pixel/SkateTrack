// [協作區] Shared/Models/SpotVisit.swift
// 用途：定義 Spot 與 Session 的本機關聯資料；Task-021a 先建立模型，Task-021b 再接 route detection。
// 委派至：SpotRepository、Session Summary link-to-spot 與未來 achievements statistics。

import Foundation

struct SpotVisit: Identifiable, Codable, Sendable, Equatable, Hashable {
    let id: UUID
    var spotID: UUID
    var sessionID: UUID
    var visitedAt: Date
    var distanceKilometers: Double
    var confidence: Double

    init(
        id: UUID = UUID(),
        spotID: UUID,
        sessionID: UUID,
        visitedAt: Date = Date(),
        distanceKilometers: Double = 0,
        confidence: Double = 0
    ) {
        self.id = id
        self.spotID = spotID
        self.sessionID = sessionID
        self.visitedAt = visitedAt
        self.distanceKilometers = max(0, distanceKilometers)
        self.confidence = max(0, min(confidence, 1))
    }
}
