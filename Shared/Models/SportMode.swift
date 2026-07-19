// [協作區] Shared/Models/SportMode.swift
// 用途：定義 SkateTrack 跨平台共用的滑板、直排輪與雪地運動模式。
// 委派至：後續 Task 的 session recording、feature flags、analytics 與 UI 選擇器。

import Foundation

enum BoardMode: String, Codable, Sendable, CaseIterable {
    case streetPark
    case longboard
    case surfskate
    case freebord

    var localizationKey: String {
        switch self {
        case .streetPark:
            return "sport.mode.streetpark"
        case .longboard:
            return "sport.mode.longboard"
        case .surfskate:
            return "sport.mode.surfskate"
        case .freebord:
            return "sport.mode.freebord"
        }
    }
}

enum InlineMode: String, Codable, Sendable, CaseIterable {
    case urbanFreestyle
    case fitnessSpeed
    case aggressive
    case slalom

    var localizationKey: String {
        switch self {
        case .urbanFreestyle:
            return "sport.mode.inline.urban"
        case .fitnessSpeed:
            return "sport.mode.inline.fitness"
        case .aggressive:
            return "sport.mode.inline.aggressive"
        case .slalom:
            return "sport.mode.inline.slalom"
        }
    }
}

enum SportMode: Codable, Sendable, Equatable {
    case skateboard(BoardMode)
    case inline(InlineMode)
    case snow(SnowDiscipline)

    var sportLocalizationKey: String {
        switch self {
        case .skateboard:
            return "sport.skateboard"
        case .inline:
            return "sport.inline"
        case .snow:
            return "snow.sport.title"
        }
    }

    var modeLocalizationKey: String {
        switch self {
        case let .skateboard(boardMode):
            return boardMode.localizationKey
        case let .inline(inlineMode):
            return inlineMode.localizationKey
        case let .snow(discipline):
            return discipline.localizationKey
        }
    }

    var allowsElectricPower: Bool {
        switch self {
        case .skateboard:
            return true
        case .inline:
            return false
        case .snow:
            return false
        }
    }

    var requiresEquipmentSelection: Bool {
        switch self {
        case .skateboard, .inline:
            return true
        case .snow:
            return false
        }
    }
}
