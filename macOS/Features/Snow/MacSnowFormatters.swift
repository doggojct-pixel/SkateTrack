// [協作區] MacSnowFormatters.swift
// 用途：提供 macOS Snow viewer 的唯讀顯示格式，不寫入 repository 或 package。
// 委派至：MacSnowDashboardView、MacSnowInspector 與 Distance Inspector。

import Foundation

enum MacSnowFormatters {
    static func distanceKilometers(_ meters: Double) -> String {
        String(format: "%.2f km", max(0, meters) / 1_000.0)
    }

    static func distanceMeters(_ meters: Double) -> String {
        if meters >= 1_000 {
            return distanceKilometers(meters)
        }
        return String(format: "%.0f m", max(0, meters))
    }

    static func speedKmh(fromMetersPerSecond speed: Double) -> String {
        String(format: "%.1f km/h", max(0, speed) * 3.6)
    }

    static func duration(_ duration: TimeInterval?) -> String {
        guard let duration else { return "—" }
        let totalSeconds = max(0, Int(duration.rounded()))
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        }
        if minutes > 0 {
            return String(format: "%dm %02ds", minutes, seconds)
        }
        return String(format: "%ds", seconds)
    }

    static func percent(_ value: Double) -> String {
        String(format: "%.0f%%", min(max(value, 0), 1) * 100)
    }

    static func altitude(_ value: Double?) -> String {
        guard let value else { return "—" }
        return String(format: "%.0f m", value)
    }

    static func signedAltitudeDelta(_ value: Double?) -> String {
        guard let value else { return "—" }
        return String(format: "%+.0f m", value)
    }

    static func dateTime(_ date: Date) -> String {
        dateTimeFormatter.string(from: date)
    }

    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
