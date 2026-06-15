// [協作區] Shared/Models/SnowSegmentClassifier.swift
// 用途：Snow-Task-003 v0 rule-based classifier，將 MotionSample 視窗分類為 SnowSegmentType。
// 委派至：later run-boundary task、SnowSessionRepository fixture tests 與後續 Snow UI。

import Foundation

struct SnowSegmentClassifier: Sendable {
    let config: SnowClassifierConfig

    init(config: SnowClassifierConfig = .productionV0) {
        self.config = config
    }

    func classify(
        samples unsortedSamples: [MotionSample],
        previousType: SnowSegmentType? = nil
    ) -> SnowSegmentClassification {
        let samples = unsortedSamples.sorted { $0.timestamp < $1.timestamp }
        let metrics = makeMetrics(samples: samples)

        guard metrics.sampleCount >= config.minimumSampleCount, metrics.durationSeconds > 0 else {
            return makeClassification(type: .unknown, confidence: 0.12, metrics: metrics, reasonCodes: ["insufficientSamples"])
        }

        let candidate = classifyCandidate(metrics: metrics)
        return applyHysteresisIfNeeded(candidate, previousType: previousType, metrics: metrics)
    }

    private func classifyCandidate(metrics: ClassificationMetrics) -> SnowSegmentClassification {
        if metrics.durationSeconds >= config.stoppedWindowSeconds,
           metrics.averageSpeedKmh < config.stoppedSpeedThresholdKmh,
           metrics.motionEnergyG <= config.lowMotionEnergyThresholdG + 0.02 {
            return makeClassification(type: .stopped, confidence: 0.88, metrics: metrics, reasonCodes: ["lowSpeed", "lowMotionEnergy"])
        }

        if metrics.averageSpeedKmh >= config.walkingMinSpeedKmh,
           metrics.averageSpeedKmh <= config.walkingMaxSpeedKmh,
           abs(metrics.verticalRateMetersPerSecond ?? 0) <= config.flatVerticalRateAbsThresholdMetersPerSecond {
            return makeClassification(type: .walking, confidence: 0.76, metrics: metrics, reasonCodes: ["walkingSpeed", "flatAltitudeTrend"])
        }

        if let verticalRate = metrics.verticalRateMetersPerSecond,
           verticalRate >= config.ascentVerticalRateThresholdMetersPerSecond {
            return classifyAscent(metrics: metrics, verticalRate: verticalRate)
        }

        if let verticalRate = metrics.verticalRateMetersPerSecond,
           verticalRate <= config.downhillVerticalRateThresholdMetersPerSecond,
           metrics.averageSpeedKmh >= config.downhillMinSpeedKmh {
            return classifyDescent(metrics: metrics, verticalRate: verticalRate)
        }

        if abs(metrics.verticalRateMetersPerSecond ?? 0) <= config.flatVerticalRateAbsThresholdMetersPerSecond,
           metrics.averageSpeedKmh >= config.flatTraverseMinSpeedKmh,
           metrics.motionEnergyG > config.lowMotionEnergyThresholdG {
            return makeClassification(type: .flatTraverse, confidence: 0.70, metrics: metrics, reasonCodes: ["flatAltitudeTrend", "moving"])
        }

        if metrics.altitudeDeltaMeters == nil, metrics.averageSpeedKmh >= config.downhillMinSpeedKmh {
            return makeClassification(type: .unknown, confidence: 0.32, metrics: metrics, reasonCodes: ["missingAltitude", "moving"])
        }

        return makeClassification(type: .unknown, confidence: 0.28, metrics: metrics, reasonCodes: ["noRuleMatched"])
    }

    private func classifyAscent(metrics: ClassificationMetrics, verticalRate: Double) -> SnowSegmentClassification {
        if metrics.averageSpeedKmh >= config.gondolaMinSpeedKmh,
           metrics.averageSpeedKmh <= config.gondolaMaxSpeedKmh,
           metrics.motionEnergyG <= config.lowMotionEnergyThresholdG,
           (metrics.headingStandardDeviationDegrees ?? 0) <= config.stableHeadingStandardDeviationThresholdDegrees {
            return makeClassification(type: .gondolaAscent, confidence: 0.84, metrics: metrics, reasonCodes: ["ascentTrend", "stableHeading", "lowMotionEnergy", "gondolaSpeed"])
        }

        if metrics.averageSpeedKmh >= config.walkingMinSpeedKmh,
           metrics.averageSpeedKmh <= config.walkingMaxSpeedKmh,
           metrics.motionEnergyG <= config.downhillMotionEnergyThresholdG {
            return makeClassification(type: .surfaceLiftAscent, confidence: 0.78, metrics: metrics, reasonCodes: ["ascentTrend", "surfaceLiftSpeed"])
        }

        let confidence = verticalRate >= config.ascentVerticalRateThresholdMetersPerSecond * 1.8 ? 0.82 : 0.74
        return makeClassification(type: .liftAscent, confidence: confidence, metrics: metrics, reasonCodes: ["ascentTrend", "liftSpeed"])
    }

    private func classifyDescent(metrics: ClassificationMetrics, verticalRate: Double) -> SnowSegmentClassification {
        if metrics.averageSpeedKmh >= config.gondolaMinSpeedKmh,
           metrics.averageSpeedKmh <= config.gondolaMaxSpeedKmh,
           metrics.motionEnergyG <= config.lowMotionEnergyThresholdG,
           (metrics.headingStandardDeviationDegrees ?? 0) <= config.stableHeadingStandardDeviationThresholdDegrees {
            return makeClassification(type: .unknown, confidence: 0.45, metrics: metrics, reasonCodes: ["ambiguousGondolaLikeDescent", "stableHeading", "lowMotionEnergy"])
        }

        let hasDownhillMotion = metrics.motionEnergyG >= config.downhillMotionEnergyThresholdG
        let hasDownhillHeadingChange = (metrics.headingStandardDeviationDegrees ?? 0) >= config.downhillHeadingStandardDeviationThresholdDegrees
        if hasDownhillMotion || hasDownhillHeadingChange {
            let confidence = verticalRate <= config.strongDownhillVerticalRateThresholdMetersPerSecond ? 0.90 : 0.80
            var reasons = ["downhillAltitudeTrend", "speedAboveThreshold"]
            if hasDownhillMotion { reasons.append("motionEnergy") }
            if hasDownhillHeadingChange { reasons.append("headingVariation") }
            return makeClassification(type: .downhillRun, confidence: confidence, metrics: metrics, reasonCodes: reasons)
        }

        return makeClassification(type: .unknown, confidence: 0.55, metrics: metrics, reasonCodes: ["downhillAltitudeTrend", "lowMotionEnergy", "insufficientHeadingVariation"])
    }

    private func applyHysteresisIfNeeded(
        _ candidate: SnowSegmentClassification,
        previousType: SnowSegmentType?,
        metrics: ClassificationMetrics
    ) -> SnowSegmentClassification {
        guard let previousType, previousType != candidate.type else { return candidate }
        guard metrics.durationSeconds < config.hysteresisSeconds else { return candidate }
        guard candidate.confidence < config.mediumConfidenceThreshold else { return candidate }

        var reasons = candidate.reasonCodes
        reasons.append("hysteresisHold")
        return makeClassification(type: previousType, confidence: max(0.35, candidate.confidence - 0.10), metrics: metrics, reasonCodes: reasons)
    }

    private func makeClassification(
        type: SnowSegmentType,
        confidence: Double,
        metrics: ClassificationMetrics,
        reasonCodes: [String]
    ) -> SnowSegmentClassification {
        SnowSegmentClassification(
            type: type,
            confidence: confidence,
            startDate: metrics.startDate,
            endDate: metrics.endDate,
            sampleCount: metrics.sampleCount,
            averageSpeedKmh: metrics.averageSpeedKmh,
            maxSpeedKmh: metrics.maxSpeedKmh,
            altitudeDeltaMeters: metrics.altitudeDeltaMeters,
            verticalRateMetersPerSecond: metrics.verticalRateMetersPerSecond,
            motionEnergyG: metrics.motionEnergyG,
            headingStandardDeviationDegrees: metrics.headingStandardDeviationDegrees,
            routeDistanceMeters: metrics.routeDistanceMeters,
            reasonCodes: reasonCodes
        )
    }

    private func makeMetrics(samples: [MotionSample]) -> ClassificationMetrics {
        let startDate = samples.first?.timestamp
        let endDate = samples.last?.timestamp
        let duration = startDate.flatMap { start in endDate.map { max(0, $0.timeIntervalSince(start)) } } ?? 0
        let speeds = samples.map { max(0, $0.speedKmh) }
        let averageSpeed = speeds.isEmpty ? 0 : speeds.reduce(0, +) / Double(speeds.count)
        let maxSpeed = speeds.max() ?? 0
        let smoothedAltitudes = smoothedAltitudeSeries(samples: samples)
        let altitudeDelta = smoothedAltitudes.first.flatMap { first in smoothedAltitudes.last.map { $0 - first } }
        let verticalRate = altitudeDelta.flatMap { delta in duration > 0 ? delta / duration : nil }
        let motionEnergy = samples.isEmpty ? 0 : samples.map { motionEnergyG($0.accelerometerG) }.reduce(0, +) / Double(samples.count)
        let routeDistance = routeDistanceMeters(samples: samples)
        let headingStdDev = headingStandardDeviationDegrees(samples: samples)

        return ClassificationMetrics(
            startDate: startDate,
            endDate: endDate,
            sampleCount: samples.count,
            durationSeconds: duration,
            averageSpeedKmh: averageSpeed,
            maxSpeedKmh: maxSpeed,
            altitudeDeltaMeters: altitudeDelta,
            verticalRateMetersPerSecond: verticalRate,
            motionEnergyG: motionEnergy,
            headingStandardDeviationDegrees: headingStdDev,
            routeDistanceMeters: routeDistance
        )
    }

    private func smoothedAltitudeSeries(samples: [MotionSample]) -> [Double] {
        let altitudes = samples.compactMap { $0.altitudeMeters }
        guard !altitudes.isEmpty else { return [] }
        let windowSize = max(1, config.altitudeMovingAverageSampleCount)
        return altitudes.indices.map { index in
            let lowerBound = max(0, index - windowSize + 1)
            let window = altitudes[lowerBound...index]
            return window.reduce(0, +) / Double(window.count)
        }
    }

    private func motionEnergyG(_ value: ThreeAxisValue) -> Double {
        let gravityAdjustedZ = value.z - 1
        return sqrt((value.x * value.x) + (value.y * value.y) + (gravityAdjustedZ * gravityAdjustedZ))
    }

    private func routeDistanceMeters(samples: [MotionSample]) -> Double {
        samples.map(\.gpsCoordinate).compactMap { $0 }.adjacentPairs().reduce(0) { partialResult, pair in
            partialResult + haversineDistanceMeters(from: pair.0, to: pair.1)
        }
    }

    private func headingStandardDeviationDegrees(samples: [MotionSample]) -> Double? {
        let bearings = samples.map(\.gpsCoordinate).compactMap { $0 }.adjacentPairs().map { bearingDegrees(from: $0.0, to: $0.1) }
        guard bearings.count >= 2 else { return nil }
        let radians = bearings.map { $0 * .pi / 180 }
        let sinMean = radians.map(sin).reduce(0, +) / Double(radians.count)
        let cosMean = radians.map(cos).reduce(0, +) / Double(radians.count)
        let resultantLength = min(1, max(0, sqrt((sinMean * sinMean) + (cosMean * cosMean))))
        guard resultantLength > 0 else { return 180 }
        return sqrt(-2 * log(resultantLength)) * 180 / .pi
    }

    private func haversineDistanceMeters(from start: GeoCoordinate, to end: GeoCoordinate) -> Double {
        let earthRadiusMeters = 6_371_000.0
        let lat1 = start.latitude * .pi / 180
        let lat2 = end.latitude * .pi / 180
        let deltaLat = (end.latitude - start.latitude) * .pi / 180
        let deltaLon = (end.longitude - start.longitude) * .pi / 180
        let a = sin(deltaLat / 2) * sin(deltaLat / 2)
            + cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthRadiusMeters * c
    }

    private func bearingDegrees(from start: GeoCoordinate, to end: GeoCoordinate) -> Double {
        let lat1 = start.latitude * .pi / 180
        let lat2 = end.latitude * .pi / 180
        let deltaLon = (end.longitude - start.longitude) * .pi / 180
        let y = sin(deltaLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        let bearing = atan2(y, x) * 180 / .pi
        return bearing < 0 ? bearing + 360 : bearing
    }
}

private struct ClassificationMetrics: Sendable, Equatable {
    let startDate: Date?
    let endDate: Date?
    let sampleCount: Int
    let durationSeconds: TimeInterval
    let averageSpeedKmh: Double
    let maxSpeedKmh: Double
    let altitudeDeltaMeters: Double?
    let verticalRateMetersPerSecond: Double?
    let motionEnergyG: Double
    let headingStandardDeviationDegrees: Double?
    let routeDistanceMeters: Double
}

private extension Array {
    func adjacentPairs() -> [(Element, Element)] {
        guard count >= 2 else { return [] }
        return zip(self.dropLast(), self.dropFirst()).map { ($0, $1) }
    }
}
