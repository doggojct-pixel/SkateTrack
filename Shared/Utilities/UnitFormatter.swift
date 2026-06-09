// [協作區] UnitFormatter.swift
// 用途：集中處理距離、溫度與配速的地區化顯示，避免 UI 或 feature 檔案硬編碼單位字串。
// 原則：所有使用者可見單位都必須透過 Foundation formatter 或 Localizable.strings 取得。

import Foundation

enum SkateTrackDistanceUnit: String, CaseIterable, Sendable {
    case kilometers
    case miles

    var foundationUnit: UnitLength {
        switch self {
        case .kilometers:
            return .kilometers
        case .miles:
            return .miles
        }
    }

    var paceDistanceInMeters: Double {
        switch self {
        case .kilometers:
            return 1_000
        case .miles:
            return 1_609.344
        }
    }

    var shortLocalizationKey: String {
        switch self {
        case .kilometers:
            return "unit.length.kilometer.short"
        case .miles:
            return "unit.length.mile.short"
        }
    }
}

enum SkateTrackTemperatureUnit: String, CaseIterable, Sendable {
    case celsius
    case fahrenheit

    var foundationUnit: UnitTemperature {
        switch self {
        case .celsius:
            return .celsius
        case .fahrenheit:
            return .fahrenheit
        }
    }
}

enum UnitFormatter {
    static func distance(
        meters: Double,
        unit: SkateTrackDistanceUnit = .kilometers,
        locale: Locale = .autoupdatingCurrent,
        maximumFractionDigits: Int = 2
    ) -> String {
        guard meters.isFinite else {
            return localizedString(forKey: "general.value.unavailable")
        }

        let measurement = Measurement(value: meters, unit: UnitLength.meters)
            .converted(to: unit.foundationUnit)
        let formatter = measurementFormatter(
            locale: locale,
            numberFormatter: .skateTrackDistance(
                locale: locale,
                maximumFractionDigits: maximumFractionDigits
            )
        )
        return formatter.string(from: measurement)
    }

    static func temperature(
        celsius: Double,
        unit: SkateTrackTemperatureUnit = .celsius,
        locale: Locale = .autoupdatingCurrent
    ) -> String {
        guard celsius.isFinite else {
            return localizedString(forKey: "general.value.unavailable")
        }

        let measurement = Measurement(value: celsius, unit: UnitTemperature.celsius)
            .converted(to: unit.foundationUnit)
        let formatter = measurementFormatter(
            locale: locale,
            numberFormatter: .skateTrackTemperature(locale: locale)
        )
        return formatter.string(from: measurement)
    }

    static func pace(
        seconds: TimeInterval,
        meters: Double,
        distanceUnit: SkateTrackDistanceUnit = .kilometers,
        locale: Locale = .autoupdatingCurrent
    ) -> String {
        guard seconds.isFinite, meters.isFinite, seconds >= 0, meters > 0 else {
            return localizedString(forKey: "general.value.unavailable")
        }

        return pace(
            secondsPerMeter: seconds / meters,
            distanceUnit: distanceUnit,
            locale: locale
        )
    }

    static func pace(
        secondsPerMeter: Double,
        distanceUnit: SkateTrackDistanceUnit = .kilometers,
        locale: Locale = .autoupdatingCurrent
    ) -> String {
        guard secondsPerMeter.isFinite, secondsPerMeter >= 0 else {
            return localizedString(forKey: "general.value.unavailable")
        }

        let totalSeconds = secondsPerMeter * distanceUnit.paceDistanceInMeters
        let duration = paceDurationFormatter.string(from: totalSeconds)
            ?? localizedString(forKey: "general.value.unavailable")
        let unitLabel = localizedString(forKey: distanceUnit.shortLocalizationKey)
        let format = localizedString(forKey: "unit.pace.format")
        return String(format: format, locale: locale, duration, unitLabel)
    }
}

private extension UnitFormatter {
    static var paceDurationFormatter: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }

    static func measurementFormatter(
        locale: Locale,
        numberFormatter: NumberFormatter
    ) -> MeasurementFormatter {
        let formatter = MeasurementFormatter()
        formatter.locale = locale
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter = numberFormatter
        return formatter
    }

    static func localizedString(forKey key: String) -> String {
        NSLocalizedString(key, comment: "")
    }
}
