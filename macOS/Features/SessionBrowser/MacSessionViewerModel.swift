// [協作區] MacSessionViewerModel.swift
// 用途：將 .skatetrack package session 轉成 macOS 只讀 Session Viewer 可顯示的 derived view model。
// 委派至：MacSessionBrowserView / MacSessionDetailView / MacRoutePreviewView；不得寫入資料庫、merge、restore 或同步雲端。

import Foundation

struct MacSessionViewerModel: Identifiable, Equatable {
    let id: UUID
    let packageSession: SkateTrackPackageSession
    let title: String
    let subtitle: String
    let startDate: Date
    let endDate: Date?
    let exportedAt: Date
    let sportModeKey: String
    let powerTypeKey: String
    let motionSampleCount: Int
    let routeSampleCount: Int
    let privacyNotes: [String]
    let speedPoints: [MacSpeedPoint]
    let routePoints: [MacRoutePoint]
    let routeSummary: MacRouteSummary
    let displayMetrics: SessionSummaryMetrics
    let usesDerivedMetrics: Bool

    init(packageSession: SkateTrackPackageSession) {
        let session = packageSession.session
        let samples = packageSession.effectiveMotionSamples
        let derived = MacSessionMetricsDeriver.deriveMetrics(session: session, samples: samples)
        let storedMetrics = session.summaryMetrics
        let displayMetrics = MacSessionViewerModel.preferredMetrics(stored: storedMetrics, derived: derived.metrics)

        id = packageSession.id
        self.packageSession = packageSession
        title = MacSessionViewerModel.title(for: session)
        subtitle = MacSessionViewerModel.subtitle(for: session)
        startDate = session.startDate
        endDate = session.endDate
        exportedAt = packageSession.exportedAt
        sportModeKey = session.sportMode.modeLocalizationKey
        powerTypeKey = session.powerType.localizationKey
        motionSampleCount = samples.count
        routeSampleCount = samples.filter { $0.gpsCoordinate != nil }.count
        privacyNotes = packageSession.privacyNotes
        speedPoints = MacSessionMetricsDeriver.speedPoints(from: samples)
        routePoints = derived.routePoints
        routeSummary = derived.routeSummary
        self.displayMetrics = displayMetrics
        usesDerivedMetrics = MacSessionViewerModel.shouldUseDerivedMetrics(stored: storedMetrics, derived: derived.metrics)
    }

    var durationSeconds: TimeInterval? {
        endDate?.timeIntervalSince(startDate)
    }

    var hasRoute: Bool {
        routeSampleCount > 0
    }

    var hasDrawableRoute: Bool {
        routePoints.count >= 2 && routeSummary.quality != .unavailable
    }

    private static func title(for session: SessionData) -> String {
        if let displayName = session.spotSnapshot?.displayName, !displayName.isEmpty {
            return displayName
        }
        return String(localized: "mac.viewer.session.default_title")
    }

    private static func subtitle(for session: SessionData) -> String {
        if let equipmentName = session.equipmentSnapshot?.displayName, !equipmentName.isEmpty {
            return equipmentName
        }
        return String(localized: "mac.viewer.session.no_equipment")
    }

    private static func preferredMetrics(stored: SessionSummaryMetrics?, derived: SessionSummaryMetrics) -> SessionSummaryMetrics {
        guard let stored else { return derived }
        return shouldUseDerivedMetrics(stored: stored, derived: derived) ? derived : stored
    }

    private static func shouldUseDerivedMetrics(stored: SessionSummaryMetrics?, derived: SessionSummaryMetrics) -> Bool {
        guard let stored else { return true }
        let storedLooksEmpty = stored.distanceKilometers <= 0.0001
            && stored.maxSpeedKilometersPerHour <= 0.0001
            && stored.averageSpeedKilometersPerHour <= 0.0001
        let derivedHasUsefulData = derived.distanceKilometers > 0.0001
            || derived.maxSpeedKilometersPerHour > 0.0001
            || derived.averageSpeedKilometersPerHour > 0.0001
        return storedLooksEmpty && derivedHasUsefulData
    }
}

struct MacSpeedPoint: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    let elapsedSeconds: TimeInterval
    let speedKmh: Double
}

struct MacRoutePoint: Identifiable, Equatable {
    let id: Int
    let timestamp: Date
    let elapsedSeconds: TimeInterval
    let rawCoordinate: GeoCoordinate
    let displayCoordinate: GeoCoordinate
    let speedKmh: Double
    let confidence: RouteSegmentConfidence
    let horizontalAccuracyMeters: Double?
    let isStartupWarmup: Bool

    var segmentStyle: MacRouteSegmentStyle {
        if isStartupWarmup { return .startupWarmup }
        return confidence == .low || confidence == .unavailable ? .uncertain : .trusted
    }

    var isReliableAnchor: Bool {
        !isStartupWarmup && segmentStyle == .trusted
    }
}

struct MacRouteSummary: Equatable {
    let startCoordinate: GeoCoordinate?
    let finishCoordinate: GeoCoordinate?
    let routePointCount: Int
    let uniqueRoutePointCount: Int
    let derivedDistanceKilometers: Double
    let quality: MacRouteVisualizationQuality
    let hasStartupWarmup: Bool
}

enum MacRouteVisualizationQuality: Equatable {
    case unavailable
    case limited
    case usable
}

struct MacDerivedMetricsResult {
    let metrics: SessionSummaryMetrics
    let routeSummary: MacRouteSummary
    let routePoints: [MacRoutePoint]
}

private extension SkateTrackPackageSession {
    var effectiveMotionSamples: [MotionSample] {
        motionSamples.isEmpty ? session.motionSamples : motionSamples
    }
}
