// [協作區] Shared/Models/EquipmentProfile.swift
// 用途：定義滑板與直排輪裝備檔案、里程、輪組磨耗與模式相容性。
// 委派至：equipment manager、wear reminders、session linking 與 macOS gear analysis。

import Foundation

struct EquipmentProfile: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    var name: String
    var sportMode: SportMode
    var powerType: PowerType
    var purchaseDate: Date?
    var totalDistanceKm: Double
    var wheelSetMileageKm: Double
    var wheelDiameterMillimeters: Double?
    var wheelHardness: String?
    var notes: String?

    init(
        id: UUID = UUID(),
        name: String,
        sportMode: SportMode,
        powerType: PowerType = .humanPowered,
        purchaseDate: Date? = nil,
        totalDistanceKm: Double = 0,
        wheelSetMileageKm: Double = 0,
        wheelDiameterMillimeters: Double? = nil,
        wheelHardness: String? = nil,
        notes: String? = nil
    ) throws {
        guard powerType.isValid(for: sportMode) else {
            throw PowerTypeValidationError.electricPowerRequiresSkateboardMode
        }

        self.id = id
        self.name = name
        self.sportMode = sportMode
        self.powerType = powerType
        self.purchaseDate = purchaseDate
        self.totalDistanceKm = totalDistanceKm
        self.wheelSetMileageKm = wheelSetMileageKm
        self.wheelDiameterMillimeters = wheelDiameterMillimeters
        self.wheelHardness = wheelHardness
        self.notes = notes
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case sportMode
        case powerType
        case purchaseDate
        case totalDistanceKm
        case wheelSetMileageKm
        case wheelDiameterMillimeters
        case wheelHardness
        case notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedSportMode = try container.decode(SportMode.self, forKey: .sportMode)
        let decodedPowerType = try container.decode(PowerType.self, forKey: .powerType)

        guard decodedPowerType.isValid(for: decodedSportMode) else {
            throw DecodingError.dataCorruptedError(
                forKey: .powerType,
                in: container,
                debugDescription: "Electric equipment requires a skateboard sport mode."
            )
        }

        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        sportMode = decodedSportMode
        powerType = decodedPowerType
        purchaseDate = try container.decodeIfPresent(Date.self, forKey: .purchaseDate)
        totalDistanceKm = try container.decode(Double.self, forKey: .totalDistanceKm)
        wheelSetMileageKm = try container.decode(Double.self, forKey: .wheelSetMileageKm)
        wheelDiameterMillimeters = try container.decodeIfPresent(Double.self, forKey: .wheelDiameterMillimeters)
        wheelHardness = try container.decodeIfPresent(String.self, forKey: .wheelHardness)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }
}
