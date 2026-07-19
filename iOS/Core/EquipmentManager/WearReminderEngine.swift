// [自主區] WearReminderEngine.swift
// 用途：集中依裝備類型、輪子 / 培林里程計算 OK / CHECK / REPLACE 語意狀態。
// 委派至：EquipmentCardView、EquipmentDetailView；View 不直接硬編磨耗公式。

import Foundation

enum EquipmentWearStatus: String, Codable, Sendable, Equatable {
    case ok
    case checkSoon
    case replaceRecommended

    var badgeLocalizationKey: String {
        switch self {
        case .ok:
            return "gear.status.ok"
        case .checkSoon:
            return "gear.status.check"
        case .replaceRecommended:
            return "gear.status.replace"
        }
    }
}

enum EquipmentWearComponent: String, Codable, Sendable, CaseIterable, Identifiable {
    case wheels
    case bearings

    var id: String { rawValue }

    var titleLocalizationKey: String {
        switch self {
        case .wheels:
            return "gear.wheelWear"
        case .bearings:
            return "gear.bearingHealth"
        }
    }
}

struct EquipmentWearReading: Identifiable, Sendable, Equatable {
    let component: EquipmentWearComponent
    let mileageKm: Double
    let thresholdKm: Double
    let status: EquipmentWearStatus

    var id: EquipmentWearComponent { component }

    var progress: Double {
        guard thresholdKm > 0 else { return 0 }
        return min(max(mileageKm / thresholdKm, 0), 1)
    }
}

struct EquipmentWearReport: Sendable, Equatable {
    let equipmentID: UUID
    let overallStatus: EquipmentWearStatus
    let readings: [EquipmentWearReading]

    var primaryReading: EquipmentWearReading? {
        readings.max { lhs, rhs in lhs.progress < rhs.progress }
    }
}

enum WearReminderEngine {
    static func report(for equipment: EquipmentProfile) -> EquipmentWearReport {
        let wheelThreshold = wheelThresholdKm(for: equipment)
        let bearingThreshold = bearingThresholdKm(for: equipment)
        let readings = [
            makeReading(
                component: .wheels,
                mileageKm: equipment.wheelSetMileageKm,
                thresholdKm: wheelThreshold
            ),
            makeReading(
                component: .bearings,
                mileageKm: equipment.bearingSetMileageKm,
                thresholdKm: bearingThreshold
            )
        ]
        let overall = readings.map(\.status).reduce(.ok, combine)
        return EquipmentWearReport(
            equipmentID: equipment.id,
            overallStatus: overall,
            readings: readings
        )
    }

    static func wheelThresholdKm(for equipment: EquipmentProfile) -> Double {
        switch equipment.equipmentType {
        case .skateboard:
            return 300
        case .inlineSkates:
            switch equipment.sportMode {
            case .inline(.fitnessSpeed):
                return 300
            case .inline(.aggressive):
                return 200
            case .inline(.urbanFreestyle), .inline(.slalom), .skateboard, .snow:
                return 250
            }
        }
    }

    static func bearingThresholdKm(for equipment: EquipmentProfile) -> Double {
        switch equipment.equipmentType {
        case .skateboard, .inlineSkates:
            return 80
        }
    }

    private static func makeReading(
        component: EquipmentWearComponent,
        mileageKm: Double,
        thresholdKm: Double
    ) -> EquipmentWearReading {
        EquipmentWearReading(
            component: component,
            mileageKm: max(0, mileageKm),
            thresholdKm: thresholdKm,
            status: status(mileageKm: mileageKm, thresholdKm: thresholdKm)
        )
    }

    private static func status(mileageKm: Double, thresholdKm: Double) -> EquipmentWearStatus {
        guard thresholdKm > 0 else { return .ok }
        let ratio = mileageKm / thresholdKm
        if ratio >= 1.0 { return .replaceRecommended }
        if ratio >= 0.75 { return .checkSoon }
        return .ok
    }

    private static func combine(
        _ lhs: EquipmentWearStatus,
        _ rhs: EquipmentWearStatus
    ) -> EquipmentWearStatus {
        if lhs == .replaceRecommended || rhs == .replaceRecommended {
            return .replaceRecommended
        }
        if lhs == .checkSoon || rhs == .checkSoon {
            return .checkSoon
        }
        return .ok
    }
}
