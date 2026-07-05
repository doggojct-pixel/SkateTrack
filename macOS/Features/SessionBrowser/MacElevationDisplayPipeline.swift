// [協作區] MacElevationDisplayPipeline.swift
// 用途：將 macOS read-only package viewer 的海拔顯示資料委派給 Shared ElevationDisplayPipeline，再轉成 macOS renderer 使用的 point adapter。
// 委派至：Task-031-prep-ActivityViz-011 macOS Elevation Profile Migration。
// Safety: display-only adapter; never writes derived elevation, ascent, metrics, or package data back to persistence/export/schema.

import Foundation

enum MacElevationDisplayPipeline {
    static func elevationResult(session: SessionData, samples: [MotionSample]) -> ElevationDisplayResult {
        let policy = ActivityFidelityPolicy(
            profile: session.fidelityProfile ?? ActivityFidelityProfile.defaultProfile(
                for: session.sportMode,
                powerType: session.powerType
            )
        )

        return ElevationDisplayPipeline(
            configuration: ElevationDisplayConfiguration(maximumDisplayPointCount: 180)
        ).makeDisplayElevation(
            samples: samples,
            startDate: session.startDate,
            fidelityPolicy: policy
        )
    }

    static func elevationPoints(session: SessionData, samples: [MotionSample]) -> [MacElevationPoint] {
        elevationPoints(from: elevationResult(session: session, samples: samples))
    }

    static func elevationPoints(from result: ElevationDisplayResult) -> [MacElevationPoint] {
        result.points.map { point in
            MacElevationPoint(
                id: point.id,
                timestamp: point.timestamp,
                elapsedSeconds: point.elapsedSeconds,
                elevationMeters: point.elevationMeters,
                segmentID: point.segmentID
            )
        }
    }

    static func displayDerivedTotalAscentMeters(
        from result: ElevationDisplayResult,
        fallback storedMeters: Double
    ) -> Double {
        guard let displayDerivedTotalAscentMeters = result.summary.displayDerivedTotalAscentMeters,
              displayDerivedTotalAscentMeters.isFinite
        else { return storedMeters }
        return displayDerivedTotalAscentMeters
    }
}
