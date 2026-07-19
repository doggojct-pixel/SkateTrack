// [Collaboration Zone] WatchSnowFormatters.swift
// Purpose: Lightweight watchOS Snow formatting helpers for WatchSnowSessionSnapshot.

import Foundation

extension WatchSnowSessionSnapshot {
    var watchSpeedText: String {
        String(format: "%.1f", currentSpeedKmh)
    }

    var watchMaxSpeedText: String {
        String(format: "%.1f", maxSpeedThisRunKmh)
    }

    var watchSkiDistanceText: String {
        String(format: "%.1f", totalSkiDistanceMeters / 1_000)
    }

    var watchLiftDistanceText: String {
        String(format: "%.1f", totalLiftDistanceMeters / 1_000)
    }

    var watchRunNumberText: String {
        guard let snowRunNumber else { return "--" }
        return String(format: "%02d", snowRunNumber)
    }

    var watchCurrentVerticalText: String {
        guard let snowVerticalDropMeters else { return "--" }
        return "\(Int(snowVerticalDropMeters))m"
    }

    var watchTotalVerticalText: String {
        guard let snowTotalVerticalMeters else { return "--" }
        return "\(Int(snowTotalVerticalMeters))m"
    }

    var watchLastRunVerticalText: String {
        guard let lastRunVerticalDropMeters else { return "--" }
        return "\(Int(lastRunVerticalDropMeters))m"
    }

    var watchLastRunTopSpeedText: String {
        guard let lastRunTopSpeedKmh else { return "--" }
        return String(format: "%.1f", lastRunTopSpeedKmh)
    }

    var watchSlopeAngleText: String {
        guard let snowSlopeAngleDegrees else { return "--" }
        return "\(Int(snowSlopeAngleDegrees))°"
    }
}
