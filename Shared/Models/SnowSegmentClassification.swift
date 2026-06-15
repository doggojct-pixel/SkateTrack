// [協作區] Shared/Models/SnowSegmentClassification.swift
// 用途：表示 SnowSegmentClassifier 對一段 MotionSample 視窗的 v0 分類結果。
// 委派至：SnowSegmentClassifier、later run-boundary task 與 Snow-Task-003 fixture tests。

import Foundation

struct SnowSegmentClassification: Sendable, Equatable {
    let type: SnowSegmentType
    let confidence: Double
    let startDate: Date?
    let endDate: Date?
    let sampleCount: Int
    let averageSpeedKmh: Double
    let maxSpeedKmh: Double
    let altitudeDeltaMeters: Double?
    let verticalRateMetersPerSecond: Double?
    let motionEnergyG: Double
    let headingStandardDeviationDegrees: Double?
    let routeDistanceMeters: Double
    let reasonCodes: [String]

    init(
        type: SnowSegmentType,
        confidence: Double,
        startDate: Date?,
        endDate: Date?,
        sampleCount: Int,
        averageSpeedKmh: Double,
        maxSpeedKmh: Double,
        altitudeDeltaMeters: Double?,
        verticalRateMetersPerSecond: Double?,
        motionEnergyG: Double,
        headingStandardDeviationDegrees: Double?,
        routeDistanceMeters: Double,
        reasonCodes: [String]
    ) {
        self.type = type
        self.confidence = min(max(confidence, 0), 1)
        self.startDate = startDate
        self.endDate = endDate
        self.sampleCount = sampleCount
        self.averageSpeedKmh = max(0, averageSpeedKmh)
        self.maxSpeedKmh = max(0, maxSpeedKmh)
        self.altitudeDeltaMeters = altitudeDeltaMeters
        self.verticalRateMetersPerSecond = verticalRateMetersPerSecond
        self.motionEnergyG = max(0, motionEnergyG)
        self.headingStandardDeviationDegrees = headingStandardDeviationDegrees
        self.routeDistanceMeters = max(0, routeDistanceMeters)
        self.reasonCodes = reasonCodes
    }
}
