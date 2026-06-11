// [協作區] Shared/Models/EquipmentProfile.swift
// 用途：定義滑板與直排輪裝備檔案、里程、輪組 / 培林磨耗與模式相容性。
// 委派至：equipment manager、wear reminders、session linking 與 macOS gear analysis。

import Foundation

enum EquipmentType: String, Codable, Sendable, CaseIterable, Identifiable {
    case skateboard
    case inlineSkates

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .skateboard:
            return "gear.type.skateboard"
        case .inlineSkates:
            return "gear.type.inline"
        }
    }

    var iconName: String {
        switch self {
        case .skateboard:
            return "figure.skateboarding"
        case .inlineSkates:
            return "figure.walk"
        }
    }

    var defaultSportMode: SportMode {
        switch self {
        case .skateboard:
            return .skateboard(.streetPark)
        case .inlineSkates:
            return .inline(.urbanFreestyle)
        }
    }
}

struct EquipmentProfile: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    var name: String
    var equipmentType: EquipmentType
    var sportMode: SportMode
    var powerType: PowerType
    var purchaseDate: Date?
    var totalDistanceKm: Double
    var wheelSetMileageKm: Double
    var bearingSetMileageKm: Double
    var wheelDiameterMillimeters: Double?
    var wheelHardness: String?
    var bearingABEC: String?
    var brakeType: String?
    var truckTightnessNote: String?
    var riserPadNote: String?
    var bootType: String?
    var frameLengthMillimeters: Double?
    var lastMaintenanceDate: Date?
    var photoLocalIdentifier: String?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        equipmentType: EquipmentType? = nil,
        sportMode: SportMode,
        powerType: PowerType = .humanPowered,
        purchaseDate: Date? = nil,
        totalDistanceKm: Double = 0,
        wheelSetMileageKm: Double = 0,
        bearingSetMileageKm: Double = 0,
        wheelDiameterMillimeters: Double? = nil,
        wheelHardness: String? = nil,
        bearingABEC: String? = nil,
        brakeType: String? = nil,
        truckTightnessNote: String? = nil,
        riserPadNote: String? = nil,
        bootType: String? = nil,
        frameLengthMillimeters: Double? = nil,
        lastMaintenanceDate: Date? = nil,
        photoLocalIdentifier: String? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) throws {
        guard powerType.isValid(for: sportMode) else {
            throw PowerTypeValidationError.electricPowerRequiresSkateboardMode
        }

        let resolvedType = equipmentType ?? Self.inferredEquipmentType(from: sportMode)
        guard resolvedType.isCompatible(with: sportMode) else {
            throw EquipmentProfileValidationError.equipmentTypeDoesNotMatchSportMode
        }

        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.equipmentType = resolvedType
        self.sportMode = sportMode
        self.powerType = powerType
        self.purchaseDate = purchaseDate
        self.totalDistanceKm = max(0, totalDistanceKm)
        self.wheelSetMileageKm = max(0, wheelSetMileageKm)
        self.bearingSetMileageKm = max(0, bearingSetMileageKm)
        self.wheelDiameterMillimeters = wheelDiameterMillimeters
        self.wheelHardness = Self.nilIfBlank(wheelHardness)
        self.bearingABEC = Self.nilIfBlank(bearingABEC)
        self.brakeType = Self.nilIfBlank(brakeType)
        self.truckTightnessNote = Self.nilIfBlank(truckTightnessNote)
        self.riserPadNote = Self.nilIfBlank(riserPadNote)
        self.bootType = Self.nilIfBlank(bootType)
        self.frameLengthMillimeters = frameLengthMillimeters
        self.lastMaintenanceDate = lastMaintenanceDate
        self.photoLocalIdentifier = Self.nilIfBlank(photoLocalIdentifier)
        self.notes = Self.nilIfBlank(notes)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var displayTypeLocalizationKey: String {
        equipmentType.localizationKey
    }

    var isInlineGear: Bool {
        equipmentType == .inlineSkates
    }

    var isSkateboardGear: Bool {
        equipmentType == .skateboard
    }

    static func inferredEquipmentType(from sportMode: SportMode) -> EquipmentType {
        switch sportMode {
        case .skateboard:
            return .skateboard
        case .inline:
            return .inlineSkates
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case equipmentType
        case sportMode
        case powerType
        case purchaseDate
        case totalDistanceKm
        case wheelSetMileageKm
        case bearingSetMileageKm
        case wheelDiameterMillimeters
        case wheelHardness
        case bearingABEC
        case brakeType
        case truckTightnessNote
        case riserPadNote
        case bootType
        case frameLengthMillimeters
        case lastMaintenanceDate
        case photoLocalIdentifier
        case notes
        case createdAt
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedSportMode = try container.decode(SportMode.self, forKey: .sportMode)
        let decodedPowerType = try container.decode(PowerType.self, forKey: .powerType)
        let decodedEquipmentType = try container.decodeIfPresent(EquipmentType.self, forKey: .equipmentType)
            ?? Self.inferredEquipmentType(from: decodedSportMode)

        guard decodedPowerType.isValid(for: decodedSportMode) else {
            throw DecodingError.dataCorruptedError(
                forKey: .powerType,
                in: container,
                debugDescription: "Electric equipment requires a skateboard sport mode."
            )
        }
        guard decodedEquipmentType.isCompatible(with: decodedSportMode) else {
            throw DecodingError.dataCorruptedError(
                forKey: .equipmentType,
                in: container,
                debugDescription: "Equipment type does not match sport mode."
            )
        }

        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        equipmentType = decodedEquipmentType
        sportMode = decodedSportMode
        powerType = decodedPowerType
        purchaseDate = try container.decodeIfPresent(Date.self, forKey: .purchaseDate)
        totalDistanceKm = try container.decodeIfPresent(Double.self, forKey: .totalDistanceKm) ?? 0
        wheelSetMileageKm = try container.decodeIfPresent(Double.self, forKey: .wheelSetMileageKm) ?? 0
        bearingSetMileageKm = try container.decodeIfPresent(Double.self, forKey: .bearingSetMileageKm) ?? 0
        wheelDiameterMillimeters = try container.decodeIfPresent(Double.self, forKey: .wheelDiameterMillimeters)
        wheelHardness = try container.decodeIfPresent(String.self, forKey: .wheelHardness)
        bearingABEC = try container.decodeIfPresent(String.self, forKey: .bearingABEC)
        brakeType = try container.decodeIfPresent(String.self, forKey: .brakeType)
        truckTightnessNote = try container.decodeIfPresent(String.self, forKey: .truckTightnessNote)
        riserPadNote = try container.decodeIfPresent(String.self, forKey: .riserPadNote)
        bootType = try container.decodeIfPresent(String.self, forKey: .bootType)
        frameLengthMillimeters = try container.decodeIfPresent(Double.self, forKey: .frameLengthMillimeters)
        lastMaintenanceDate = try container.decodeIfPresent(Date.self, forKey: .lastMaintenanceDate)
        photoLocalIdentifier = try container.decodeIfPresent(String.self, forKey: .photoLocalIdentifier)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
    }

    private static func nilIfBlank(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed?.isEmpty == false ? trimmed : nil
    }
}

extension EquipmentType {
    func isCompatible(with sportMode: SportMode) -> Bool {
        switch (self, sportMode) {
        case (.skateboard, .skateboard), (.inlineSkates, .inline):
            return true
        case (.skateboard, .inline), (.inlineSkates, .skateboard):
            return false
        }
    }
}

enum EquipmentProfileValidationError: Error, Sendable {
    case equipmentTypeDoesNotMatchSportMode
}
