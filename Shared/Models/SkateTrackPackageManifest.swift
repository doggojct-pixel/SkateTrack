// [協作區] Shared/Models/SkateTrackPackageManifest.swift
// 用途：定義 Task-027 可攜式 .skatetrack 匯出 package manifest 與 schema 版本策略。
// 委派至：SkateTrackPackageWriter / Reader 與 iOS package export provider；不得混用 Task-026 backup package。

import Foundation

enum SkateTrackPackageType: String, Codable, Sendable, Equatable {
    case export
}

struct SkateTrackPackageManifest: Codable, Sendable, Equatable {
    static let currentSchemaVersion = 1

    let packageType: SkateTrackPackageType
    let schemaVersion: Int
    let appVersion: String
    let buildNumber: String
    let createdAt: Date
    let localeIdentifier: String
    let sessionCount: Int
    let includesMotionSamples: Bool
    let includesAccountData: Bool
    let includesAchievements: Bool
    let formatDescription: String
    let formatCapabilities: [String]?
    let watchSampleCompatibility: SkateTrackWatchSampleCompatibility?

    init(
        packageType: SkateTrackPackageType = .export,
        schemaVersion: Int = SkateTrackPackageManifest.currentSchemaVersion,
        appVersion: String,
        buildNumber: String,
        createdAt: Date = Date(),
        localeIdentifier: String,
        sessionCount: Int,
        includesMotionSamples: Bool,
        includesAccountData: Bool = false,
        includesAchievements: Bool = false,
        formatDescription: String = "portable-session-export",
        formatCapabilities: [String]? = nil,
        watchSampleCompatibility: SkateTrackWatchSampleCompatibility? = nil
    ) {
        self.packageType = packageType
        self.schemaVersion = schemaVersion
        self.appVersion = appVersion
        self.buildNumber = buildNumber
        self.createdAt = createdAt
        self.localeIdentifier = localeIdentifier
        self.sessionCount = max(0, sessionCount)
        self.includesMotionSamples = includesMotionSamples
        self.includesAccountData = includesAccountData
        self.includesAchievements = includesAchievements
        self.formatDescription = formatDescription
        self.formatCapabilities = formatCapabilities
        self.watchSampleCompatibility = watchSampleCompatibility
    }

    var includesOptionalWatchSampleData: Bool {
        watchSampleCompatibility?.containsWatchSamples == true
    }

    static func decode(from data: Data) throws -> SkateTrackPackageManifest {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let raw = try decoder.decode(SkateTrackPackageManifest.self, from: data)
        try validate(raw)
        return raw
    }

    static func validate(_ manifest: SkateTrackPackageManifest) throws {
        switch manifest.schemaVersion {
        case currentSchemaVersion:
            break
        default:
            throw SkateTrackPackageError.unsupportedSchemaVersion(manifest.schemaVersion)
        }

        guard manifest.packageType == .export else {
            throw SkateTrackPackageError.unsupportedPackageType(manifest.packageType.rawValue)
        }

        guard !manifest.includesAccountData else {
            throw SkateTrackPackageError.accountDataNotAllowed
        }

        guard !manifest.includesAchievements else {
            throw SkateTrackPackageError.achievementsNotAllowed
        }
    }
}

struct SkateTrackWatchSampleCompatibility: Codable, Sendable, Equatable {
    static let capabilityIdentifier = "watch-sample-optional-v1"

    let containsWatchSamples: Bool
    let storageStrategy: String
    let sourceAttributionPreserved: Bool
    let displayDerivedOnly: Bool
    let trustedMetricMutationCount: Int
    let routeGeometryMutationCount: Int

    init(
        containsWatchSamples: Bool = false,
        storageStrategy: String = "not-exported",
        sourceAttributionPreserved: Bool = false,
        displayDerivedOnly: Bool = true,
        trustedMetricMutationCount: Int = 0,
        routeGeometryMutationCount: Int = 0
    ) {
        self.containsWatchSamples = containsWatchSamples
        self.storageStrategy = storageStrategy
        self.sourceAttributionPreserved = sourceAttributionPreserved
        self.displayDerivedOnly = displayDerivedOnly
        self.trustedMetricMutationCount = trustedMetricMutationCount
        self.routeGeometryMutationCount = routeGeometryMutationCount
    }
}

enum SkateTrackPackageError: Error, Sendable, Equatable {
    case unsupportedSchemaVersion(Int)
    case unsupportedPackageType(String)
    case accountDataNotAllowed
    case achievementsNotAllowed
    case emptySessionExport
    case packageEncodingFailed
    case packageDecodingFailed
    case fileWriteFailed
    case fileReadFailed

    var localizationKey: String {
        switch self {
        case .unsupportedSchemaVersion:
            return "skatetrack.package.error.unsupported_schema"
        case .unsupportedPackageType:
            return "skatetrack.package.error.unsupported_type"
        case .accountDataNotAllowed:
            return "skatetrack.package.error.account_data"
        case .achievementsNotAllowed:
            return "skatetrack.package.error.achievements"
        case .emptySessionExport:
            return "skatetrack.package.error.empty"
        case .packageEncodingFailed:
            return "skatetrack.package.error.encoding"
        case .packageDecodingFailed:
            return "skatetrack.package.error.decoding"
        case .fileWriteFailed:
            return "skatetrack.package.error.write"
        case .fileReadFailed:
            return "skatetrack.package.error.read"
        }
    }
}
