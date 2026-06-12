// [協作區] MacSessionViewerModel.swift
// 用途：將 .skatetrack package session 轉成 macOS 只讀 Session Viewer 可顯示的 derived view model。
// 委派至：MacSessionBrowserView / MacSessionDetailView；不得寫入資料庫、merge、restore 或同步雲端。

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
    let routeSummary: MacRouteSummary
    let displayMetrics: SessionSummaryMetrics
    let usesDerivedMetrics: Bool

    init(packageSession: SkateTrackPackageSession) {
        let session = packageSession.session
        let samples = packageSession.effectiveMotionSamples
        let derived = MacSessionMetricsDeriver.deriveMetrics(
            session: session,
            samples: samples
        )
        let storedMetrics = session.summaryMetrics
        let displayMetrics = MacSessionViewerModel.preferredMetrics(
            stored: storedMetrics,
            derived: derived.metrics
        )

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
        routeSummary = derived.routeSummary
        self.displayMetrics = displayMetrics
        usesDerivedMetrics = MacSessionViewerModel.shouldUseDerivedMetrics(
            stored: storedMetrics,
            derived: derived.metrics
        )
    }

    var durationSeconds: TimeInterval? {
        endDate?.timeIntervalSince(startDate)
    }

    var hasRoute: Bool {
        routeSampleCount > 0
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

    private static func preferredMetrics(
        stored: SessionSummaryMetrics?,
        derived: SessionSummaryMetrics
    ) -> SessionSummaryMetrics {
        guard let stored else { return derived }
        if shouldUseDerivedMetrics(stored: stored, derived: derived) {
            return derived
        }
        return stored
    }

    private static func shouldUseDerivedMetrics(
        stored: SessionSummaryMetrics?,
        derived: SessionSummaryMetrics
    ) -> Bool {
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

struct MacRouteSummary: Equatable {
    let startCoordinate: GeoCoordinate?
    let finishCoordinate: GeoCoordinate?
    let routePointCount: Int
    let derivedDistanceKilometers: Double
}

private struct MacDerivedMetricsResult {
    let metrics: SessionSummaryMetrics
    let routeSummary: MacRouteSummary
}

private enum MacSessionMetricsDeriver {
    static func deriveMetrics(
        session: SessionData,
        samples: [MotionSample]
    ) -> MacDerivedMetricsResult {
        let sortedSamples = samples.sorted { $0.timestamp < $1.timestamp }
        let routeSamples = sortedSamples.compactMap { sample -> (timestamp: Date, coordinate: GeoCoordinate, speedKmh: Double)? in
            guard let coordinate = sample.gpsCoordinate else { return nil }
            return (sample.timestamp, coordinate, sample.speedKmh)
        }

        let distanceKilometers = deriveDistanceKilometers(from: routeSamples)
        let durationSeconds = max(0, session.durationSeconds ?? 0)
        let validSpeeds = sortedSamples.map(\.speedKmh).filter { $0.isFinite && $0 >= 0 }
        let maxSpeed = validSpeeds.max() ?? 0
        let averageSpeed = distanceKilometers > 0 && durationSeconds > 0
            ? distanceKilometers / (durationSeconds / 3600)
            : (validSpeeds.isEmpty ? 0 : validSpeeds.reduce(0, +) / Double(validSpeeds.count))
        let movingRatio = deriveMovingRatio(from: sortedSamples)
        let elevationGain = deriveElevationGainMeters(from: sortedSamples)
        let metrics = SessionSummaryMetrics(
            distanceKilometers: distanceKilometers,
            maxSpeedKilometersPerHour: maxSpeed,
            averageSpeedKilometersPerHour: averageSpeed,
            elevationGainMeters: elevationGain,
            movingRatio: movingRatio
        )
        let routeSummary = MacRouteSummary(
            startCoordinate: routeSamples.first?.coordinate,
            finishCoordinate: routeSamples.last?.coordinate,
            routePointCount: routeSamples.count,
            derivedDistanceKilometers: distanceKilometers
        )
        return MacDerivedMetricsResult(metrics: metrics, routeSummary: routeSummary)
    }

    static func speedPoints(from samples: [MotionSample]) -> [MacSpeedPoint] {
        let sortedSamples = samples.sorted { $0.timestamp < $1.timestamp }
        guard let firstDate = sortedSamples.first?.timestamp else { return [] }
        let points = sortedSamples.compactMap { sample -> MacSpeedPoint? in
            guard sample.speedKmh.isFinite, sample.speedKmh >= 0 else { return nil }
            return MacSpeedPoint(
                timestamp: sample.timestamp,
                elapsedSeconds: sample.timestamp.timeIntervalSince(firstDate),
                speedKmh: sample.speedKmh
            )
        }
        return downsample(points: points, maxCount: 160)
    }

    private static func deriveDistanceKilometers(
        from routeSamples: [(timestamp: Date, coordinate: GeoCoordinate, speedKmh: Double)]
    ) -> Double {
        guard let first = routeSamples.first else { return 0 }
        var anchor = first
        var distanceMeters = 0.0

        for sample in routeSamples.dropFirst() {
            let segmentMeters = distanceMetersBetween(anchor.coordinate, sample.coordinate)
            guard segmentMeters >= 3 else { continue }
            let elapsedSeconds = max(sample.timestamp.timeIntervalSince(anchor.timestamp), 0.1)
            let impliedSpeedKmh = (segmentMeters / elapsedSeconds) * 3.6
            guard segmentMeters <= 2_000, impliedSpeedKmh <= 150 else {
                anchor = sample
                continue
            }
            distanceMeters += segmentMeters
            anchor = sample
        }
        return distanceMeters / 1_000
    }

    private static func deriveMovingRatio(from samples: [MotionSample]) -> Double {
        guard samples.count > 1 else { return 0 }
        let movingCount = samples.filter { $0.speedKmh >= 1 }.count
        return min(1, max(0, Double(movingCount) / Double(samples.count)))
    }

    private static func deriveElevationGainMeters(from samples: [MotionSample]) -> Double {
        let altitudes = samples.compactMap(\.altitudeMeters)
        guard altitudes.count > 1 else { return 0 }
        var gain = 0.0
        var previous = altitudes[0]
        for altitude in altitudes.dropFirst() {
            let delta = altitude - previous
            if delta > 0 { gain += delta }
            previous = altitude
        }
        return gain
    }

    private static func distanceMetersBetween(_ first: GeoCoordinate, _ second: GeoCoordinate) -> Double {
        let earthRadiusMeters = 6_371_000.0
        let latitude1 = first.latitude * .pi / 180
        let latitude2 = second.latitude * .pi / 180
        let deltaLatitude = (second.latitude - first.latitude) * .pi / 180
        let deltaLongitude = (second.longitude - first.longitude) * .pi / 180
        let a = sin(deltaLatitude / 2) * sin(deltaLatitude / 2)
            + cos(latitude1) * cos(latitude2)
            * sin(deltaLongitude / 2) * sin(deltaLongitude / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthRadiusMeters * c
    }

    private static func downsample(points: [MacSpeedPoint], maxCount: Int) -> [MacSpeedPoint] {
        guard points.count > maxCount, maxCount > 0 else { return points }
        let stride = max(1, Int(ceil(Double(points.count) / Double(maxCount))))
        return points.enumerated().compactMap { index, point in
            index % stride == 0 || index == points.count - 1 ? point : nil
        }
    }
}

private extension SkateTrackPackageSession {
    var effectiveMotionSamples: [MotionSample] {
        motionSamples.isEmpty ? session.motionSamples : motionSamples
    }
}
