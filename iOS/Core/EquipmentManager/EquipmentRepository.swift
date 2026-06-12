// [自主區] EquipmentRepository.swift
// 用途：提供裝備檔案本機 CRUD，隱藏 Core Data NSManagedObject 與欄位遷移細節。
// 委派至：useEquipmentManager、Task-020b mileage tracking。

import CoreData
import Foundation

protocol EquipmentRepositoryProtocol: AnyObject, Sendable {
    func fetchEquipment() async throws -> [EquipmentProfile]
    func fetchEquipment(id: UUID) async throws -> EquipmentProfile?
    @discardableResult
    func saveEquipment(_ equipment: EquipmentProfile) async throws -> EquipmentProfile
    func deleteEquipment(id: UUID) async throws
    @discardableResult
    func resetWheelMileage(id: UUID) async throws -> EquipmentProfile
    @discardableResult
    func resetBearingMileage(id: UUID) async throws -> EquipmentProfile
    @discardableResult
    func addMileage(id: UUID, distanceKilometers: Double) async throws -> EquipmentProfile?
}

final class EquipmentRepository: EquipmentRepositoryProtocol, @unchecked Sendable {
    static let shared = EquipmentRepository()

    private let persistenceController: PersistenceController
    private let entityName = "PersistedEquipment"

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    func fetchEquipment() async throws -> [EquipmentProfile] {
        let context = persistenceController.viewContext
        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: self.entityName)
            request.sortDescriptors = [
                NSSortDescriptor(key: "updatedAt", ascending: false),
                NSSortDescriptor(key: "name", ascending: true)
            ]
            return try context.fetch(request).map(self.makeEquipmentProfile)
        }
    }

    func fetchEquipment(id: UUID) async throws -> EquipmentProfile? {
        let context = persistenceController.viewContext
        return try await context.perform {
            guard let object = try self.fetchObject(id: id, in: context) else { return nil }
            return try self.makeEquipmentProfile(from: object)
        }
    }

    @discardableResult
    func saveEquipment(_ equipment: EquipmentProfile) async throws -> EquipmentProfile {
        let context = persistenceController.viewContext
        return try await context.perform {
            let object = try self.fetchObject(id: equipment.id, in: context)
                ?? self.makeObject(in: context)
            let now = Date()
            let existingCreatedAt = object.value(forKey: "createdAt") as? Date
            let profile = try EquipmentProfile(
                id: equipment.id,
                name: equipment.name,
                equipmentType: equipment.equipmentType,
                sportMode: equipment.sportMode,
                powerType: equipment.powerType,
                purchaseDate: equipment.purchaseDate,
                totalDistanceKm: equipment.totalDistanceKm,
                wheelSetMileageKm: equipment.wheelSetMileageKm,
                bearingSetMileageKm: equipment.bearingSetMileageKm,
                wheelDiameterMillimeters: equipment.wheelDiameterMillimeters,
                wheelHardness: equipment.wheelHardness,
                bearingABEC: equipment.bearingABEC,
                brakeType: equipment.brakeType,
                truckTightnessNote: equipment.truckTightnessNote,
                riserPadNote: equipment.riserPadNote,
                bootType: equipment.bootType,
                frameLengthMillimeters: equipment.frameLengthMillimeters,
                lastMaintenanceDate: equipment.lastMaintenanceDate,
                photoLocalIdentifier: equipment.photoLocalIdentifier,
                notes: equipment.notes,
                createdAt: existingCreatedAt ?? equipment.createdAt,
                updatedAt: now
            )

            try self.apply(profile, to: object)
            if context.hasChanges {
                try context.save()
            }
            return profile
        }
    }

    func deleteEquipment(id: UUID) async throws {
        let context = persistenceController.viewContext
        try await context.perform {
            guard let object = try self.fetchObject(id: id, in: context) else { return }
            context.delete(object)
            if context.hasChanges {
                try context.save()
            }
        }
    }

    @discardableResult
    func resetWheelMileage(id: UUID) async throws -> EquipmentProfile {
        try await resetMileage(id: id, wheel: true)
    }

    @discardableResult
    func resetBearingMileage(id: UUID) async throws -> EquipmentProfile {
        try await resetMileage(id: id, wheel: false)
    }

    @discardableResult
    func addMileage(id: UUID, distanceKilometers: Double) async throws -> EquipmentProfile? {
        let safeDistance = max(0, distanceKilometers)
        guard safeDistance > 0 else {
            return try await fetchEquipment(id: id)
        }

        let context = persistenceController.viewContext
        return try await context.perform {
            guard let object = try self.fetchObject(id: id, in: context) else { return nil }
            let now = Date()
            let totalDistance = (self.optionalDouble("totalDistanceKm", from: object) ?? 0) + safeDistance
            let wheelMileage = (self.optionalDouble("wheelSetMileageKm", from: object) ?? 0) + safeDistance
            let bearingMileage = (self.optionalDouble("bearingSetMileageKm", from: object) ?? 0) + safeDistance

            object.setValue(totalDistance, forKey: "totalDistanceKm")
            object.setValue(wheelMileage, forKey: "wheelSetMileageKm")
            object.setValue(bearingMileage, forKey: "bearingSetMileageKm")
            object.setValue(now, forKey: "updatedAt")

            if context.hasChanges {
                try context.save()
            }
            return try self.makeEquipmentProfile(from: object)
        }
    }

    private func resetMileage(id: UUID, wheel: Bool) async throws -> EquipmentProfile {
        let context = persistenceController.viewContext
        return try await context.perform {
            guard let object = try self.fetchObject(id: id, in: context) else {
                throw RepositoryError.decodingFailed
            }
            let now = Date()
            object.setValue(0.0, forKey: wheel ? "wheelSetMileageKm" : "bearingSetMileageKm")
            object.setValue(now, forKey: "lastMaintenanceDate")
            object.setValue(now, forKey: "updatedAt")
            if context.hasChanges {
                try context.save()
            }
            return try self.makeEquipmentProfile(from: object)
        }
    }

    private func fetchObject(id: UUID, in context: NSManagedObjectContext) throws -> NSManagedObject? {
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try context.fetch(request).first
    }

    private func makeObject(in context: NSManagedObjectContext) throws -> NSManagedObject {
        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else {
            throw RepositoryError.persistenceStoreUnavailable
        }
        return NSManagedObject(entity: entity, insertInto: context)
    }

    private func apply(_ profile: EquipmentProfile, to object: NSManagedObject) throws {
        object.setValue(profile.id, forKey: "id")
        object.setValue(profile.name, forKey: "name")
        object.setValue(profile.equipmentType.rawValue, forKey: "equipmentTypeRaw")
        object.setValue(try encode(profile.sportMode), forKey: "sportModeData")
        object.setValue(profile.powerType.rawValue, forKey: "powerTypeRaw")
        object.setValue(profile.purchaseDate, forKey: "purchaseDate")
        object.setValue(profile.totalDistanceKm, forKey: "totalDistanceKm")
        object.setValue(profile.wheelSetMileageKm, forKey: "wheelSetMileageKm")
        object.setValue(profile.bearingSetMileageKm, forKey: "bearingSetMileageKm")
        object.setValue(profile.wheelDiameterMillimeters, forKey: "wheelDiameterMillimeters")
        object.setValue(profile.wheelHardness, forKey: "wheelHardness")
        object.setValue(profile.bearingABEC, forKey: "bearingABEC")
        object.setValue(profile.brakeType, forKey: "brakeType")
        object.setValue(profile.truckTightnessNote, forKey: "truckTightnessNote")
        object.setValue(profile.riserPadNote, forKey: "riserPadNote")
        object.setValue(profile.bootType, forKey: "bootType")
        object.setValue(profile.frameLengthMillimeters, forKey: "frameLengthMillimeters")
        object.setValue(profile.lastMaintenanceDate, forKey: "lastMaintenanceDate")
        object.setValue(profile.photoLocalIdentifier, forKey: "photoLocalIdentifier")
        object.setValue(profile.notes, forKey: "notes")
        object.setValue(profile.createdAt, forKey: "createdAt")
        object.setValue(profile.updatedAt, forKey: "updatedAt")
    }

    private func makeEquipmentProfile(from object: NSManagedObject) throws -> EquipmentProfile {
        let sportModeData: Data = try requiredValue("sportModeData", from: object)
        let sportMode = try decode(SportMode.self, from: sportModeData)
        let powerTypeRaw: String = try requiredValue("powerTypeRaw", from: object)
        guard let powerType = PowerType(rawValue: powerTypeRaw) else {
            throw RepositoryError.decodingFailed
        }
        let equipmentType = EquipmentType(rawValue: object.value(forKey: "equipmentTypeRaw") as? String ?? "")
            ?? EquipmentProfile.inferredEquipmentType(from: sportMode)

        return try EquipmentProfile(
            id: requiredValue("id", from: object),
            name: requiredValue("name", from: object),
            equipmentType: equipmentType,
            sportMode: sportMode,
            powerType: powerType,
            purchaseDate: object.value(forKey: "purchaseDate") as? Date,
            totalDistanceKm: optionalDouble("totalDistanceKm", from: object) ?? 0,
            wheelSetMileageKm: optionalDouble("wheelSetMileageKm", from: object) ?? 0,
            bearingSetMileageKm: optionalDouble("bearingSetMileageKm", from: object) ?? 0,
            wheelDiameterMillimeters: optionalDouble("wheelDiameterMillimeters", from: object),
            wheelHardness: object.value(forKey: "wheelHardness") as? String,
            bearingABEC: object.value(forKey: "bearingABEC") as? String,
            brakeType: object.value(forKey: "brakeType") as? String,
            truckTightnessNote: object.value(forKey: "truckTightnessNote") as? String,
            riserPadNote: object.value(forKey: "riserPadNote") as? String,
            bootType: object.value(forKey: "bootType") as? String,
            frameLengthMillimeters: optionalDouble("frameLengthMillimeters", from: object),
            lastMaintenanceDate: object.value(forKey: "lastMaintenanceDate") as? Date,
            photoLocalIdentifier: object.value(forKey: "photoLocalIdentifier") as? String,
            notes: object.value(forKey: "notes") as? String,
            createdAt: object.value(forKey: "createdAt") as? Date ?? Date(),
            updatedAt: object.value(forKey: "updatedAt") as? Date ?? Date()
        )
    }

    private func encode<T: Encodable>(_ value: T) throws -> Data {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            return try encoder.encode(value)
        } catch {
            throw RepositoryError.encodingFailed
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(type, from: data)
        } catch {
            throw RepositoryError.decodingFailed
        }
    }

    private func requiredValue<T>(_ key: String, from object: NSManagedObject) throws -> T {
        guard let rawValue = object.value(forKey: key) else {
            throw RepositoryError.decodingFailed
        }
        if let value = rawValue as? T { return value }
        if T.self == Double.self, let number = rawValue as? NSNumber {
            return number.doubleValue as! T
        }
        throw RepositoryError.decodingFailed
    }

    private func optionalDouble(_ key: String, from object: NSManagedObject) -> Double? {
        if let value = object.value(forKey: key) as? Double { return value }
        if let number = object.value(forKey: key) as? NSNumber { return number.doubleValue }
        return nil
    }
}
