// [協作區] Shared/Models/SnowClassifierConfig.swift
// 用途：集中定義 SnowSegmentClassifier v0 rule-based 分類門檻。
// 委派至：SnowSegmentClassifier、Snow-Task-003 fixture tests 與後續實機校準。

import Foundation

struct SnowClassifierConfig: Codable, Sendable, Equatable {
    let altitudeMovingAverageSampleCount: Int
    let trendWindowSeconds: TimeInterval
    let hysteresisSeconds: TimeInterval
    let ascentWindowSeconds: TimeInterval
    let stoppedWindowSeconds: TimeInterval
    let minimumSampleCount: Int

    let downhillMinSpeedKmh: Double
    let downhillVerticalRateThresholdMetersPerSecond: Double
    let strongDownhillVerticalRateThresholdMetersPerSecond: Double

    let ascentVerticalRateThresholdMetersPerSecond: Double
    let flatVerticalRateAbsThresholdMetersPerSecond: Double

    let stoppedSpeedThresholdKmh: Double
    let walkingMinSpeedKmh: Double
    let walkingMaxSpeedKmh: Double
    let flatTraverseMinSpeedKmh: Double

    let gondolaMinSpeedKmh: Double
    let gondolaMaxSpeedKmh: Double

    let downhillMotionEnergyThresholdG: Double
    let lowMotionEnergyThresholdG: Double

    let downhillHeadingStandardDeviationThresholdDegrees: Double
    let stableHeadingStandardDeviationThresholdDegrees: Double

    let highConfidenceThreshold: Double
    let mediumConfidenceThreshold: Double

    static let productionV0 = SnowClassifierConfig(
        altitudeMovingAverageSampleCount: 30,
        trendWindowSeconds: 5,
        hysteresisSeconds: 5,
        ascentWindowSeconds: 10,
        stoppedWindowSeconds: 15,
        minimumSampleCount: 5,
        downhillMinSpeedKmh: 10,
        downhillVerticalRateThresholdMetersPerSecond: -0.25,
        strongDownhillVerticalRateThresholdMetersPerSecond: -0.45,
        ascentVerticalRateThresholdMetersPerSecond: 0.15,
        flatVerticalRateAbsThresholdMetersPerSecond: 0.10,
        stoppedSpeedThresholdKmh: 2,
        walkingMinSpeedKmh: 2,
        walkingMaxSpeedKmh: 6,
        flatTraverseMinSpeedKmh: 6,
        gondolaMinSpeedKmh: 8,
        gondolaMaxSpeedKmh: 30,
        downhillMotionEnergyThresholdG: 0.08,
        lowMotionEnergyThresholdG: 0.03,
        downhillHeadingStandardDeviationThresholdDegrees: 12,
        stableHeadingStandardDeviationThresholdDegrees: 5,
        highConfidenceThreshold: 0.78,
        mediumConfidenceThreshold: 0.62
    )
}
