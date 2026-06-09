// [協作區] Shared/Models/TrickEvent.swift
// 用途：定義 session 時間軸上的招式、空中高度、信心分數與落地品質事件。
// 委派至：trick recognition、AI analysis、session summary 與 macOS review tools。

import Foundation

enum TrickType: String, Codable, Sendable, CaseIterable {
    case ollie
    case kickflip
    case heelflip
    case shoveIt
    case popShoveIt
    case manual
    case grind
    case grab
    case stall
    case pump
    case carve
    case unknown
}

struct TrickEvent: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    let timestamp: Date
    let sportMode: SportMode
    let trickType: TrickType
    let confidenceScore: Double
    let airHeightMeters: Double?
    let landingQualityScore: Double?

    init(
        id: UUID = UUID(),
        timestamp: Date,
        sportMode: SportMode,
        trickType: TrickType,
        confidenceScore: Double,
        airHeightMeters: Double? = nil,
        landingQualityScore: Double? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.sportMode = sportMode
        self.trickType = trickType
        self.confidenceScore = confidenceScore
        self.airHeightMeters = airHeightMeters
        self.landingQualityScore = landingQualityScore
    }
}
