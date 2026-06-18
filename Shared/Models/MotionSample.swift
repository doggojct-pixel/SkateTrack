// [協作區] Shared/Models/MotionSample.swift
// 用途：定義 GPS、速度、加速度、陀螺儀、高度與定位品質診斷的單筆跨平台感測樣本。
// 委派至：SensorProvider、session recording、fall detection 與後續分析引擎。

import Foundation

struct GeoCoordinate: Codable, Sendable, Equatable {
    let latitude: Double
    let longitude: Double

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

struct ThreeAxisValue: Codable, Sendable, Equatable {
    let x: Double
    let y: Double
    let z: Double

    init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
}

enum LocationSpeedSource: String, Codable, Sendable, Equatable {
    case coreLocation
    case coordinateDerived
    case debugSimulated
    case stale
    case unavailable
}

enum LocationFreshnessState: String, Codable, Sendable, Equatable {
    case fresh
    case recent
    case stale
    case unavailable
}

enum RouteSegmentConfidence: String, Codable, Sendable, Equatable {
    case high
    case medium
    case low
    case unavailable
}

enum HeadingDiagnosticsSource: String, Codable, Sendable, Equatable {
    case coreLocationCourse
    case unavailable
}

struct HeadingDiagnostics: Codable, Sendable, Equatable {
    let source: HeadingDiagnosticsSource
    let headingAvailable: Bool
    let courseOverGroundDegrees: Double?
    let courseAccuracyDegrees: Double?
    let coreLocationSpeedKmh: Double?
    let courseReliableForRouteContinuity: Bool
    let deviceHeadingDeferred: Bool

    init(
        source: HeadingDiagnosticsSource = .unavailable,
        headingAvailable: Bool = false,
        courseOverGroundDegrees: Double? = nil,
        courseAccuracyDegrees: Double? = nil,
        coreLocationSpeedKmh: Double? = nil,
        courseReliableForRouteContinuity: Bool = false,
        deviceHeadingDeferred: Bool = true
    ) {
        self.source = source
        self.headingAvailable = headingAvailable
        self.courseOverGroundDegrees = courseOverGroundDegrees
        self.courseAccuracyDegrees = courseAccuracyDegrees
        self.coreLocationSpeedKmh = coreLocationSpeedKmh
        self.courseReliableForRouteContinuity = courseReliableForRouteContinuity
        self.deviceHeadingDeferred = deviceHeadingDeferred
    }
}

enum GPSGapClassification: String, Codable, Sendable, Equatable {
    case normalCadence
    case shortGap
    case backgroundLocationGap
    case extendedSignalLoss
}

struct GPSGapDiagnostics: Codable, Sendable, Equatable {
    static let shortGapThresholdSeconds: TimeInterval = 1.5
    static let backgroundGapThresholdSeconds: TimeInterval = 5
    static let extendedSignalLossThresholdSeconds: TimeInterval = 30

    let classification: GPSGapClassification
    let gapSeconds: TimeInterval?
    let isTimerFusionRepeat: Bool
    let rawLocationAvailable: Bool

    init(
        classification: GPSGapClassification,
        gapSeconds: TimeInterval? = nil,
        isTimerFusionRepeat: Bool = false,
        rawLocationAvailable: Bool = true
    ) {
        self.classification = classification
        self.gapSeconds = gapSeconds.map { max(0, $0) }
        self.isTimerFusionRepeat = isTimerFusionRepeat
        self.rawLocationAvailable = rawLocationAvailable
    }

    static func classification(for gapSeconds: TimeInterval?) -> GPSGapClassification? {
        guard let gapSeconds else { return nil }
        if gapSeconds <= shortGapThresholdSeconds { return .normalCadence }
        if gapSeconds <= backgroundGapThresholdSeconds { return .shortGap }
        if gapSeconds <= extendedSignalLossThresholdSeconds { return .backgroundLocationGap }
        return .extendedSignalLoss
    }
}

enum DeadReckoningReadinessReason: String, Codable, Sendable, Equatable {
    case normalCadence
    case headingUnavailable
    case anchorUnavailable
    case eligibleDiagnosticsOnly
    case r4RouteReconstructionDeferred
}

struct DeadReckoningDiagnostics: Codable, Sendable, Equatable {
    let estimatedRouteActive: Bool
    let eligibleForFutureEstimation: Bool
    let anchorAvailable: Bool
    let gapSeconds: TimeInterval?
    let headingAvailable: Bool
    let reason: DeadReckoningReadinessReason

    init(
        estimatedRouteActive: Bool = false,
        eligibleForFutureEstimation: Bool = false,
        anchorAvailable: Bool = false,
        gapSeconds: TimeInterval? = nil,
        headingAvailable: Bool = false,
        reason: DeadReckoningReadinessReason = .normalCadence
    ) {
        self.estimatedRouteActive = estimatedRouteActive
        self.eligibleForFutureEstimation = eligibleForFutureEstimation
        self.anchorAvailable = anchorAvailable
        self.gapSeconds = gapSeconds.map { max(0, $0) }
        self.headingAvailable = headingAvailable
        self.reason = reason
    }
}

enum MotionSampleSource: String, Codable, Sendable, Equatable {
    case timerFusion
    case locationFix
    case debugSimulated
}

enum AltitudeSampleSource: String, Codable, Sendable, Equatable {
    case coreLocationAbsolute
    case barometerRelative
    case debugSimulated
    case unavailable
}

enum ActivityFidelityProfile: String, Codable, Sendable, Equatable {
    case technicalSkateboard
    case standardSkateboard
    case electricSkateboard
    case inlineRecreation
    case inlineSpeed
    case snowReserved
    case vehicleValidation

    static func defaultProfile(for mode: SportMode, powerType: PowerType = .humanPowered) -> ActivityFidelityProfile {
        switch (mode, powerType) {
        case (.skateboard(.surfskate), _):
            return .technicalSkateboard
        case (.skateboard, .electric):
            return .electricSkateboard
        case (.skateboard, _):
            return .standardSkateboard
        case (.inline(.fitnessSpeed), _):
            return .inlineSpeed
        case (.inline, _):
            return .inlineRecreation
        }
    }
}

struct ActivityFidelityPolicy: Codable, Sendable, Equatable {
    static let maximumGlobalPlausibleSpeedKmh = 180.0

    let profile: ActivityFidelityProfile
    let preferredHorizontalAccuracyMeters: Double
    let maximumUsableHorizontalAccuracyMeters: Double
    let maximumTrustedUpdateIntervalSeconds: TimeInterval
    let maximumTrustedSegmentDistanceMeters: Double
    let maximumTrustedImpliedSpeedKmh: Double
    let chartMaximumSpeedKmh: Double
    let fallDetectionEnabled: Bool
    let fallDetectionMaximumSpeedKmh: Double
    let maximumElevationStepMeters: Double
    let maximumVerticalAccuracyMeters: Double

    init(profile: ActivityFidelityProfile) {
        self.profile = profile
        switch profile {
        case .technicalSkateboard:
            preferredHorizontalAccuracyMeters = 5
            maximumUsableHorizontalAccuracyMeters = 25
            maximumTrustedUpdateIntervalSeconds = 4
            maximumTrustedSegmentDistanceMeters = 35
            maximumTrustedImpliedSpeedKmh = 45
            chartMaximumSpeedKmh = 60
            fallDetectionEnabled = true
            fallDetectionMaximumSpeedKmh = 35
            maximumElevationStepMeters = 3
            maximumVerticalAccuracyMeters = 12
        case .standardSkateboard:
            preferredHorizontalAccuracyMeters = 8
            maximumUsableHorizontalAccuracyMeters = 40
            maximumTrustedUpdateIntervalSeconds = 6
            maximumTrustedSegmentDistanceMeters = 80
            maximumTrustedImpliedSpeedKmh = 70
            chartMaximumSpeedKmh = 80
            fallDetectionEnabled = true
            fallDetectionMaximumSpeedKmh = 45
            maximumElevationStepMeters = 4
            maximumVerticalAccuracyMeters = 15
        case .electricSkateboard:
            preferredHorizontalAccuracyMeters = 10
            maximumUsableHorizontalAccuracyMeters = 60
            maximumTrustedUpdateIntervalSeconds = 8
            maximumTrustedSegmentDistanceMeters = 180
            maximumTrustedImpliedSpeedKmh = 100
            chartMaximumSpeedKmh = 110
            fallDetectionEnabled = true
            fallDetectionMaximumSpeedKmh = 70
            maximumElevationStepMeters = 5
            maximumVerticalAccuracyMeters = 18
        case .inlineRecreation:
            preferredHorizontalAccuracyMeters = 8
            maximumUsableHorizontalAccuracyMeters = 50
            maximumTrustedUpdateIntervalSeconds = 7
            maximumTrustedSegmentDistanceMeters = 130
            maximumTrustedImpliedSpeedKmh = 85
            chartMaximumSpeedKmh = 90
            fallDetectionEnabled = true
            fallDetectionMaximumSpeedKmh = 55
            maximumElevationStepMeters = 5
            maximumVerticalAccuracyMeters = 18
        case .inlineSpeed:
            preferredHorizontalAccuracyMeters = 10
            maximumUsableHorizontalAccuracyMeters = 70
            maximumTrustedUpdateIntervalSeconds = 8
            maximumTrustedSegmentDistanceMeters = 240
            maximumTrustedImpliedSpeedKmh = 120
            chartMaximumSpeedKmh = 130
            fallDetectionEnabled = true
            fallDetectionMaximumSpeedKmh = 80
            maximumElevationStepMeters = 6
            maximumVerticalAccuracyMeters = 20
        case .snowReserved:
            preferredHorizontalAccuracyMeters = 12
            maximumUsableHorizontalAccuracyMeters = 80
            maximumTrustedUpdateIntervalSeconds = 8
            maximumTrustedSegmentDistanceMeters = 280
            maximumTrustedImpliedSpeedKmh = 140
            chartMaximumSpeedKmh = 150
            fallDetectionEnabled = false
            fallDetectionMaximumSpeedKmh = 0
            maximumElevationStepMeters = 12
            maximumVerticalAccuracyMeters = 25
        case .vehicleValidation:
            preferredHorizontalAccuracyMeters = 15
            maximumUsableHorizontalAccuracyMeters = 100
            maximumTrustedUpdateIntervalSeconds = 12
            maximumTrustedSegmentDistanceMeters = 500
            maximumTrustedImpliedSpeedKmh = Self.maximumGlobalPlausibleSpeedKmh
            chartMaximumSpeedKmh = Self.maximumGlobalPlausibleSpeedKmh
            fallDetectionEnabled = false
            fallDetectionMaximumSpeedKmh = 0
            maximumElevationStepMeters = 15
            maximumVerticalAccuracyMeters = 35
        }
    }


    var usesStrictSmallAreaLowSpeedGate: Bool {
        switch profile {
        case .technicalSkateboard, .standardSkateboard, .inlineRecreation:
            return true
        case .electricSkateboard, .inlineSpeed, .snowReserved, .vehicleValidation:
            return false
        }
    }

    var displayRouteMaximumHorizontalAccuracyMeters: Double {
        switch profile {
        case .technicalSkateboard:
            return 18
        case .standardSkateboard, .inlineRecreation:
            return 24
        case .electricSkateboard, .inlineSpeed:
            return 70
        case .snowReserved:
            return 90
        case .vehicleValidation:
            return maximumUsableHorizontalAccuracyMeters
        }
    }

    var speedDisplayCorroborationAccuracyMeters: Double {
        switch profile {
        case .technicalSkateboard:
            return max(8, preferredHorizontalAccuracyMeters)
        case .standardSkateboard, .inlineRecreation:
            return max(10, preferredHorizontalAccuracyMeters * 1.25)
        case .electricSkateboard:
            return max(20, preferredHorizontalAccuracyMeters * 1.8)
        case .inlineSpeed:
            return max(24, preferredHorizontalAccuracyMeters * 1.8)
        case .snowReserved:
            return max(30, preferredHorizontalAccuracyMeters * 2.0)
        case .vehicleValidation:
            return max(45, preferredHorizontalAccuracyMeters * 2.5)
        }
    }

    func acceptsSpeed(_ speedKmh: Double) -> Bool {
        speedKmh.isFinite && speedKmh >= 0 && speedKmh <= chartMaximumSpeedKmh
    }

    func acceptsLowSpeedMetricSample(
        speedKmh: Double,
        horizontalAccuracyMeters: Double?,
        speedAccuracyMetersPerSecond: Double?,
        coordinateDerivedSpeedKmh: Double?,
        segmentDistanceMeters: Double?
    ) -> Bool {
        guard acceptsSpeed(speedKmh) else { return false }
        guard let horizontalAccuracyMeters else { return false }

        let strictLowSpeedSuspicionThresholdKmh = 6.0
        let lowSpeedSuspicionThresholdKmh = 7.0
        let localJumpImpliedSpeedThresholdKmh = min(maximumTrustedImpliedSpeedKmh, 18.0)
        let localJumpSegmentThresholdMeters = 8.0
        let smallAreaSegmentThresholdMeters = 2.5
        let accuracyPenaltyThresholdMeters = max(preferredHorizontalAccuracyMeters, 8.0)
        let strictAccuracyPenaltyThresholdMeters = preferredHorizontalAccuracyMeters

        guard horizontalAccuracyMeters <= maximumUsableHorizontalAccuracyMeters else { return false }
        if let coordinateDerivedSpeedKmh,
           coordinateDerivedSpeedKmh > maximumTrustedImpliedSpeedKmh {
            return false
        }
        if let segmentDistanceMeters,
           segmentDistanceMeters > maximumTrustedSegmentDistanceMeters {
            return false
        }

        // Task-030c-b11-r2: keep the strict small-area low-speed gate for human-powered
        // walking/skateboard-like profiles, but do not apply it to electric, snow, speed,
        // or vehicle-validation profiles. High-speed proxy sessions should be judged by
        // their activity-aware route policy rather than by standard-skateboard local-jitter
        // thresholds.
        guard usesStrictSmallAreaLowSpeedGate else { return true }

        // Task-030c-b10-r4: low-speed metrics should not trust Core Location speed alone
        // when the movement is small, the horizontal accuracy is outside the preferred
        // envelope, or the coordinate-implied speed is only weakly corroborated.
        if speedKmh >= strictLowSpeedSuspicionThresholdKmh,
           horizontalAccuracyMeters > strictAccuracyPenaltyThresholdMeters {
            return false
        }

        if speedKmh >= lowSpeedSuspicionThresholdKmh && horizontalAccuracyMeters > accuracyPenaltyThresholdMeters {
            return false
        }

        if let speedAccuracyMetersPerSecond,
           speedAccuracyMetersPerSecond > 1.2,
           speedKmh >= strictLowSpeedSuspicionThresholdKmh {
            return false
        }

        if let coordinateDerivedSpeedKmh,
           speedKmh >= strictLowSpeedSuspicionThresholdKmh,
           coordinateDerivedSpeedKmh >= strictLowSpeedSuspicionThresholdKmh,
           horizontalAccuracyMeters > strictAccuracyPenaltyThresholdMeters {
            return false
        }

        if let coordinateDerivedSpeedKmh,
           coordinateDerivedSpeedKmh >= localJumpImpliedSpeedThresholdKmh,
           horizontalAccuracyMeters > accuracyPenaltyThresholdMeters {
            return false
        }

        if let coordinateDerivedSpeedKmh,
           coordinateDerivedSpeedKmh >= max(speedKmh * 1.6, localJumpImpliedSpeedThresholdKmh),
           horizontalAccuracyMeters > preferredHorizontalAccuracyMeters {
            return false
        }

        if let segmentDistanceMeters,
           segmentDistanceMeters > smallAreaSegmentThresholdMeters,
           horizontalAccuracyMeters > strictAccuracyPenaltyThresholdMeters,
           speedKmh >= strictLowSpeedSuspicionThresholdKmh {
            return false
        }

        if let segmentDistanceMeters,
           segmentDistanceMeters > localJumpSegmentThresholdMeters,
           horizontalAccuracyMeters > preferredHorizontalAccuracyMeters,
           speedKmh >= 5.0 {
            return false
        }

        return true
    }

    func acceptsElevationStep(_ deltaMeters: Double, verticalAccuracyMeters: Double?) -> Bool {
        guard deltaMeters.isFinite, deltaMeters > 0.5, deltaMeters <= maximumElevationStepMeters else { return false }
        guard let verticalAccuracyMeters else { return false }
        return verticalAccuracyMeters <= maximumVerticalAccuracyMeters
    }

    func trustsRouteSegment(
        horizontalAccuracyMeters: Double?,
        freshnessState: LocationFreshnessState,
        updateIntervalSeconds: TimeInterval?,
        segmentDistanceMeters: Double?,
        coordinateDerivedSpeedKmh: Double?
    ) -> Bool {
        guard freshnessState == .fresh || freshnessState == .recent else { return false }
        guard let horizontalAccuracyMeters, horizontalAccuracyMeters <= maximumUsableHorizontalAccuracyMeters else { return false }
        if updateIntervalSeconds.map({ $0 > maximumTrustedUpdateIntervalSeconds }) == true { return false }
        if segmentDistanceMeters.map({ $0 > maximumTrustedSegmentDistanceMeters }) == true { return false }
        if coordinateDerivedSpeedKmh.map({ $0 > maximumTrustedImpliedSpeedKmh }) == true { return false }
        return true
    }
}

struct LocationFixDiagnostics: Codable, Sendable, Equatable {
    let horizontalAccuracyMeters: Double?
    let verticalAccuracyMeters: Double?
    let speedAccuracyMetersPerSecond: Double?
    let courseAccuracyDegrees: Double?
    let rawLocationTimestamp: Date?
    let rawLocationTimestampMillisecondsSince1970: Int64?
    let receivedAtTimestamp: Date?
    let receivedAtTimestampMillisecondsSince1970: Int64?
    let gpsUpdateIntervalSeconds: TimeInterval?
    let gpsSegmentDistanceMeters: Double?
    let coordinateDerivedSpeedKmh: Double?
    let speedSource: LocationSpeedSource
    let freshnessState: LocationFreshnessState
    let routeSegmentConfidence: RouteSegmentConfidence
    let headingDiagnostics: HeadingDiagnostics?
    let gpsGapDiagnostics: GPSGapDiagnostics?
    let deadReckoningDiagnostics: DeadReckoningDiagnostics?

    init(
        horizontalAccuracyMeters: Double? = nil,
        verticalAccuracyMeters: Double? = nil,
        speedAccuracyMetersPerSecond: Double? = nil,
        courseAccuracyDegrees: Double? = nil,
        rawLocationTimestamp: Date? = nil,
        rawLocationTimestampMillisecondsSince1970: Int64? = nil,
        receivedAtTimestamp: Date? = nil,
        receivedAtTimestampMillisecondsSince1970: Int64? = nil,
        gpsUpdateIntervalSeconds: TimeInterval? = nil,
        gpsSegmentDistanceMeters: Double? = nil,
        coordinateDerivedSpeedKmh: Double? = nil,
        speedSource: LocationSpeedSource = .unavailable,
        freshnessState: LocationFreshnessState = .unavailable,
        routeSegmentConfidence: RouteSegmentConfidence = .unavailable,
        headingDiagnostics: HeadingDiagnostics? = nil,
        gpsGapDiagnostics: GPSGapDiagnostics? = nil,
        deadReckoningDiagnostics: DeadReckoningDiagnostics? = nil
    ) {
        self.horizontalAccuracyMeters = horizontalAccuracyMeters
        self.verticalAccuracyMeters = verticalAccuracyMeters
        self.speedAccuracyMetersPerSecond = speedAccuracyMetersPerSecond
        self.courseAccuracyDegrees = courseAccuracyDegrees
        self.rawLocationTimestamp = rawLocationTimestamp
        self.rawLocationTimestampMillisecondsSince1970 = rawLocationTimestampMillisecondsSince1970
        self.receivedAtTimestamp = receivedAtTimestamp
        self.receivedAtTimestampMillisecondsSince1970 = receivedAtTimestampMillisecondsSince1970
        self.gpsUpdateIntervalSeconds = gpsUpdateIntervalSeconds
        self.gpsSegmentDistanceMeters = gpsSegmentDistanceMeters
        self.coordinateDerivedSpeedKmh = coordinateDerivedSpeedKmh
        self.speedSource = speedSource
        self.freshnessState = freshnessState
        self.routeSegmentConfidence = routeSegmentConfidence
        self.headingDiagnostics = headingDiagnostics
        self.gpsGapDiagnostics = gpsGapDiagnostics
        self.deadReckoningDiagnostics = deadReckoningDiagnostics
    }

    func replacingR4Diagnostics(
        headingDiagnostics: HeadingDiagnostics? = nil,
        gpsGapDiagnostics: GPSGapDiagnostics? = nil,
        deadReckoningDiagnostics: DeadReckoningDiagnostics? = nil
    ) -> LocationFixDiagnostics {
        LocationFixDiagnostics(
            horizontalAccuracyMeters: horizontalAccuracyMeters,
            verticalAccuracyMeters: verticalAccuracyMeters,
            speedAccuracyMetersPerSecond: speedAccuracyMetersPerSecond,
            courseAccuracyDegrees: courseAccuracyDegrees,
            rawLocationTimestamp: rawLocationTimestamp,
            rawLocationTimestampMillisecondsSince1970: rawLocationTimestampMillisecondsSince1970,
            receivedAtTimestamp: receivedAtTimestamp,
            receivedAtTimestampMillisecondsSince1970: receivedAtTimestampMillisecondsSince1970,
            gpsUpdateIntervalSeconds: gpsUpdateIntervalSeconds,
            gpsSegmentDistanceMeters: gpsSegmentDistanceMeters,
            coordinateDerivedSpeedKmh: coordinateDerivedSpeedKmh,
            speedSource: speedSource,
            freshnessState: freshnessState,
            routeSegmentConfidence: routeSegmentConfidence,
            headingDiagnostics: headingDiagnostics ?? self.headingDiagnostics,
            gpsGapDiagnostics: gpsGapDiagnostics ?? self.gpsGapDiagnostics,
            deadReckoningDiagnostics: deadReckoningDiagnostics ?? self.deadReckoningDiagnostics
        )
    }
}

struct RouteQualitySummary: Codable, Sendable, Equatable {
    let sampleCount: Int
    let gpsSampleCount: Int
    let uniqueCoordinateCount: Int
    let lowConfidenceSegmentCount: Int
    let staleLocationSampleCount: Int
    let averageGPSUpdateIntervalSeconds: TimeInterval?
    let maxGPSUpdateIntervalSeconds: TimeInterval?
    let maxMotionSampleIntervalSeconds: TimeInterval?
    let longLocationUpdateGapCount: Int?
    let longMotionSampleGapCount: Int?
    let totalGPSDistanceMeters: Double

    init(
        sampleCount: Int,
        gpsSampleCount: Int,
        uniqueCoordinateCount: Int,
        lowConfidenceSegmentCount: Int,
        staleLocationSampleCount: Int,
        averageGPSUpdateIntervalSeconds: TimeInterval? = nil,
        maxGPSUpdateIntervalSeconds: TimeInterval? = nil,
        maxMotionSampleIntervalSeconds: TimeInterval? = nil,
        longLocationUpdateGapCount: Int? = nil,
        longMotionSampleGapCount: Int? = nil,
        totalGPSDistanceMeters: Double = 0
    ) {
        self.sampleCount = max(0, sampleCount)
        self.gpsSampleCount = max(0, gpsSampleCount)
        self.uniqueCoordinateCount = max(0, uniqueCoordinateCount)
        self.lowConfidenceSegmentCount = max(0, lowConfidenceSegmentCount)
        self.staleLocationSampleCount = max(0, staleLocationSampleCount)
        self.averageGPSUpdateIntervalSeconds = averageGPSUpdateIntervalSeconds
        self.maxGPSUpdateIntervalSeconds = maxGPSUpdateIntervalSeconds
        self.maxMotionSampleIntervalSeconds = maxMotionSampleIntervalSeconds
        self.longLocationUpdateGapCount = longLocationUpdateGapCount.map { max(0, $0) }
        self.longMotionSampleGapCount = longMotionSampleGapCount.map { max(0, $0) }
        self.totalGPSDistanceMeters = max(0, totalGPSDistanceMeters)
    }

    static func make(from samples: [MotionSample]) -> RouteQualitySummary {
        var uniqueCoordinates = Set<String>()
        var uniqueLocationFixKeys = Set<String>()
        var lowConfidenceSegmentCount = 0
        var staleLocationSampleCount = 0
        var updateIntervals: [TimeInterval] = []
        var motionSampleIntervals: [TimeInterval] = []
        var totalGPSDistanceMeters = 0.0
        var previousCoordinate: GeoCoordinate?
        var previousTimestamp: Date?
        var previousSampleTimestamp: Date?

        let sortedSamples = samples.sorted { lhs, rhs in
            Self.routeTimestamp(for: lhs) < Self.routeTimestamp(for: rhs)
        }

        for sample in sortedSamples {
            if let previousSampleTimestamp {
                let sampleInterval = max(sample.timestamp.timeIntervalSince(previousSampleTimestamp), 0)
                if sampleInterval > 0 {
                    motionSampleIntervals.append(sampleInterval)
                }
            }
            previousSampleTimestamp = sample.timestamp
            guard let coordinate = sample.gpsCoordinate else { continue }
            uniqueCoordinates.insert(Self.coordinateKey(for: coordinate))

            let locationFixKey = Self.locationFixKey(for: sample, coordinate: coordinate)
            let isNewLocationFix = uniqueLocationFixKeys.insert(locationFixKey).inserted
            guard isNewLocationFix else { continue }

            if let diagnostics = sample.locationDiagnostics {
                if diagnostics.freshnessState == .stale {
                    staleLocationSampleCount += 1
                }
                if diagnostics.routeSegmentConfidence == .low {
                    lowConfidenceSegmentCount += 1
                }
                if let interval = diagnostics.gpsUpdateIntervalSeconds, interval > 0 {
                    updateIntervals.append(interval)
                }
                if let distance = diagnostics.gpsSegmentDistanceMeters, distance > 0 {
                    if Self.isTrustedRouteDistanceSegment(diagnostics) {
                        totalGPSDistanceMeters += distance
                        previousCoordinate = coordinate
                        previousTimestamp = Self.routeTimestamp(for: sample)
                    } else {
                        previousCoordinate = nil
                        previousTimestamp = nil
                    }
                    continue
                }
            }

            guard let lastCoordinate = previousCoordinate else {
                previousCoordinate = coordinate
                previousTimestamp = Self.routeTimestamp(for: sample)
                continue
            }

            let segmentDistance = haversineDistanceMeters(from: lastCoordinate, to: coordinate)
            guard segmentDistance >= 0.5 else { continue }
            totalGPSDistanceMeters += segmentDistance

            if let previousTimestamp {
                let interval = max(Self.routeTimestamp(for: sample).timeIntervalSince(previousTimestamp), 0)
                if interval > 0 {
                    updateIntervals.append(interval)
                }
                if interval > 10 || segmentDistance > 100 {
                    lowConfidenceSegmentCount += 1
                }
            }

            previousCoordinate = coordinate
            previousTimestamp = Self.routeTimestamp(for: sample)
        }

        let averageInterval = updateIntervals.isEmpty ? nil : updateIntervals.reduce(0, +) / Double(updateIntervals.count)
        let longLocationUpdateGapCount = updateIntervals.filter { $0 > 10 }.count
        let longMotionSampleGapCount = motionSampleIntervals.filter { $0 > 5 }.count
        return RouteQualitySummary(
            sampleCount: samples.count,
            gpsSampleCount: samples.filter { $0.gpsCoordinate != nil }.count,
            uniqueCoordinateCount: uniqueCoordinates.count,
            lowConfidenceSegmentCount: lowConfidenceSegmentCount,
            staleLocationSampleCount: staleLocationSampleCount,
            averageGPSUpdateIntervalSeconds: averageInterval,
            maxGPSUpdateIntervalSeconds: updateIntervals.max(),
            maxMotionSampleIntervalSeconds: motionSampleIntervals.max(),
            longLocationUpdateGapCount: longLocationUpdateGapCount,
            longMotionSampleGapCount: longMotionSampleGapCount,
            totalGPSDistanceMeters: totalGPSDistanceMeters
        )
    }

    private static func isTrustedRouteDistanceSegment(_ diagnostics: LocationFixDiagnostics) -> Bool {
        guard diagnostics.routeSegmentConfidence != .low,
              diagnostics.routeSegmentConfidence != .unavailable else { return false }
        let policy = ActivityFidelityPolicy(profile: .standardSkateboard)
        let speedKmh = diagnostics.coordinateDerivedSpeedKmh ?? 0
        guard policy.acceptsLowSpeedMetricSample(
            speedKmh: speedKmh,
            horizontalAccuracyMeters: diagnostics.horizontalAccuracyMeters,
            speedAccuracyMetersPerSecond: diagnostics.speedAccuracyMetersPerSecond,
            coordinateDerivedSpeedKmh: diagnostics.coordinateDerivedSpeedKmh,
            segmentDistanceMeters: diagnostics.gpsSegmentDistanceMeters
        ) || speedKmh == 0 else { return false }
        return policy.trustsRouteSegment(
            horizontalAccuracyMeters: diagnostics.horizontalAccuracyMeters,
            freshnessState: diagnostics.freshnessState,
            updateIntervalSeconds: diagnostics.gpsUpdateIntervalSeconds,
            segmentDistanceMeters: diagnostics.gpsSegmentDistanceMeters,
            coordinateDerivedSpeedKmh: diagnostics.coordinateDerivedSpeedKmh
        )
    }

    private static func routeTimestamp(for sample: MotionSample) -> Date {
        sample.locationDiagnostics?.rawLocationTimestamp ?? sample.timestamp
    }

    private static func locationFixKey(for sample: MotionSample, coordinate: GeoCoordinate) -> String {
        if let rawTimestamp = sample.locationDiagnostics?.rawLocationTimestampMillisecondsSince1970 {
            return "\(rawTimestamp)-\(coordinateKey(for: coordinate))"
        }
        return "\(sample.timestampMillisecondsSince1970 ?? sample.timestamp.millisecondsSince1970)-\(coordinateKey(for: coordinate))"
    }

    private static func coordinateKey(for coordinate: GeoCoordinate) -> String {
        "\(coordinate.latitude.rounded(toPlaces: 7)),\(coordinate.longitude.rounded(toPlaces: 7))"
    }

    private static func haversineDistanceMeters(from start: GeoCoordinate, to end: GeoCoordinate) -> Double {
        let earthRadiusMeters = 6_371_000.0
        let deltaLatitude = (end.latitude - start.latitude) * (.pi / 180)
        let deltaLongitude = (end.longitude - start.longitude) * (.pi / 180)
        let startLatitude = start.latitude * (.pi / 180)
        let endLatitude = end.latitude * (.pi / 180)
        let haversine = sin(deltaLatitude / 2) * sin(deltaLatitude / 2)
            + cos(startLatitude) * cos(endLatitude) * sin(deltaLongitude / 2) * sin(deltaLongitude / 2)
        let centralAngle = 2 * atan2(sqrt(haversine), sqrt(1 - haversine))
        return earthRadiusMeters * centralAngle
    }
}

struct MotionSample: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    let timestamp: Date
    let timestampMillisecondsSince1970: Int64?
    let gpsCoordinate: GeoCoordinate?
    let speedKmh: Double
    let accelerometerG: ThreeAxisValue
    let gyroscopeRadPS: ThreeAxisValue
    let altitudeMeters: Double?
    let altitudeSource: AltitudeSampleSource?
    let locationDiagnostics: LocationFixDiagnostics?
    let sampleSource: MotionSampleSource?

    init(
        id: UUID = UUID(),
        timestamp: Date,
        timestampMillisecondsSince1970: Int64? = nil,
        gpsCoordinate: GeoCoordinate? = nil,
        speedKmh: Double,
        accelerometerG: ThreeAxisValue,
        gyroscopeRadPS: ThreeAxisValue,
        altitudeMeters: Double? = nil,
        altitudeSource: AltitudeSampleSource? = nil,
        locationDiagnostics: LocationFixDiagnostics? = nil,
        sampleSource: MotionSampleSource? = .timerFusion
    ) {
        self.id = id
        self.timestamp = timestamp
        self.timestampMillisecondsSince1970 = timestampMillisecondsSince1970 ?? timestamp.millisecondsSince1970
        self.gpsCoordinate = gpsCoordinate
        self.speedKmh = speedKmh
        self.accelerometerG = accelerometerG
        self.gyroscopeRadPS = gyroscopeRadPS
        self.altitudeMeters = altitudeMeters
        self.altitudeSource = altitudeSource
        self.locationDiagnostics = locationDiagnostics
        self.sampleSource = sampleSource
    }
}

private extension Date {
    var millisecondsSince1970: Int64 {
        Int64((timeIntervalSince1970 * 1_000).rounded())
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
