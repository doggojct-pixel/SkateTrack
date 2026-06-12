// [自主區] SpotRepository.swift
// 用途：提供本機 Spot CRUD、favorite 切換、nearby query 與 Session Visit 紀錄，隱藏 Core Data NSManagedObject 細節。
// 委派至：useSpots、Spot List / Map / Detail UI 與 Task-021b session association。

import CoreData
import Foundation

protocol SpotRepositoryProtocol: AnyObject, Sendable {
    func fetchSpots() async throws -> [SpotProfile]
    func fetchSpot(id: UUID) async throws -> SpotProfile?
    func fetchNearbySpots(center: GeoCoordinate, radiusMeters: Double) async throws -> [SpotProfile]
    func fetchVisits(for spotID: UUID) async throws -> [SpotVisit]
    @discardableResult
    func saveSpot(_ spot: SpotProfile) async throws -> SpotProfile
    func deleteSpot(id: UUID) async throws
    @discardableResult
    func setFavorite(_ isFavorite: Bool, for id: UUID) async throws -> SpotProfile
    @discardableResult
    func recordVisit(_ visit: SpotVisit) async throws -> SpotVisit
}

final class SpotRepository: SpotRepositoryProtocol, @unchecked Sendable {
    static let shared = SpotRepository()

    private let persistenceController: PersistenceController
    private let spotEntityName = "PersistedSpot"
    private let visitEntityName = "PersistedSpotVisit"

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    func fetchSpots() async throws -> [SpotProfile] {
        let context = persistenceController.viewContext
        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: self.spotEntityName)
            request.sortDescriptors = [
                NSSortDescriptor(key: "isFavorite", ascending: false),
                NSSortDescriptor(key: "updatedAt", ascending: false),
                NSSortDescriptor(key: "name", ascending: true)
            ]
            return try context.fetch(request).map(self.makeSpotProfile)
        }
    }

    func fetchSpot(id: UUID) async throws -> SpotProfile? {
        let context = persistenceController.viewContext
        return try await context.perform {
            guard let object = try self.fetchSpotObject(id: id, in: context) else { return nil }
            return try self.makeSpotProfile(from: object)
        }
    }

    func fetchNearbySpots(center: GeoCoordinate, radiusMeters: Double) async throws -> [SpotProfile] {
        let spots = try await fetchSpots()
        return spots.filter { spot in
            guard let coordinate = spot.coordinate else { return false }
            return Self.distanceMeters(from: center, to: coordinate) <= radiusMeters
        }
    }

    func fetchVisits(for spotID: UUID) async throws -> [SpotVisit] {
        let context = persistenceController.viewContext
        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: self.visitEntityName)
            request.predicate = NSPredicate(format: "spotID == %@", spotID as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "visitedAt", ascending: false)]
            return try context.fetch(request).map(self.makeSpotVisit)
        }
    }

    @discardableResult
    func saveSpot(_ spot: SpotProfile) async throws -> SpotProfile {
        let context = persistenceController.viewContext
        return try await context.perform {
            let object = try self.fetchSpotObject(id: spot.id, in: context) ?? self.makeObject(named: self.spotEntityName, in: context)
            let now = Date()
            let existingCreatedAt = object.value(forKey: "createdAt") as? Date
            let profile = SpotProfile(
                id: spot.id,
                name: spot.name,
                coordinate: spot.coordinate,
                radiusMeters: spot.radiusMeters,
                activityFamily: spot.activityFamily,
                surfaceRating: spot.surfaceRating,
                safetyRating: spot.safetyRating,
                crowdLevel: spot.crowdLevel,
                notes: spot.notes,
                isFavorite: spot.isFavorite,
                photoAssetIdentifiers: spot.photoAssetIdentifiers,
                visitCount: spot.visitCount,
                lastVisitedAt: spot.lastVisitedAt,
                preferredSportModes: spot.preferredSportModes,
                createdAt: existingCreatedAt ?? spot.createdAt,
                updatedAt: now
            )
            try self.apply(profile, to: object)
            if context.hasChanges {
                try context.save()
            }
            return profile
        }
    }

    func deleteSpot(id: UUID) async throws {
        let context = persistenceController.viewContext
        try await context.perform {
            guard let object = try self.fetchSpotObject(id: id, in: context) else { return }
            let visits = try self.fetchVisitObjects(spotID: id, in: context)
            visits.forEach(context.delete)
            context.delete(object)
            if context.hasChanges {
                try context.save()
            }
        }
    }

    @discardableResult
    func setFavorite(_ isFavorite: Bool, for id: UUID) async throws -> SpotProfile {
        let context = persistenceController.viewContext
        return try await context.perform {
            guard let object = try self.fetchSpotObject(id: id, in: context) else {
                throw RepositoryError.decodingFailed
            }
            object.setValue(isFavorite, forKey: "isFavorite")
            object.setValue(Date(), forKey: "updatedAt")
            if context.hasChanges {
                try context.save()
            }
            return try self.makeSpotProfile(from: object)
        }
    }

    @discardableResult
    func recordVisit(_ visit: SpotVisit) async throws -> SpotVisit {
        let context = persistenceController.viewContext
        return try await context.perform {
            if let existingVisit = try self.fetchVisitObject(sessionID: visit.sessionID, in: context) {
                return try self.makeSpotVisit(from: existingVisit)
            }
            guard let spotObject = try self.fetchSpotObject(id: visit.spotID, in: context) else {
                throw RepositoryError.decodingFailed
            }

            let storedVisit = SpotVisit(
                id: visit.id,
                spotID: visit.spotID,
                sessionID: visit.sessionID,
                visitedAt: visit.visitedAt,
                distanceKilometers: visit.distanceKilometers,
                confidence: visit.confidence
            )
            let visitObject = try self.makeObject(named: self.visitEntityName, in: context)
            try self.apply(storedVisit, toVisitObject: visitObject)
            self.applyVisitSummary(storedVisit, to: spotObject)

            if context.hasChanges {
                try context.save()
            }
            return storedVisit
        }
    }

    private func fetchSpotObject(id: UUID, in context: NSManagedObjectContext) throws -> NSManagedObject? {
        let request = NSFetchRequest<NSManagedObject>(entityName: spotEntityName)
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try context.fetch(request).first
    }

    private func fetchVisitObject(sessionID: UUID, in context: NSManagedObjectContext) throws -> NSManagedObject? {
        let request = NSFetchRequest<NSManagedObject>(entityName: visitEntityName)
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "sessionID == %@", sessionID as CVarArg)
        return try context.fetch(request).first
    }

    private func fetchVisitObjects(spotID: UUID, in context: NSManagedObjectContext) throws -> [NSManagedObject] {
        let request = NSFetchRequest<NSManagedObject>(entityName: visitEntityName)
        request.predicate = NSPredicate(format: "spotID == %@", spotID as CVarArg)
        return try context.fetch(request)
    }

    private func makeObject(named entityName: String, in context: NSManagedObjectContext) throws -> NSManagedObject {
        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else {
            throw RepositoryError.persistenceStoreUnavailable
        }
        return NSManagedObject(entity: entity, insertInto: context)
    }

    private func apply(_ spot: SpotProfile, to object: NSManagedObject) throws {
        object.setValue(spot.id, forKey: "id")
        object.setValue(spot.name, forKey: "name")
        object.setValue(spot.coordinate?.latitude, forKey: "latitude")
        object.setValue(spot.coordinate?.longitude, forKey: "longitude")
        object.setValue(spot.radiusMeters, forKey: "radiusMeters")
        object.setValue(spot.activityFamily.rawValue, forKey: "activityFamilyRaw")
        object.setValue(spot.surfaceRating?.rawValue, forKey: "surfaceRatingRaw")
        object.setValue(spot.safetyRating, forKey: "safetyRating")
        object.setValue(spot.crowdLevel.rawValue, forKey: "crowdLevelRaw")
        object.setValue(spot.notes, forKey: "notes")
        object.setValue(spot.isFavorite, forKey: "isFavorite")
        object.setValue(try encode(spot.photoAssetIdentifiers), forKey: "photoAssetIdentifiersData")
        object.setValue(spot.visitCount, forKey: "visitCount")
        object.setValue(spot.lastVisitedAt, forKey: "lastVisitedAt")
        object.setValue(try encode(spot.preferredSportModes), forKey: "preferredSportModesData")
        object.setValue(spot.createdAt, forKey: "createdAt")
        object.setValue(spot.updatedAt, forKey: "updatedAt")
    }

    private func apply(_ visit: SpotVisit, toVisitObject object: NSManagedObject) throws {
        object.setValue(visit.id, forKey: "id")
        object.setValue(visit.spotID, forKey: "spotID")
        object.setValue(visit.sessionID, forKey: "sessionID")
        object.setValue(visit.visitedAt, forKey: "visitedAt")
        object.setValue(visit.distanceKilometers, forKey: "distanceKilometers")
        object.setValue(visit.confidence, forKey: "confidence")
    }

    private func applyVisitSummary(_ visit: SpotVisit, to spotObject: NSManagedObject) {
        let existingCount = optionalInt("visitCount", from: spotObject) ?? 0
        spotObject.setValue(existingCount + 1, forKey: "visitCount")
        spotObject.setValue(visit.visitedAt, forKey: "lastVisitedAt")
        spotObject.setValue(Date(), forKey: "updatedAt")
    }

    private func makeSpotProfile(from object: NSManagedObject) throws -> SpotProfile {
        let latitude = optionalDouble("latitude", from: object)
        let longitude = optionalDouble("longitude", from: object)
        let coordinate: GeoCoordinate?
        if let latitude, let longitude {
            coordinate = GeoCoordinate(latitude: latitude, longitude: longitude)
        } else {
            coordinate = nil
        }
        let photoData = object.value(forKey: "photoAssetIdentifiersData") as? Data
        let sportModesData = object.value(forKey: "preferredSportModesData") as? Data
        let surfaceRating = optionalInt("surfaceRatingRaw", from: object).flatMap(SurfaceRating.init(rawValue:))

        return SpotProfile(
            id: try requiredValue("id", from: object),
            name: try requiredValue("name", from: object),
            coordinate: coordinate,
            radiusMeters: optionalDouble("radiusMeters", from: object) ?? 120,
            activityFamily: SpotActivityFamily(rawValue: object.value(forKey: "activityFamilyRaw") as? String ?? "") ?? .mixed,
            surfaceRating: surfaceRating,
            safetyRating: optionalInt("safetyRating", from: object),
            crowdLevel: SpotCrowdLevel(rawValue: object.value(forKey: "crowdLevelRaw") as? String ?? "") ?? .unknown,
            notes: object.value(forKey: "notes") as? String,
            isFavorite: optionalBool("isFavorite", from: object) ?? false,
            photoAssetIdentifiers: try photoData.map { try decode([String].self, from: $0) } ?? [],
            visitCount: optionalInt("visitCount", from: object) ?? 0,
            lastVisitedAt: object.value(forKey: "lastVisitedAt") as? Date,
            preferredSportModes: try sportModesData.map { try decode([SportMode].self, from: $0) } ?? [],
            createdAt: object.value(forKey: "createdAt") as? Date ?? Date(),
            updatedAt: object.value(forKey: "updatedAt") as? Date ?? Date()
        )
    }

    private func makeSpotVisit(from object: NSManagedObject) throws -> SpotVisit {
        SpotVisit(
            id: try requiredValue("id", from: object),
            spotID: try requiredValue("spotID", from: object),
            sessionID: try requiredValue("sessionID", from: object),
            visitedAt: try requiredValue("visitedAt", from: object),
            distanceKilometers: optionalDouble("distanceKilometers", from: object) ?? 0,
            confidence: optionalDouble("confidence", from: object) ?? 0
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
        guard let rawValue = object.value(forKey: key) else { throw RepositoryError.decodingFailed }
        if let value = rawValue as? T { return value }
        if T.self == Double.self, let number = rawValue as? NSNumber { return number.doubleValue as! T }
        if T.self == Int.self, let number = rawValue as? NSNumber { return number.intValue as! T }
        throw RepositoryError.decodingFailed
    }

    private func optionalDouble(_ key: String, from object: NSManagedObject) -> Double? {
        if let value = object.value(forKey: key) as? Double { return value }
        if let number = object.value(forKey: key) as? NSNumber { return number.doubleValue }
        return nil
    }

    private func optionalInt(_ key: String, from object: NSManagedObject) -> Int? {
        if let value = object.value(forKey: key) as? Int { return value }
        if let number = object.value(forKey: key) as? NSNumber { return number.intValue }
        return nil
    }

    private func optionalBool(_ key: String, from object: NSManagedObject) -> Bool? {
        if let value = object.value(forKey: key) as? Bool { return value }
        if let number = object.value(forKey: key) as? NSNumber { return number.boolValue }
        return nil
    }

    private static func distanceMeters(from origin: GeoCoordinate, to destination: GeoCoordinate) -> Double {
        let earthRadiusMeters = 6_371_000.0
        let deltaLatitude = (destination.latitude - origin.latitude) * .pi / 180
        let deltaLongitude = (destination.longitude - origin.longitude) * .pi / 180
        let originLatitude = origin.latitude * .pi / 180
        let destinationLatitude = destination.latitude * .pi / 180
        let a = sin(deltaLatitude / 2) * sin(deltaLatitude / 2)
            + cos(originLatitude) * cos(destinationLatitude)
            * sin(deltaLongitude / 2) * sin(deltaLongitude / 2)
        return earthRadiusMeters * 2 * atan2(sqrt(a), sqrt(1 - a))
    }
}
