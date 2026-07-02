// [協作區 — 邊界適配層] useSessionSummary.swift
// 用途：向 SwiftUI Views 暴露單筆 Session Summary 載入狀態、核心指標與 Task-018a 摘要資料。
// 委派至：SessionRepositoryProtocol 讀取 Task-015 本機持久化資料，不讓 Views 直接碰 Core Data。
import Combine
import Foundation
struct SessionSummaryContent: Equatable, Sendable {
    let session: SessionData
    let motionSamples: [MotionSample]
    var metrics: SessionSummaryMetrics { SessionSummaryDisplayMetrics.make(session: session, samples: motionSamples) }
    var durationSeconds: TimeInterval? { session.durationSeconds }
    var fallCount: Int { session.fallEvents.count }
    var trickCount: Int { session.trickEvents.count }
    var hasRouteSamples: Bool { motionSamples.contains { $0.gpsCoordinate != nil } }
    var hasAltitudeSamples: Bool { motionSamples.contains { $0.altitudeMeters != nil } }
}
enum SessionSummaryDisplayMetrics {
    private static let movingSpeedThresholdKmh = 1.0
    private static let minimumSegmentDistanceKilometers = 0.003
    private static let maximumSegmentDistanceKilometers = 2.0
    private static let earthRadiusKilometers = 6_371.0
    private static let lowConfidenceDistanceActivationRatio = 0.03
    private static let conservativeMedianSpeedBlendWeight = 0.65
    private static let conservativeSpeedDistanceCapMultiplier = 1.30
    static func make(session: SessionData, samples: [MotionSample]) -> SessionSummaryMetrics {
        let persisted = session.summaryMetrics ?? .zero
        let sortedSamples = samples.sorted { $0.timestamp < $1.timestamp }
        guard !sortedSamples.isEmpty else { return persisted }
        let policy = ActivityFidelityPolicy(
            profile: session.fidelityProfile
                ?? ActivityFidelityProfile.defaultProfile(for: session.sportMode, powerType: session.powerType)
        )
        let distanceKilometers = displayDistanceKilometers(from: sortedSamples, policy: policy)
        let speedStats = displaySpeedStats(from: sortedSamples, policy: policy, session: session)
        let elevationGainMeters = displayElevationGainMeters(from: sortedSamples, policy: policy)
        return SessionSummaryMetrics(
            distanceKilometers: distanceKilometers > 0 ? distanceKilometers : persisted.distanceKilometers,
            maxSpeedKilometersPerHour: speedStats.maxSpeedKilometersPerHour > 0 ? speedStats.maxSpeedKilometersPerHour : persisted.maxSpeedKilometersPerHour,
            averageSpeedKilometersPerHour: speedStats.averageSpeedKilometersPerHour > 0 ? speedStats.averageSpeedKilometersPerHour : persisted.averageSpeedKilometersPerHour,
            elevationGainMeters: elevationGainMeters ?? persisted.elevationGainMeters,
            movingRatio: speedStats.movingRatio > 0 ? speedStats.movingRatio : persisted.movingRatio
        )
    }
    static func displaySpeedKilometersPerHour(for sample: MotionSample, policy: ActivityFidelityPolicy) -> Double? {
        let diagnostics = sample.locationDiagnostics
        let coreLocationSpeed = diagnostics?.headingDiagnostics?.coreLocationSpeedKmh
        let coordinateSpeed = diagnostics?.coordinateDerivedSpeedKmh
        let rawSpeed = sample.speedKmh.isFinite && sample.speedKmh > 0 ? sample.speedKmh : nil
        let candidate: Double?
        switch diagnostics?.speedSource {
        case .coreLocation:
            candidate = rawSpeed ?? coreLocationSpeed ?? coordinateSpeed
        case .coordinateDerived:
            candidate = coordinateSpeed ?? rawSpeed ?? coreLocationSpeed
        case .debugSimulated:
            candidate = rawSpeed
        case .stale, .unavailable, .none:
            candidate = rawSpeed ?? coreLocationSpeed ?? coordinateSpeed
        }

        guard let speedKmh = candidate, policy.acceptsSpeed(speedKmh) else { return nil }
        guard isSpeedDisplayEligible(sample, policy: policy, speedKmh: speedKmh) else { return nil }
        return speedKmh
    }

    private static func displaySpeedStats(
        from samples: [MotionSample],
        policy: ActivityFidelityPolicy,
        session: SessionData
    ) -> (maxSpeedKilometersPerHour: Double, averageSpeedKilometersPerHour: Double, movingRatio: Double) {
        var maxSpeed = 0.0
        var speedSum = 0.0
        var speedCount = 0
        var movingElapsed = 0.0
        var previousTimestamp: Date?

        for sample in samples {
            let speed = displaySpeedKilometersPerHour(for: sample, policy: policy)
            if let speed {
                maxSpeed = max(maxSpeed, speed)
                speedSum += speed
                speedCount += 1
            }

            if let previousTimestamp {
                let delta = max(sample.timestamp.timeIntervalSince(previousTimestamp), 0)
                if (speed ?? 0) >= movingSpeedThresholdKmh {
                    movingElapsed += delta
                }
            }
            previousTimestamp = sample.timestamp
        }

        let average = speedCount > 0 ? speedSum / Double(speedCount) : 0
        let duration = session.durationSeconds ?? samples.last.map { last in
            max(last.timestamp.timeIntervalSince(samples.first?.timestamp ?? last.timestamp), 0)
        } ?? 0
        let movingRatio = duration > 0 ? min(max(movingElapsed / duration, 0), 1) : 0
        return (maxSpeed, average, movingRatio)
    }

    private static func displayDistanceKilometers(from samples: [MotionSample], policy: ActivityFidelityPolicy) -> Double {
        let gpsDistance = gpsMetricDistanceKilometers(from: samples, policy: policy)
        let speedTimeDistance = speedIntegratedDistanceKilometers(from: samples, policy: policy)
        let conservativeSpeedDistance = conservativeSpeedDistanceKilometers(from: samples, policy: policy, speedTimeDistance: speedTimeDistance)
        let lowConfidenceRatio = lowConfidenceSampleRatio(in: samples)

        // Task-030c-b13-A-4: low-confidence route geometry is still displayed,
        // but any low-confidence coverage means raw GPS geometry is treated as
        // an upper bound only. Pocket / tree-canopy freebord can drift high,
        // while speed-time alone can undercount short downhill runs; the
        // conservative median-speed envelope is therefore used as the displayed
        // distance cap instead of accepting raw GPS whenever it is merely close.
        guard lowConfidenceRatio >= lowConfidenceDistanceActivationRatio else {
            return gpsDistance > 0 ? gpsDistance : 0
        }

        let speedBoundDistance = conservativeSpeedDistance > 0 ? conservativeSpeedDistance : speedTimeDistance
        guard speedBoundDistance > 0 else { return gpsDistance }
        guard gpsDistance > 0 else { return speedBoundDistance }

        return min(gpsDistance, speedBoundDistance)
    }

    private static func gpsMetricDistanceKilometers(from samples: [MotionSample], policy: ActivityFidelityPolicy) -> Double {
        var distance = 0.0
        var lastCoordinate: GeoCoordinate?
        var lastTimestamp: Date?

        for sample in samples {
            guard let coordinate = sample.gpsCoordinate,
                  coordinate.latitude.isFinite,
                  coordinate.longitude.isFinite else { continue }

            guard isMetricEligible(sample, policy: policy, speedKmh: displaySpeedKilometersPerHour(for: sample, policy: policy)) else {
                if shouldResetMetricAnchor(after: sample, policy: policy) {
                    lastCoordinate = nil
                    lastTimestamp = nil
                }
                continue
            }

            guard let previousCoordinate = lastCoordinate else {
                lastCoordinate = coordinate
                lastTimestamp = sample.timestamp
                continue
            }

            let segmentDistance = haversineDistanceKilometers(from: previousCoordinate, to: coordinate)
            guard segmentDistance >= minimumSegmentDistanceKilometers else { continue }
            guard segmentDistance <= maximumSegmentDistanceKilometers else { continue }

            if let lastTimestamp {
                let deltaSeconds = max(sample.timestamp.timeIntervalSince(lastTimestamp), 0.001)
                let impliedSpeed = (segmentDistance / deltaSeconds) * 3_600
                guard impliedSpeed <= policy.maximumTrustedImpliedSpeedKmh else { continue }
            }

            distance += segmentDistance
            lastCoordinate = coordinate
            lastTimestamp = sample.timestamp
        }

        return distance
    }

    private static func speedIntegratedDistanceKilometers(from samples: [MotionSample], policy: ActivityFidelityPolicy) -> Double {
        var distance = 0.0
        var previousTimestamp: Date?

        for sample in samples {
            defer { previousTimestamp = sample.timestamp }
            guard let previousTimestamp else { continue }
            let deltaSeconds = sample.timestamp.timeIntervalSince(previousTimestamp)
            guard deltaSeconds > 0, deltaSeconds <= 12 else { continue }
            guard let speedKmh = displaySpeedKilometersPerHour(for: sample, policy: policy),
                  speedKmh >= movingSpeedThresholdKmh else { continue }

            let cappedSpeed = min(speedKmh, distanceIntegrationSpeedCapKmh(for: policy))
            distance += (cappedSpeed * deltaSeconds) / 3_600
        }

        return distance
    }

    private static func conservativeSpeedDistanceKilometers(
        from samples: [MotionSample],
        policy: ActivityFidelityPolicy,
        speedTimeDistance: Double
    ) -> Double {
        let sortedSamples = samples.sorted { $0.timestamp < $1.timestamp }
        guard let firstTimestamp = sortedSamples.first?.timestamp,
              let lastTimestamp = sortedSamples.last?.timestamp else { return speedTimeDistance }

        let durationSeconds = max(lastTimestamp.timeIntervalSince(firstTimestamp), 0)
        guard durationSeconds > 0 else { return speedTimeDistance }

        let speeds = sortedSamples.compactMap { sample -> Double? in
            guard let speed = displaySpeedKilometersPerHour(for: sample, policy: policy),
                  speed >= movingSpeedThresholdKmh else { return nil }
            return min(speed, distanceIntegrationSpeedCapKmh(for: policy))
        }.sorted()
        guard let medianSpeed = median(speeds) else { return speedTimeDistance }

        let medianSpeedDistance = (medianSpeed * durationSeconds) / 3_600
        guard medianSpeedDistance > speedTimeDistance else { return speedTimeDistance }

        let blendedDistance = speedTimeDistance * (1 - conservativeMedianSpeedBlendWeight)
            + medianSpeedDistance * conservativeMedianSpeedBlendWeight
        return min(blendedDistance, speedTimeDistance * conservativeSpeedDistanceCapMultiplier)
    }

    private static func median(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values[values.count / 2]
    }

    private static func distanceIntegrationSpeedCapKmh(for policy: ActivityFidelityPolicy) -> Double {
        switch policy.profile {
        case .technicalSkateboard:
            return 10
        case .standardSkateboard, .inlineRecreation:
            return 12
        case .electricSkateboard:
            return 55
        case .inlineSpeed:
            return 70
        case .snowReserved:
            return 90
        case .vehicleValidation:
            return policy.chartMaximumSpeedKmh
        }
    }

    private static func lowConfidenceSampleRatio(in samples: [MotionSample]) -> Double {
        let diagnosticSamples = samples.compactMap(\.locationDiagnostics)
        guard !diagnosticSamples.isEmpty else { return 0 }
        let lowCount = diagnosticSamples.filter { $0.routeSegmentConfidence == .low }.count
        return Double(lowCount) / Double(diagnosticSamples.count)
    }

    private static func isSpeedDisplayEligible(
        _ sample: MotionSample,
        policy: ActivityFidelityPolicy,
        speedKmh: Double?
    ) -> Bool {
        if sample.sampleSource == .debugSimulated { return true }
        guard let diagnostics = sample.locationDiagnostics else { return true }
        guard diagnostics.freshnessState == .fresh || diagnostics.freshnessState == .recent else { return false }
        guard diagnostics.routeSegmentConfidence != .unavailable else { return false }
        guard let horizontalAccuracy = diagnostics.horizontalAccuracyMeters,
              horizontalAccuracy <= policy.maximumUsableHorizontalAccuracyMeters else { return false }
        if diagnostics.gpsUpdateIntervalSeconds.map({ $0 > max(12, policy.maximumTrustedUpdateIntervalSeconds * 1.5) }) == true { return false }
        if diagnostics.coordinateDerivedSpeedKmh.map({ $0 > policy.maximumTrustedImpliedSpeedKmh }) == true { return false }
        if let speedKmh, !policy.acceptsSpeed(speedKmh) { return false }
        return true
    }

    private static func isMetricEligible(
        _ sample: MotionSample,
        policy: ActivityFidelityPolicy,
        speedKmh: Double?
    ) -> Bool {
        if sample.sampleSource == .debugSimulated { return true }
        guard let diagnostics = sample.locationDiagnostics else { return true }
        guard diagnostics.freshnessState == .fresh || diagnostics.freshnessState == .recent else { return false }
        guard diagnostics.routeSegmentConfidence != .unavailable else { return false }
        guard let horizontalAccuracy = diagnostics.horizontalAccuracyMeters,
              horizontalAccuracy <= policy.maximumUsableHorizontalAccuracyMeters else { return false }
        if diagnostics.gpsUpdateIntervalSeconds.map({ $0 > max(12, policy.maximumTrustedUpdateIntervalSeconds * 1.5) }) == true { return false }
        if diagnostics.gpsSegmentDistanceMeters.map({ $0 > policy.maximumTrustedSegmentDistanceMeters }) == true { return false }
        if diagnostics.coordinateDerivedSpeedKmh.map({ $0 > policy.maximumTrustedImpliedSpeedKmh }) == true { return false }
        if let speedKmh, !policy.acceptsSpeed(speedKmh) { return false }
        return true
    }

    private static func shouldResetMetricAnchor(after sample: MotionSample, policy: ActivityFidelityPolicy) -> Bool {
        guard let diagnostics = sample.locationDiagnostics else { return false }
        if diagnostics.freshnessState == .stale || diagnostics.freshnessState == .unavailable { return true }
        if diagnostics.routeSegmentConfidence == .unavailable { return true }
        if diagnostics.horizontalAccuracyMeters.map({ $0 > policy.maximumUsableHorizontalAccuracyMeters }) == true { return true }
        if diagnostics.gpsUpdateIntervalSeconds.map({ $0 > max(12, policy.maximumTrustedUpdateIntervalSeconds * 1.5) }) == true { return true }
        return false
    }

    private static func displayElevationGainMeters(from samples: [MotionSample], policy: ActivityFidelityPolicy) -> Double? {
        // Task-030c-b15-B-3: Summary climb must use the same trusted altitude-source preference as the elevation chart.
        if samples.contains(where: { $0.altitudeDiagnostics != nil }) { return displayDiagnosticElevationGainMeters(from: samples, policy: policy) }
        if samples.contains(where: { $0.altitudeSource == .barometerRelative && $0.altitudeMeters?.isFinite == true }) {
            return displayLegacySourceElevationGainMeters(from: samples, preferredSources: [.barometerRelative], policy: policy)
        }
        guard samples.contains(where: { ($0.altitudeSource == .coreLocationAbsolute || $0.altitudeSource == .debugSimulated) && $0.altitudeMeters?.isFinite == true }) else { return nil }
        return displayLegacySourceElevationGainMeters(from: samples, preferredSources: [.coreLocationAbsolute, .debugSimulated], policy: policy)
    }

    private static func displayDiagnosticElevationGainMeters(from samples: [MotionSample], policy: ActivityFidelityPolicy) -> Double {
        let hasTrustedBarometer = samples.contains { sample in
            guard let d = sample.altitudeDiagnostics else { return false }
            return d.source == .barometerRelative && d.isTrustedForElevationGain && d.trustedAltitudeMeters?.isFinite == true
        }
        let preferredSources: Set<AltitudeSampleSource> = hasTrustedBarometer ? [.barometerRelative] : [.coreLocationAbsolute, .debugSimulated]
        let entries = samples.compactMap { sample -> (source: AltitudeSampleSource, altitude: Double, sample: MotionSample)? in
            guard let d = sample.altitudeDiagnostics, preferredSources.contains(d.source), d.isTrustedForElevationGain,
                  let altitude = d.trustedAltitudeMeters, altitude.isFinite else { return nil }
            return (d.source, altitude, sample)
        }
        return displayElevationGain(from: entries, policy: policy)
    }

    private static func displayLegacySourceElevationGainMeters(from samples: [MotionSample], preferredSources: Set<AltitudeSampleSource>, policy: ActivityFidelityPolicy) -> Double {
        let entries = samples.compactMap { sample -> (source: AltitudeSampleSource, altitude: Double, sample: MotionSample)? in
            guard let source = sample.altitudeSource, preferredSources.contains(source), let altitude = sample.altitudeMeters, altitude.isFinite else { return nil }
            return (source, altitude, sample)
        }
        return displayElevationGain(from: entries, firstTimestamp: samples.first?.timestamp, policy: policy)
    }

    private static func displayElevationGain(from entries: [(source: AltitudeSampleSource, altitude: Double, sample: MotionSample)], firstTimestamp: Date? = nil, policy: ActivityFidelityPolicy) -> Double {
        var lastAltitudeBySource: [AltitudeSampleSource: Double] = [:]
        var gain = 0.0
        for entry in entries {
            defer { lastAltitudeBySource[entry.source] = entry.altitude }
            guard let previous = lastAltitudeBySource[entry.source] else { continue }
            let delta = entry.altitude - previous
            switch entry.source {
            case .barometerRelative where delta > 0.03 && delta <= min(policy.maximumElevationStepMeters, 1.0): gain += delta
            case .coreLocationAbsolute:
                guard let firstTimestamp, entry.sample.timestamp.timeIntervalSince(firstTimestamp) > 30 else { continue }
                let strictVerticalAccuracy = min(policy.maximumVerticalAccuracyMeters, 5)
                if delta > 0 && delta <= min(policy.maximumElevationStepMeters, 1.0) && entry.sample.locationDiagnostics?.verticalAccuracyMeters.map({ $0 <= strictVerticalAccuracy }) == true { gain += delta }
            case .debugSimulated where delta > 0 && delta <= policy.maximumElevationStepMeters: gain += delta
            default: continue
            }
        }
        return gain
    }

    private static func haversineDistanceKilometers(from: GeoCoordinate, to: GeoCoordinate) -> Double {
        let deltaLatitude = (to.latitude - from.latitude) * (.pi / 180)
        let deltaLongitude = (to.longitude - from.longitude) * (.pi / 180)
        let startLatitude = from.latitude * (.pi / 180)
        let endLatitude = to.latitude * (.pi / 180)

        let haversine = sin(deltaLatitude / 2) * sin(deltaLatitude / 2)
            + cos(startLatitude) * cos(endLatitude) * sin(deltaLongitude / 2) * sin(deltaLongitude / 2)
        let centralAngle = 2 * atan2(sqrt(haversine), sqrt(1 - haversine))
        return earthRadiusKilometers * centralAngle
    }
}


enum SessionSummaryViewState: Equatable {
    case loading
    case content(SessionSummaryContent)
    case error(String)
}

@MainActor
final class SessionSummaryViewModel: ObservableObject {
    @Published private(set) var viewState: SessionSummaryViewState = .loading

    private let sessionID: UUID
    private let repository: SessionRepositoryProtocol
    private let initialSession: SessionData?
    private var hasLoaded = false

    init(
        sessionID: UUID,
        initialSession: SessionData? = nil,
        repository: SessionRepositoryProtocol = SessionRepository.shared
    ) {
        self.sessionID = sessionID
        self.initialSession = initialSession
        self.repository = repository

        if let initialSession {
            viewState = .content(
                SessionSummaryContent(
                    session: initialSession,
                    motionSamples: initialSession.motionSamples
                )
            )
        }
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await reload()
    }

    func reload() async {
        if initialSession == nil {
            viewState = .loading
        }

        do {
            let session = try await repository.fetchSession(id: sessionID)
            let samples = try await repository.loadMotionSamples(for: sessionID)
            let effectiveSamples = samples.isEmpty ? session.motionSamples : samples
            hasLoaded = true
            viewState = .content(SessionSummaryContent(session: session, motionSamples: effectiveSamples))
        } catch let error as RepositoryError {
            hasLoaded = true
            viewState = .error(error.localizationKey)
        } catch {
            hasLoaded = true
            viewState = .error("summary.error.generic")
        }
    }
}

@MainActor
func useSessionSummary(
    sessionID: UUID,
    initialSession: SessionData? = nil,
    repository: SessionRepositoryProtocol = SessionRepository.shared
) -> SessionSummaryViewModel {
    SessionSummaryViewModel(sessionID: sessionID, initialSession: initialSession, repository: repository)
}
