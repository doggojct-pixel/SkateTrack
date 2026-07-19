// [協作區 — 邊界適配層] Shared/Persistence/SnowSessionEntityMapper.swift
// 用途：轉換 SnowRun / SnowSegment 與 Core Data NSManagedObject，避免 UI 直接依賴 Core Data。
// 委派至：SnowSessionRepository、Snow-Task-003/004 classifier pipeline、Snow UI 與 package compatibility。

import CoreData
import Foundation

enum SnowSessionEntityMapper {
    static let snowRunEntityName = "PersistedSnowRun"
    static let snowSegmentEntityName = "PersistedSnowSegment"

    static func upsertRun(_ run: SnowRun, in context: NSManagedObjectContext) throws {
        let object = try fetchRunObject(id: run.id, in: context)
            ?? makeObject(named: snowRunEntityName, in: context)
        let now = Date()

        object.setValue(run.id, forKey: "id")
        object.setValue(run.sessionID, forKey: "sessionID")
        object.setValue(Int64(run.runNumber), forKey: "runNumber")
        object.setValue(run.startDate, forKey: "startDate")
        object.setValue(run.endDate, forKey: "endDate")
        object.setValue(run.skiDistanceMeters, forKey: "skiDistanceMeters")
        object.setValue(run.verticalDropMeters, forKey: "verticalDropMeters")
        object.setValue(run.topSpeedMetersPerSecond, forKey: "topSpeedMetersPerSecond")
        object.setValue(run.averageSpeedMetersPerSecond, forKey: "averageSpeedMetersPerSecond")
        object.setValue(try encode(run.segmentIDs), forKey: "segmentIDsData")
        object.setValue(run.isManualEnd, forKey: "isManualEnd")
        object.setValue(object.value(forKey: "createdAt") as? Date ?? now, forKey: "createdAt")
        object.setValue(now, forKey: "updatedAt")
    }

    static func upsertSegment(_ segment: SnowSegment, in context: NSManagedObjectContext) throws {
        let object = try fetchSegmentObject(id: segment.id, in: context)
            ?? makeObject(named: snowSegmentEntityName, in: context)
        let now = Date()

        object.setValue(segment.id, forKey: "id")
        object.setValue(segment.sessionID, forKey: "sessionID")
        object.setValue(segment.runID, forKey: "runID")
        object.setValue(segment.type.rawValue, forKey: "typeRaw")
        object.setValue(segment.startDate, forKey: "startDate")
        object.setValue(segment.endDate, forKey: "endDate")
        object.setValue(segment.distanceMeters, forKey: "distanceMeters")
        object.setValue(segment.verticalDeltaMeters, forKey: "verticalDeltaMeters")
        object.setValue(segment.startAltitudeMeters, forKey: "startAltitudeMeters")
        object.setValue(segment.endAltitudeMeters, forKey: "endAltitudeMeters")
        object.setValue(segment.averageSpeedMetersPerSecond, forKey: "averageSpeedMetersPerSecond")
        object.setValue(segment.maxSpeedMetersPerSecond, forKey: "maxSpeedMetersPerSecond")
        object.setValue(segment.confidence, forKey: "confidence")
        object.setValue(segment.countsTowardSkiDistance, forKey: "countsTowardSkiDistance")
        object.setValue(segment.manualOverride, forKey: "manualOverride")
        object.setValue(try encode(segment.sourceSampleIDs), forKey: "sourceSampleIDsData")
        object.setValue(object.value(forKey: "createdAt") as? Date ?? now, forKey: "createdAt")
        object.setValue(now, forKey: "updatedAt")
    }

    static func makeRun(from object: NSManagedObject) throws -> SnowRun {
        let segmentIDsData: Data = try requiredValue("segmentIDsData", from: object)
        return SnowRun(
            id: try requiredValue("id", from: object),
            sessionID: try requiredValue("sessionID", from: object),
            runNumber: Int(try requiredInt64("runNumber", from: object)),
            startDate: try requiredValue("startDate", from: object),
            endDate: object.value(forKey: "endDate") as? Date,
            skiDistanceMeters: try requiredDouble("skiDistanceMeters", from: object),
            verticalDropMeters: try requiredDouble("verticalDropMeters", from: object),
            topSpeedMetersPerSecond: try requiredDouble("topSpeedMetersPerSecond", from: object),
            averageSpeedMetersPerSecond: optionalDouble("averageSpeedMetersPerSecond", from: object),
            segmentIDs: try decode([UUID].self, from: segmentIDsData),
            isManualEnd: try requiredBool("isManualEnd", from: object)
        )
    }

    static func makeSegment(from object: NSManagedObject) throws -> SnowSegment {
        let typeRaw: String = try requiredValue("typeRaw", from: object)
        guard let type = SnowSegmentType(rawValue: typeRaw) else {
            throw RepositoryError.decodingFailed
        }
        let sourceSampleIDsData = object.value(forKey: "sourceSampleIDsData") as? Data
        let sourceSampleIDs = try sourceSampleIDsData.map { try decode([UUID].self, from: $0) } ?? []

        return SnowSegment(
            id: try requiredValue("id", from: object),
            sessionID: try requiredValue("sessionID", from: object),
            runID: object.value(forKey: "runID") as? UUID,
            type: type,
            startDate: try requiredValue("startDate", from: object),
            endDate: object.value(forKey: "endDate") as? Date,
            distanceMeters: try requiredDouble("distanceMeters", from: object),
            verticalDeltaMeters: optionalDouble("verticalDeltaMeters", from: object),
            startAltitudeMeters: optionalDouble("startAltitudeMeters", from: object),
            endAltitudeMeters: optionalDouble("endAltitudeMeters", from: object),
            averageSpeedMetersPerSecond: optionalDouble("averageSpeedMetersPerSecond", from: object),
            maxSpeedMetersPerSecond: optionalDouble("maxSpeedMetersPerSecond", from: object),
            confidence: try requiredDouble("confidence", from: object),
            countsTowardSkiDistance: try requiredBool("countsTowardSkiDistance", from: object),
            manualOverride: optionalBool("manualOverride", from: object),
            sourceSampleIDs: sourceSampleIDs
        )
    }

    static func fetchRunObject(id: UUID, in context: NSManagedObjectContext) throws -> NSManagedObject? {
        let request = NSFetchRequest<NSManagedObject>(entityName: snowRunEntityName)
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try context.fetch(request).first
    }

    static func fetchSegmentObject(id: UUID, in context: NSManagedObjectContext) throws -> NSManagedObject? {
        let request = NSFetchRequest<NSManagedObject>(entityName: snowSegmentEntityName)
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try context.fetch(request).first
    }

    static func fetchRunObjects(sessionID: UUID, in context: NSManagedObjectContext) throws -> [NSManagedObject] {
        let request = NSFetchRequest<NSManagedObject>(entityName: snowRunEntityName)
        request.predicate = NSPredicate(format: "sessionID == %@", sessionID as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "runNumber", ascending: true)]
        return try context.fetch(request)
    }

    static func fetchSegmentObjects(sessionID: UUID, in context: NSManagedObjectContext) throws -> [NSManagedObject] {
        let request = NSFetchRequest<NSManagedObject>(entityName: snowSegmentEntityName)
        request.predicate = NSPredicate(format: "sessionID == %@", sessionID as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true)]
        return try context.fetch(request)
    }

    static func fetchSegmentObjects(runID: UUID, in context: NSManagedObjectContext) throws -> [NSManagedObject] {
        let request = NSFetchRequest<NSManagedObject>(entityName: snowSegmentEntityName)
        request.predicate = NSPredicate(format: "runID == %@", runID as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true)]
        return try context.fetch(request)
    }

    static func deleteSnowObjects(sessionID: UUID, in context: NSManagedObjectContext) throws {
        let runs = try fetchRunObjects(sessionID: sessionID, in: context)
        let segments = try fetchSegmentObjects(sessionID: sessionID, in: context)
        runs.forEach(context.delete)
        segments.forEach(context.delete)
    }

    static func makeObject(named entityName: String, in context: NSManagedObjectContext) throws -> NSManagedObject {
        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else {
            throw RepositoryError.persistenceStoreUnavailable
        }
        return NSManagedObject(entity: entity, insertInto: context)
    }

    static func encode<T: Encodable>(_ value: T) throws -> Data {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            return try encoder.encode(value)
        } catch {
            throw RepositoryError.encodingFailed
        }
    }

    static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
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
        throw RepositoryError.decodingFailed
    }

    static func requiredDouble(_ key: String, from object: NSManagedObject) throws -> Double {
        if let value = object.value(forKey: key) as? Double { return value }
        if let number = object.value(forKey: key) as? NSNumber { return number.doubleValue }
        throw RepositoryError.decodingFailed
    }

    static func requiredInt64(_ key: String, from object: NSManagedObject) throws -> Int64 {
        if let value = object.value(forKey: key) as? Int64 { return value }
        if let number = object.value(forKey: key) as? NSNumber { return number.int64Value }
        throw RepositoryError.decodingFailed
    }

    static func requiredBool(_ key: String, from object: NSManagedObject) throws -> Bool {
        if let value = object.value(forKey: key) as? Bool { return value }
        if let number = object.value(forKey: key) as? NSNumber { return number.boolValue }
        throw RepositoryError.decodingFailed
    }

    static func optionalDouble(_ key: String, from object: NSManagedObject) -> Double? {
        if let value = object.value(forKey: key) as? Double { return value }
        if let number = object.value(forKey: key) as? NSNumber { return number.doubleValue }
        return nil
    }

    static func optionalBool(_ key: String, from object: NSManagedObject) -> Bool? {
        if let value = object.value(forKey: key) as? Bool { return value }
        if let number = object.value(forKey: key) as? NSNumber { return number.boolValue }
        return nil
    }
}
