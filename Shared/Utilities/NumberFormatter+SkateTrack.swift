// [協作區] NumberFormatter+SkateTrack.swift
// 用途：集中管理 SkateTrack 全域數字格式，避免在畫面或資料層硬編碼小數位規則。
// 原則：所有地區相關格式必須透過 Foundation formatter 與明確 Locale 處理。

import Foundation

extension NumberFormatter {
    static func skateTrackDecimal(
        locale: Locale = .autoupdatingCurrent,
        minimumFractionDigits: Int = 0,
        maximumFractionDigits: Int = 1
    ) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = minimumFractionDigits
        formatter.maximumFractionDigits = maximumFractionDigits
        return formatter
    }

    static func skateTrackInteger(locale: Locale = .autoupdatingCurrent) -> NumberFormatter {
        skateTrackDecimal(
            locale: locale,
            minimumFractionDigits: 0,
            maximumFractionDigits: 0
        )
    }

    static func skateTrackDistance(
        locale: Locale = .autoupdatingCurrent,
        maximumFractionDigits: Int = 2
    ) -> NumberFormatter {
        skateTrackDecimal(
            locale: locale,
            minimumFractionDigits: 0,
            maximumFractionDigits: maximumFractionDigits
        )
    }

    static func skateTrackTemperature(locale: Locale = .autoupdatingCurrent) -> NumberFormatter {
        skateTrackDecimal(
            locale: locale,
            minimumFractionDigits: 0,
            maximumFractionDigits: 1
        )
    }
}
