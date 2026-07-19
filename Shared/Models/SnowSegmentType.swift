// [協作區] Shared/Models/SnowSegmentType.swift
// 用途：定義 Snow Mode 生產資料層的 segment 分類型別。
// 委派至：SnowSegmentClassifier、RunBoundaryDetector、SnowSessionRepository、Snow UI 與 package compatibility。

import Foundation

enum SnowSegmentType: String, Codable, Sendable, CaseIterable, Identifiable {
    case downhillRun
    case liftAscent
    case gondolaAscent
    case surfaceLiftAscent
    case flatTraverse
    case walking
    case stopped
    case unknown

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .downhillRun:
            return "snow.segment.downhillRun"
        case .liftAscent:
            return "snow.segment.liftAscent"
        case .gondolaAscent:
            return "snow.segment.gondolaAscent"
        case .surfaceLiftAscent:
            return "snow.segment.surfaceLiftAscent"
        case .flatTraverse:
            return "snow.segment.flatTraverse"
        case .walking:
            return "snow.segment.walking"
        case .stopped:
            return "snow.segment.stopped"
        case .unknown:
            return "snow.segment.unknown"
        }
    }

    var defaultCountsTowardSkiDistance: Bool {
        switch self {
        case .downhillRun, .flatTraverse:
            return true
        case .liftAscent, .gondolaAscent, .surfaceLiftAscent, .walking, .stopped, .unknown:
            return false
        }
    }

    var countsTowardLiftDistance: Bool {
        switch self {
        case .liftAscent, .gondolaAscent, .surfaceLiftAscent:
            return true
        case .downhillRun, .flatTraverse, .walking, .stopped, .unknown:
            return false
        }
    }

    var isLiftTransport: Bool {
        switch self {
        case .liftAscent, .gondolaAscent, .surfaceLiftAscent:
            return true
        case .downhillRun, .flatTraverse, .walking, .stopped, .unknown:
            return false
        }
    }
}
