// [協作區] iOS/Core/SnowEngine/SnowLiveHUDState.swift
// 用途：SnowHUDView 唯一允許 switch 的 iPhone Snow Live HUD view-state enum。
// 委派至：SnowLiveHUDStateMapper、Snow-Task-005 iPhone UI。

import Foundation

struct SnowDownhillHUDModel: Sendable, Equatable {
    let runNumber: Int
    let currentSpeedKmh: Double
    let maxSpeedThisRunKmh: Double
    let verticalDropMeters: Double
    let skiDistanceMeters: Double
    let elapsedTime: TimeInterval
}

struct SnowLiftHUDModel: Sendable, Equatable {
    let segmentType: SnowSegmentType
    let currentSpeedKmh: Double
    let liftDistanceMeters: Double
    let routeDistanceMeters: Double
    let messageLocalizationKey: String
}

struct SnowWaitingHUDModel: Sendable, Equatable {
    let titleLocalizationKey: String
    let currentSegmentType: SnowSegmentType
    let pendingEndElapsedSeconds: TimeInterval?
    let lastRunVerticalDropMeters: Double?
    let lastRunTopSpeedKmh: Double?
    let lastRunDurationSeconds: TimeInterval?
}

struct SnowLowConfidenceHUDModel: Sendable, Equatable {
    let currentSegmentType: SnowSegmentType
    let confidence: Double
    let reasonCodes: [String]
    let currentSpeedKmh: Double
    let messageLocalizationKey: String
}

enum SnowLiveHUDState: Sendable, Equatable {
    case downhill(SnowDownhillHUDModel)
    case lift(SnowLiftHUDModel)
    case waiting(SnowWaitingHUDModel)
    case lowConfidence(SnowLowConfidenceHUDModel)
}
