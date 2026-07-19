// [Collaboration Zone] WatchSnowSessionSnapshot.swift
// Purpose: Production-safe Watch Snow data contract for Snow-Task-006a.
// Notes: Mirrors the Addendum watch data field contract without introducing prototype-only production naming. Future Snow-Task-006b
//        should map real watch transport snow payloads into this type.

import Foundation

struct WatchSnowSessionSnapshot: Codable, Equatable, Sendable {
    // Speed & run state.
    var currentSpeedKmh: Double
    var maxSpeedThisRunKmh: Double

    // Phase 1c snow fields; mirrors future watch transport snow payload.
    var snowRunNumber: Int?
    var snowVerticalDropMeters: Double?
    var snowTotalVerticalMeters: Double?
    var snowSlopeAngleDegrees: Double?
    var snowSegmentType: String?
    var snowSchemaVersion: String?

    // Session-level summary for WatchSnowSummaryView.
    var totalRunsToday: Int
    var totalSkiDistanceMeters: Double
    var totalLiftDistanceMeters: Double
    var averageRunDurationSeconds: Double?

    // Last completed run for WatchSnowWaitingCardView.
    var lastRunVerticalDropMeters: Double?
    var lastRunTopSpeedKmh: Double?
    var lastRunDurationSeconds: Double?

    // Optional Health / safety / entitlement-adjacent presentation fields.
    var heartRateBpm: Int?
    var fallAlertActive: Bool
    var fallAlertPeakGForce: Double?
    var isSubscriber: Bool

    static let empty = WatchSnowSessionSnapshot(
        currentSpeedKmh: 0,
        maxSpeedThisRunKmh: 0,
        snowRunNumber: nil,
        snowVerticalDropMeters: nil,
        snowTotalVerticalMeters: nil,
        snowSlopeAngleDegrees: nil,
        snowSegmentType: nil,
        snowSchemaVersion: "1.1",
        totalRunsToday: 0,
        totalSkiDistanceMeters: 0,
        totalLiftDistanceMeters: 0,
        averageRunDurationSeconds: nil,
        lastRunVerticalDropMeters: nil,
        lastRunTopSpeedKmh: nil,
        lastRunDurationSeconds: nil,
        heartRateBpm: nil,
        fallAlertActive: false,
        fallAlertPeakGForce: nil,
        isSubscriber: false
    )
}
