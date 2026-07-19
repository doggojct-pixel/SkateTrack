// [協作區] Shared/Models/SnowDiscipline.swift
// 用途：定義 Phase 1c Snow Mode 的雪地運動子類型，供正式 SportMode.snow 使用。
// 委派至：SportMode、Session Start、後續 Snow data model / classifier / UI tasks。

import Foundation

enum SnowDiscipline: String, Codable, Sendable, CaseIterable, Equatable, Identifiable {
    case snowboard
    case skiing

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .snowboard:
            return "snow.discipline.snowboard"
        case .skiing:
            return "snow.discipline.skiing"
        }
    }
}
