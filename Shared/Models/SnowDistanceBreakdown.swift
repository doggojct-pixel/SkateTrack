// [協作區] Shared/Models/SnowDistanceBreakdown.swift
// 用途：定義 Snow Mode 的距離語意拆分，避免把 lift / gondola 路線誤算為滑行距離。
// 委派至：SnowSessionRepository、Snow UI、macOS viewer 與 package compatibility。

import Foundation

struct SnowDistanceBreakdown: Codable, Sendable, Equatable {
    let skiDistanceMeters: Double
    let liftDistanceMeters: Double
    let routeDistanceMeters: Double
    let unknownDistanceMeters: Double

    init(
        skiDistanceMeters: Double = 0,
        liftDistanceMeters: Double = 0,
        routeDistanceMeters: Double = 0,
        unknownDistanceMeters: Double = 0
    ) {
        self.skiDistanceMeters = max(0, skiDistanceMeters)
        self.liftDistanceMeters = max(0, liftDistanceMeters)
        self.routeDistanceMeters = max(0, routeDistanceMeters)
        self.unknownDistanceMeters = max(0, unknownDistanceMeters)
    }

    static let zero = SnowDistanceBreakdown()

    static func make(from segments: [SnowSegment]) -> SnowDistanceBreakdown {
        let skiDistance = segments.reduce(0) { $0 + $1.skiDistanceMeters }
        let liftDistance = segments.reduce(0) { $0 + $1.liftDistanceMeters }
        let routeDistance = segments.reduce(0) { $0 + $1.distanceMeters }
        let unknownDistance = segments.reduce(0) { $0 + $1.unknownDistanceMeters }
        return SnowDistanceBreakdown(
            skiDistanceMeters: skiDistance,
            liftDistanceMeters: liftDistance,
            routeDistanceMeters: routeDistance,
            unknownDistanceMeters: unknownDistance
        )
    }
}
