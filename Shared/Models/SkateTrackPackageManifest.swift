// [協作區] Shared/Models/SkateTrackPackageManifest.swift
// 用途：定義 Task-027/008a 可攜式 .skatetrack 匯出 package manifest、schema 版本策略與 capability 宣告。
// 委派至：SkateTrackPackageWriter / Reader 與 iOS package export provider；不得混用 Task-026 backup package。

import Foundation

enum SkateTrackPackageType: String, Codable, Sendable, Equatable {
    case export
}

struct SkateTrackPackageManifest: Codable, Sendable, Equatable {
    static let currentSchemaVersion = 2
    static let supportedSchemaVersions: Set<Int> = [1, 2]

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
    // Mainline export-format and diagnostics features that describe how the
    // portable session content was produced. These do not declare payloads.
    let formatCapabilities: [String]?
    let watchSampleCompatibility: SkateTrackWatchSampleCompatibility?
    // Optional extension-payload features. Snow values are present only when
    // the package carries the corresponding Snow payload.
    let capabilities: [String]?

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
        watchSampleCompatibility: SkateTrackWatchSampleCompatibility? = nil,
        capabilities: [String]? = nil
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
        self.capabilities = Self.normalizedCapabilities(capabilities)
    }

    var includesOptionalWatchSampleData: Bool {
        watchSampleCompatibility?.containsWatchSamples == true
    }

    var declaresSnowPackagePayload: Bool {
        normalizedCapabilitySet.contains(SkateTrackPackageSnowCapability.snowSports.rawValue)
    }

    var normalizedCapabilitySet: Set<String> {
        Set(capabilities ?? [])
    }

    static func decode(from data: Data) throws -> SkateTrackPackageManifest {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let raw = try decoder.decode(SkateTrackPackageManifest.self, from: data)
        try validate(raw)
        return raw
    }

    static func validate(_ manifest: SkateTrackPackageManifest) throws {
        guard supportedSchemaVersions.contains(manifest.schemaVersion) else {
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

    private static func normalizedCapabilities(_ capabilities: [String]?) -> [String]? {
        guard let capabilities else { return nil }
        let normalized = Array(Set(capabilities.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })).sorted()
        return normalized.isEmpty ? nil : normalized
    }

    private enum CodingKeys: String, CodingKey {
        case packageType
        case schemaVersion
        case appVersion
        case buildNumber
        case createdAt
        case localeIdentifier
        case sessionCount
        case includesMotionSamples
        case includesAccountData
        case includesAchievements
        case formatDescription
        case formatCapabilities
        case watchSampleCompatibility
        case capabilities
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        packageType = try container.decode(SkateTrackPackageType.self, forKey: .packageType)
        schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        appVersion = try container.decode(String.self, forKey: .appVersion)
        buildNumber = try container.decode(String.self, forKey: .buildNumber)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        localeIdentifier = try container.decode(String.self, forKey: .localeIdentifier)
        sessionCount = max(0, try container.decode(Int.self, forKey: .sessionCount))
        includesMotionSamples = try container.decode(Bool.self, forKey: .includesMotionSamples)
        includesAccountData = try container.decode(Bool.self, forKey: .includesAccountData)
        includesAchievements = try container.decode(Bool.self, forKey: .includesAchievements)
        formatDescription = try container.decode(String.self, forKey: .formatDescription)
        formatCapabilities = try container.decodeIfPresent([String].self, forKey: .formatCapabilities)
        watchSampleCompatibility = try container.decodeIfPresent(
            SkateTrackWatchSampleCompatibility.self,
            forKey: .watchSampleCompatibility
        )
        capabilities = Self.normalizedCapabilities(try container.decodeIfPresent([String].self, forKey: .capabilities))
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
