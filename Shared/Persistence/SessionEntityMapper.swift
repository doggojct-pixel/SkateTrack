// [自主區] Shared/Persistence/SessionEntityMapper.swift
// 用途：集中 SessionData / FallEvent 與 Core Data NSManagedObject 的轉換，避免 UI 直接碰 Core Data。
// 委派至：SessionRepository、FallEventRepository、Task-015b recording integration。

import CoreData
import Foundation

enum SessionEntityMapper {
    static let sessionEntityName = "PersistedSession"
    static let fallEventEntityName = "PersistedFallEvent"

    static func upsertSession(
        _ session: SessionData,
        sampleFileName: String?,
        in context: NSManagedObjectContext
    ) throws {
        let object = try fetchSessionObject(id: session.id, in: context)
            ?? makeObject(named: sessionEntityName, in: context)
        let now = Date()
        let summary = session.summaryMetrics ?? .zero

        object.setValue(session.id, forKey: "id")
        object.setValue(session.startDate, forKey: "startDate")
        object.setValue(session.endDate, forKey: "endDate")
        object.setValue(try encode(session.sportMode), forKey: "sportModeData")
        object.setValue(session.powerType.rawValue, forKey: "powerTypeRaw")
        object.setValue(summary.distanceKilometers, forKey: "distanceKilometers")
        object.setValue(summary.maxSpeedKilometersPerHour, forKey: "maxSpeedKilometersPerHour")
        object.setValue(summary.averageSpeedKilometersPerHour, forKey: "averageSpeedKilometersPerHour")
        object.setValue(summary.elevationGainMeters, forKey: "elevationGainMeters")
        object.setValue(summary.movingRatio, forKey: "movingRatio")
        object.setValue(session.equipmentID, forKey: "equipmentID")
        object.setValue(try session.equipmentSnapshot.map { try encode($0) }, forKey: "equipmentSnapshotData")
        object.setValue(session.spotID, forKey: "spotID")
        object.setValue(sampleFileName, forKey: "sampleFileName")
        object.setValue(try encode(session.trickEvents), forKey: "trickEventsData")
        object.setValue(object.value(forKey: "createdAt") as? Date ?? now, forKey: "createdAt")
        object.setValue(now, forKey: "updatedAt")

        try deleteFallEvents(sessionID: session.id, in: context)
        try session.fallEvents.forEach { fallEvent in
            try makeFallEventObject(fallEvent, sessionID: session.id, in: context)
        }
    }

    static func makeSessionData(
        from object: NSManagedObject,
        motionSamples: [MotionSample],
        fallEvents: [FallEvent]
    ) throws -> SessionData {
        let sportModeData: Data = try requiredValue("sportModeData", from: object)
        let powerTypeRaw: String = try requiredValue("powerTypeRaw", from: object)
        let trickEventsData: Data = try requiredValue("trickEventsData", from: object)

        guard let powerType = PowerType(rawValue: powerTypeRaw) else {
            throw RepositoryError.decodingFailed
        }

        let summary = SessionSummaryMetrics(
            distanceKilometers: try requiredValue("distanceKilometers", from: object),
            maxSpeedKilometersPerHour: try requiredValue("maxSpeedKilometersPerHour", from: object),
            averageSpeedKilometersPerHour: try requiredValue("averageSpeedKilometersPerHour", from: object),
            elevationGainMeters: try requiredValue("elevationGainMeters", from: object),
            movingRatio: try requiredValue("movingRatio", from: object)
        )

        return try SessionData(
            id: requiredValue("id", from: object),
            startDate: requiredValue("startDate", from: object),
            endDate: object.value(forKey: "endDate") as? Date,
            sportMode: decode(SportMode.self, from: sportModeData),
            powerType: powerType,
            motionSamples: motionSamples,
            trickEvents: decode([TrickEvent].self, from: trickEventsData),
            fallEvents: fallEvents,
            summaryMetrics: summary,
            equipmentID: object.value(forKey: "equipmentID") as? UUID,
            equipmentSnapshot: try (object.value(forKey: "equipmentSnapshotData") as? Data).map {
                try decode(EquipmentSessionSnapshot.self, from: $0)
            },
            spotID: object.value(forKey: "spotID") as? UUID
        )
    }

    static func makeFallEvent(from object: NSManagedObject) throws -> FallEvent {
        let latitude = optionalDouble("latitude", from: object)
        let longitude = optionalDouble("longitude", from: object)
        let coordinate: GeoCoordinate?
        if let latitude, let longitude {
            coordinate = GeoCoordinate(latitude: latitude, longitude: longitude)
        } else {
            coordinate = nil
        }

        let sportModeData = object.value(forKey: "sportModeData") as? Data
        return FallEvent(
            id: try requiredValue("id", from: object),
            timestamp: try requiredValue("timestamp", from: object),
            peakImpactGForce: try requiredValue("peakImpactGForce", from: object),
            locationCoordinate: coordinate,
            recoveryDurationSeconds: optionalDouble("recoveryDurationSeconds", from: object),
            sportMode: try sportModeData.map { try decode(SportMode.self, from: $0) },
            userConfirmed: try requiredValue("userConfirmed", from: object)
        )
    }

    static func fetchSessionObject(id: UUID, in context: NSManagedObjectContext) throws -> NSManagedObject? {
        let request = NSFetchRequest<NSManagedObject>(entityName: sessionEntityName)
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try context.fetch(request).first
    }

    static func fetchRecentSessionObjects(
        limit: Int,
        in context: NSManagedObjectContext
    ) throws -> [NSManagedObject] {
        let request = NSFetchRequest<NSManagedObject>(entityName: sessionEntityName)
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        request.fetchLimit = max(limit, 1)
        return try context.fetch(request)
    }

    static func fetchFallEventObjects(sessionID: UUID, in context: NSManagedObjectContext) throws -> [NSManagedObject] {
        let request = NSFetchRequest<NSManagedObject>(entityName: fallEventEntityName)
        request.predicate = NSPredicate(format: "sessionID == %@", sessionID as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        return try context.fetch(request)
    }

    static func sampleFileName(from object: NSManagedObject) -> String? {
        object.value(forKey: "sampleFileName") as? String
    }

    private static func makeFallEventObject(
        _ fallEvent: FallEvent,
        sessionID: UUID,
        in context: NSManagedObjectContext
    ) throws {
        let object = try makeObject(named: fallEventEntityName, in: context)
        object.setValue(fallEvent.id, forKey: "id")
        object.setValue(sessionID, forKey: "sessionID")
        object.setValue(fallEvent.timestamp, forKey: "timestamp")
        object.setValue(fallEvent.peakImpactGForce, forKey: "peakImpactGForce")
        object.setValue(fallEvent.locationCoordinate?.latitude, forKey: "latitude")
        object.setValue(fallEvent.locationCoordinate?.longitude, forKey: "longitude")
        object.setValue(fallEvent.recoveryDurationSeconds, forKey: "recoveryDurationSeconds")
        object.setValue(try fallEvent.sportMode.map { try encode($0) }, forKey: "sportModeData")
        object.setValue(fallEvent.userConfirmed, forKey: "userConfirmed")
    }

    private static func deleteFallEvents(sessionID: UUID, in context: NSManagedObjectContext) throws {
        let existingEvents = try fetchFallEventObjects(sessionID: sessionID, in: context)
        existingEvents.forEach(context.delete)
    }

    private static func makeObject(named entityName: String, in context: NSManagedObjectContext) throws -> NSManagedObject {
        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else {
            throw RepositoryError.persistenceStoreUnavailable
        }
        return NSManagedObject(entity: entity, insertInto: context)
    }

    private static func encode<T: Encodable>(_ value: T) throws -> Data {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            return try encoder.encode(value)
        } catch {
            throw RepositoryError.encodingFailed
        }
    }

    private static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(type, from: data)
        } catch {
            throw RepositoryError.decodingFailed
        }
    }

    static func requiredValue<T>(_ key: String, from object: NSManagedObject) throws -> T {
        guard let rawValue = object.value(forKey: key) else {
            throw RepositoryError.decodingFailed
        }
        if let value = rawValue as? T {
            return value
        }
        if T.self == Double.self, let number = rawValue as? NSNumber {
            return number.doubleValue as! T
        }
        if T.self == Bool.self, let number = rawValue as? NSNumber {
            return number.boolValue as! T
        }
        if T.self == Int64.self, let number = rawValue as? NSNumber {
            return number.int64Value as! T
        }
        throw RepositoryError.decodingFailed
    }

    private static func optionalDouble(_ key: String, from object: NSManagedObject) -> Double? {
        if let value = object.value(forKey: key) as? Double {
            return value
        }
        if let number = object.value(forKey: key) as? NSNumber {
            return number.doubleValue
        }
        return nil
    }
}
