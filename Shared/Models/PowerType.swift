// [協作區] Shared/Models/PowerType.swift
// 用途：定義 session 與裝備使用的人力或電動動力來源，並集中驗證電動僅適用於滑板模式。
// 委派至：SessionData、EquipmentProfile 與後續訂閱 / 分析任務。

import Foundation

enum PowerType: String, Codable, Sendable, CaseIterable {
    case humanPowered
    case electric

    var localizationKey: String {
        switch self {
        case .humanPowered:
            return "power.human"
        case .electric:
            return "power.electric"
        }
    }

    func isValid(for sportMode: SportMode) -> Bool {
        switch self {
        case .humanPowered:
            return true
        case .electric:
            return sportMode.allowsElectricPower
        }
    }
}

enum PowerTypeValidationError: Error, Sendable {
    case electricPowerRequiresSkateboardMode
}
