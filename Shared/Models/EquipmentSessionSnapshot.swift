// [協作區] Shared/Models/EquipmentSessionSnapshot.swift
// 用途：保存 Session 當下的裝備歸屬快照，讓歷史紀錄不依賴仍存在的裝備資料。
// 委派至：SessionData、SessionEntityMapper、History、Summary 與未來 export/report。

import Foundation

struct EquipmentSessionSnapshot: Codable, Sendable, Equatable {
    let equipmentID: UUID
    let name: String
    let equipmentType: EquipmentType
    let sportMode: SportMode
    let powerType: PowerType
    let archivedAt: Date

    init(
        equipmentID: UUID,
        name: String,
        equipmentType: EquipmentType,
        sportMode: SportMode,
        powerType: PowerType,
        archivedAt: Date = Date()
    ) {
        self.equipmentID = equipmentID
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.equipmentType = equipmentType
        self.sportMode = sportMode
        self.powerType = powerType
        self.archivedAt = archivedAt
    }

    init(equipment: EquipmentProfile, archivedAt: Date = Date()) {
        self.init(
            equipmentID: equipment.id,
            name: equipment.name,
            equipmentType: equipment.equipmentType,
            sportMode: equipment.sportMode,
            powerType: equipment.powerType,
            archivedAt: archivedAt
        )
    }

    var displayName: String {
        name.isEmpty ? NSLocalizedString("gear.snapshot.untitled", comment: "") : name
    }
}
