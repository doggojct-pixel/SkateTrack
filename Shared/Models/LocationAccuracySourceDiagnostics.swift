// [協作區] Shared/Models/LocationAccuracySourceDiagnostics.swift
// 用途：定義被動定位精度來源診斷資料模型，供 CoreLocation accuracy-source 分析保存推論結果。
// 委派至：LocationAccuracySourceClassifier 與 LocationFixDiagnostics。

import Foundation

enum LocationAccuracySourceClass: String, Codable, Sendable, Equatable {
    case likelyHighPrecisionGPSOrWiFiRTT
    case possibleGoodGPSOrWiFiRTT
    case typicalGPS
    case degradedGPS
    case cellOrCachedPosition
    case unknown
}

struct LocationAccuracySourceDiagnostics: Codable, Sendable, Equatable {
    let sourceClass: LocationAccuracySourceClass
    let horizontalAccuracyMeters: Double?
    let verticalAccuracyMeters: Double?
    let freshnessState: LocationFreshnessState
    let routeSegmentConfidence: RouteSegmentConfidence
    let passiveInferenceOnly: Bool
    let explicitWiFiAPIUsed: Bool
    let wifiRTTConfirmed: Bool

    init(
        sourceClass: LocationAccuracySourceClass,
        horizontalAccuracyMeters: Double? = nil,
        verticalAccuracyMeters: Double? = nil,
        freshnessState: LocationFreshnessState = .unavailable,
        routeSegmentConfidence: RouteSegmentConfidence = .unavailable
    ) {
        self.sourceClass = sourceClass
        self.horizontalAccuracyMeters = horizontalAccuracyMeters.map { max(0, $0) }
        self.verticalAccuracyMeters = verticalAccuracyMeters.map { max(0, $0) }
        self.freshnessState = freshnessState
        self.routeSegmentConfidence = routeSegmentConfidence
        self.passiveInferenceOnly = true
        self.explicitWiFiAPIUsed = false
        self.wifiRTTConfirmed = false
    }

    private enum CodingKeys: String, CodingKey {
        case sourceClass
        case horizontalAccuracyMeters
        case verticalAccuracyMeters
        case freshnessState
        case routeSegmentConfidence
        case passiveInferenceOnly
        case explicitWiFiAPIUsed
        case wifiRTTConfirmed
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            sourceClass: try container.decodeIfPresent(LocationAccuracySourceClass.self, forKey: .sourceClass) ?? .unknown,
            horizontalAccuracyMeters: try container.decodeIfPresent(Double.self, forKey: .horizontalAccuracyMeters),
            verticalAccuracyMeters: try container.decodeIfPresent(Double.self, forKey: .verticalAccuracyMeters),
            freshnessState: try container.decodeIfPresent(LocationFreshnessState.self, forKey: .freshnessState) ?? .unavailable,
            routeSegmentConfidence: try container.decodeIfPresent(RouteSegmentConfidence.self, forKey: .routeSegmentConfidence) ?? .unavailable
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sourceClass, forKey: .sourceClass)
        try container.encodeIfPresent(horizontalAccuracyMeters, forKey: .horizontalAccuracyMeters)
        try container.encodeIfPresent(verticalAccuracyMeters, forKey: .verticalAccuracyMeters)
        try container.encode(freshnessState, forKey: .freshnessState)
        try container.encode(routeSegmentConfidence, forKey: .routeSegmentConfidence)
        try container.encode(true, forKey: .passiveInferenceOnly)
        try container.encode(false, forKey: .explicitWiFiAPIUsed)
        try container.encode(false, forKey: .wifiRTTConfirmed)
    }
}
