// [自主區] Shared/Persistence/PersistenceController.swift
// 用途：提供 SkateTrack 本機 Core Data stack，Task-015a 先以程式化 model 保證可測試與可遷移。
// 委派至：SessionRepository，不直接暴露 NSManagedObject 給 UI。

import CoreData
import Foundation

final class PersistenceController {
    static let modelName = "SkateTrackDataModel"
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    init(inMemory: Bool = false, storeURL: URL? = nil) {
        let model = Self.makeManagedObjectModel()
        container = NSPersistentContainer(name: Self.modelName, managedObjectModel: model)

        let description = NSPersistentStoreDescription()
        if inMemory {
            description.type = NSInMemoryStoreType
            description.url = URL(fileURLWithPath: "/dev/null")
        } else if let storeURL {
            description.url = storeURL
        } else {
            description.url = Self.defaultStoreURL()
        }
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        if let parentDirectory = description.url?.deletingLastPathComponent() {
            try? FileManager.default.createDirectory(at: parentDirectory, withIntermediateDirectories: true)
        }
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            if let error {
                assertionFailure("SkateTrack Core Data store failed to load: \(error.localizedDescription)")
            }
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    static func defaultStoreURL() -> URL {
        let supportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let appDirectory = supportDirectory.appendingPathComponent("SkateTrack", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        return appDirectory.appendingPathComponent("SkateTrack.sqlite")
    }

    static func makeManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        model.entities = [
            makePersistedSessionEntity(),
            makePersistedFallEventEntity(),
            makePersistedEquipmentEntity(),
            makePersistedSpotEntity()
        ]
        return model
    }

    private static func makePersistedSessionEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "PersistedSession"
        entity.managedObjectClassName = "NSManagedObject"
        entity.properties = [
            uuidAttribute("id", optional: false),
            dateAttribute("startDate", optional: false),
            dateAttribute("endDate", optional: true),
            binaryAttribute("sportModeData", optional: false),
            stringAttribute("powerTypeRaw", optional: false),
            doubleAttribute("distanceKilometers"),
            doubleAttribute("maxSpeedKilometersPerHour"),
            doubleAttribute("averageSpeedKilometersPerHour"),
            doubleAttribute("elevationGainMeters"),
            doubleAttribute("movingRatio"),
            uuidAttribute("equipmentID", optional: true),
            binaryAttribute("equipmentSnapshotData", optional: true),
            uuidAttribute("spotID", optional: true),
            stringAttribute("sampleFileName", optional: true),
            binaryAttribute("trickEventsData", optional: false),
            dateAttribute("createdAt", optional: false),
            dateAttribute("updatedAt", optional: false)
        ]
        return entity
    }

    private static func makePersistedFallEventEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "PersistedFallEvent"
        entity.managedObjectClassName = "NSManagedObject"
        entity.properties = [
            uuidAttribute("id", optional: false),
            uuidAttribute("sessionID", optional: false),
            dateAttribute("timestamp", optional: false),
            doubleAttribute("peakImpactGForce"),
            doubleAttribute("latitude", optional: true),
            doubleAttribute("longitude", optional: true),
            doubleAttribute("recoveryDurationSeconds", optional: true),
            binaryAttribute("sportModeData", optional: true),
            boolAttribute("userConfirmed")
        ]
        return entity
    }

    private static func makePersistedEquipmentEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "PersistedEquipment"
        entity.managedObjectClassName = "NSManagedObject"
        entity.properties = [
            uuidAttribute("id", optional: false),
            stringAttribute("name", optional: false),
            stringAttribute("equipmentTypeRaw", optional: true),
            binaryAttribute("sportModeData", optional: false),
            stringAttribute("powerTypeRaw", optional: false),
            dateAttribute("purchaseDate", optional: true),
            doubleAttribute("totalDistanceKm"),
            doubleAttribute("wheelSetMileageKm"),
            doubleAttribute("bearingSetMileageKm", optional: true),
            doubleAttribute("wheelDiameterMillimeters", optional: true),
            stringAttribute("wheelHardness", optional: true),
            stringAttribute("bearingABEC", optional: true),
            stringAttribute("brakeType", optional: true),
            stringAttribute("truckTightnessNote", optional: true),
            stringAttribute("riserPadNote", optional: true),
            stringAttribute("bootType", optional: true),
            doubleAttribute("frameLengthMillimeters", optional: true),
            dateAttribute("lastMaintenanceDate", optional: true),
            stringAttribute("photoLocalIdentifier", optional: true),
            stringAttribute("notes", optional: true),
            dateAttribute("createdAt", optional: true),
            dateAttribute("updatedAt", optional: true)
        ]
        return entity
    }

    private static func makePersistedSpotEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "PersistedSpot"
        entity.managedObjectClassName = "NSManagedObject"
        entity.properties = [
            uuidAttribute("id", optional: false),
            stringAttribute("name", optional: false),
            doubleAttribute("latitude", optional: true),
            doubleAttribute("longitude", optional: true),
            intAttribute("surfaceRatingRaw", optional: true),
            stringAttribute("notes", optional: true),
            binaryAttribute("photoAssetIdentifiersData", optional: false),
            intAttribute("visitCount"),
            dateAttribute("lastVisitedAt", optional: true),
            binaryAttribute("preferredSportModesData", optional: false)
        ]
        return entity
    }

    private static func uuidAttribute(_ name: String, optional: Bool) -> NSAttributeDescription {
        attribute(name, type: .UUIDAttributeType, optional: optional)
    }

    private static func dateAttribute(_ name: String, optional: Bool) -> NSAttributeDescription {
        attribute(name, type: .dateAttributeType, optional: optional)
    }

    private static func stringAttribute(_ name: String, optional: Bool) -> NSAttributeDescription {
        attribute(name, type: .stringAttributeType, optional: optional)
    }

    private static func binaryAttribute(_ name: String, optional: Bool) -> NSAttributeDescription {
        attribute(name, type: .binaryDataAttributeType, optional: optional)
    }

    private static func doubleAttribute(_ name: String, optional: Bool = false) -> NSAttributeDescription {
        attribute(name, type: .doubleAttributeType, optional: optional)
    }

    private static func intAttribute(_ name: String, optional: Bool = false) -> NSAttributeDescription {
        attribute(name, type: .integer64AttributeType, optional: optional)
    }

    private static func boolAttribute(_ name: String) -> NSAttributeDescription {
        attribute(name, type: .booleanAttributeType, optional: false)
    }

    private static func attribute(
        _ name: String,
        type: NSAttributeType,
        optional: Bool
    ) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = optional
        return attribute
    }
}
