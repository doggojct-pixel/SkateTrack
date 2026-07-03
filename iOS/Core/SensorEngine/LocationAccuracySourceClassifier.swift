// [自主區] iOS/Core/SensorEngine/LocationAccuracySourceClassifier.swift
// 用途：以 CoreLocation 已提供的 accuracy / freshness 訊號進行被動定位精度來源分類。
// 委派至：LocationFixDiagnostics；不得使用 Wi-Fi 掃描、Wi-Fi entitlement 或明示 RTT API。
// Safety token: passive CoreLocation accuracy-source diagnostics only.

import Foundation

enum LocationAccuracySourceClassifier {
    static func classify(
        horizontalAccuracyMeters: Double?,
        verticalAccuracyMeters: Double?,
        freshnessState: LocationFreshnessState,
        routeSegmentConfidence: RouteSegmentConfidence
    ) -> LocationAccuracySourceDiagnostics {
        let normalizedHorizontalAccuracyMeters = normalizedAccuracy(horizontalAccuracyMeters)
        let normalizedVerticalAccuracyMeters = normalizedAccuracy(verticalAccuracyMeters)
        return LocationAccuracySourceDiagnostics(
            sourceClass: sourceClass(
                horizontalAccuracyMeters: normalizedHorizontalAccuracyMeters,
                freshnessState: freshnessState
            ),
            horizontalAccuracyMeters: normalizedHorizontalAccuracyMeters,
            verticalAccuracyMeters: normalizedVerticalAccuracyMeters,
            freshnessState: freshnessState,
            routeSegmentConfidence: routeSegmentConfidence
        )
    }

    private static func sourceClass(
        horizontalAccuracyMeters: Double?,
        freshnessState: LocationFreshnessState
    ) -> LocationAccuracySourceClass {
        guard freshnessState != .unavailable else { return .unknown }
        guard freshnessState != .stale else { return .cellOrCachedPosition }
        guard let horizontalAccuracyMeters else { return .unknown }

        if horizontalAccuracyMeters < 3 { return .likelyHighPrecisionGPSOrWiFiRTT }
        if horizontalAccuracyMeters <= 8 { return .possibleGoodGPSOrWiFiRTT }
        if horizontalAccuracyMeters <= 20 { return .typicalGPS }
        if horizontalAccuracyMeters <= 50 { return .degradedGPS }
        return .cellOrCachedPosition
    }

    private static func normalizedAccuracy(_ value: Double?) -> Double? {
        guard let value, value.isFinite, value >= 0 else { return nil }
        return value
    }
}
