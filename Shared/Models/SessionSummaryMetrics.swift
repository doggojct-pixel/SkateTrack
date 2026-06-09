// [協作區] Shared/Models/SessionSummaryMetrics.swift
// 用途：定義 Session 結束時的聚合指標，供 summary、history 與 export 使用。
// 委派至：SessionRecordingCoordinator、Task-015 persistence 與 Task-018 summary UI。

import Foundation

struct SessionSummaryMetrics: Codable, Sendable, Equatable {
    let distanceKilometers: Double
    let maxSpeedKilometersPerHour: Double
    let averageSpeedKilometersPerHour: Double
    let elevationGainMeters: Double
    let movingRatio: Double

    static let zero = SessionSummaryMetrics(
        distanceKilometers: 0,
        maxSpeedKilometersPerHour: 0,
        averageSpeedKilometersPerHour: 0,
        elevationGainMeters: 0,
        movingRatio: 0
    )
}

struct LiveSessionMetrics: Equatable, Sendable {
    let currentSpeedKilometersPerHour: Double
    let maxSpeedKilometersPerHour: Double
    let averageSpeedKilometersPerHour: Double
    let distanceKilometers: Double
    let elapsedTime: TimeInterval
    let currentTiltDegrees: Double
    let latestMotionSample: MotionSample?

    static let zero = LiveSessionMetrics(
        currentSpeedKilometersPerHour: 0,
        maxSpeedKilometersPerHour: 0,
        averageSpeedKilometersPerHour: 0,
        distanceKilometers: 0,
        elapsedTime: 0,
        currentTiltDegrees: 0,
        latestMotionSample: nil
    )
}
