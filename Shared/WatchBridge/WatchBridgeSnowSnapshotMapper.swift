// [協作區] Shared/WatchBridge/WatchBridgeSnowSnapshotMapper.swift
// Purpose: Maps optional WatchBridge Snow metric extensions into the stable Watch Snow UI snapshot.
// Delegates to: WatchBridgeMetricUpdatePayload and WatchSnowSessionSnapshot contracts.

import Foundation

struct WatchBridgeSnowSnapshotMapper {
    func makeSnapshot(from payload: WatchBridgeMetricUpdatePayload?) -> WatchSnowSessionSnapshot {
        let currentSpeedKmh = nonnegative(payload?.currentSpeedMetersPerSecond).map { $0 * 3.6 } ?? 0
        guard let payload, payload.snowSchemaVersion != nil else {
            return WatchSnowSessionSnapshot(
                currentSpeedKmh: currentSpeedKmh,
                maxSpeedThisRunKmh: 0,
                snowRunNumber: nil,
                snowVerticalDropMeters: nil,
                snowTotalVerticalMeters: nil,
                snowSlopeAngleDegrees: nil,
                snowSegmentType: nil,
                snowSchemaVersion: nil,
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

        return WatchSnowSessionSnapshot(
            currentSpeedKmh: currentSpeedKmh,
            maxSpeedThisRunKmh: nonnegative(payload.snowMaxSpeedThisRunKmh) ?? 0,
            snowRunNumber: positive(payload.snowRunNumber),
            snowVerticalDropMeters: nonnegative(payload.snowVerticalDropMeters),
            snowTotalVerticalMeters: nonnegative(payload.snowTotalVerticalMeters),
            snowSlopeAngleDegrees: finite(payload.snowSlopeAngleDegrees),
            snowSegmentType: payload.snowSegmentType,
            snowSchemaVersion: payload.snowSchemaVersion,
            totalRunsToday: max(0, payload.snowRunCount ?? 0),
            totalSkiDistanceMeters: nonnegative(payload.snowTotalSkiDistanceMeters) ?? 0,
            totalLiftDistanceMeters: nonnegative(payload.snowTotalLiftDistanceMeters) ?? 0,
            averageRunDurationSeconds: nonnegative(payload.snowAverageRunDurationSeconds),
            lastRunVerticalDropMeters: nonnegative(payload.snowLastRunVerticalDropMeters),
            lastRunTopSpeedKmh: nonnegative(payload.snowLastRunTopSpeedKmh),
            lastRunDurationSeconds: nonnegative(payload.snowLastRunDurationSeconds),
            heartRateBpm: nil,
            fallAlertActive: false,
            fallAlertPeakGForce: nil,
            isSubscriber: false
        )
    }

    private func nonnegative(_ value: Double?) -> Double? {
        guard let value, value.isFinite, value >= 0 else { return nil }
        return value
    }

    private func finite(_ value: Double?) -> Double? {
        guard let value, value.isFinite else { return nil }
        return value
    }

    private func positive(_ value: Int?) -> Int? {
        guard let value, value > 0 else { return nil }
        return value
    }
}
