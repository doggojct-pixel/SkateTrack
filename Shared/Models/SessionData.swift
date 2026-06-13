// [協作區] Shared/Models/SessionData.swift
// 用途：定義 SkateTrack session 根容器，集中保存模式、動力、感測樣本、招式與跌倒事件。
// 委派至：SensorProvider、SyncProvider、history、summary、export 與 macOS analysis。

import Foundation

struct SessionData: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    let startDate: Date
    let endDate: Date?
    let sportMode: SportMode
    let powerType: PowerType
    let motionSamples: [MotionSample]
    let trickEvents: [TrickEvent]
    let fallEvents: [FallEvent]
    let summaryMetrics: SessionSummaryMetrics?
    let routeQualitySummary: RouteQualitySummary?
    let equipmentID: UUID?
    let equipmentSnapshot: EquipmentSessionSnapshot?
    let spotID: UUID?
    let spotSnapshot: SpotSessionSnapshot?

    init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date? = nil,
        sportMode: SportMode,
        powerType: PowerType = .humanPowered,
        motionSamples: [MotionSample] = [],
        trickEvents: [TrickEvent] = [],
        fallEvents: [FallEvent] = [],
        summaryMetrics: SessionSummaryMetrics? = nil,
        routeQualitySummary: RouteQualitySummary? = nil,
        equipmentID: UUID? = nil,
        equipmentSnapshot: EquipmentSessionSnapshot? = nil,
        spotID: UUID? = nil,
        spotSnapshot: SpotSessionSnapshot? = nil
    ) throws {
        guard powerType.isValid(for: sportMode) else {
            throw PowerTypeValidationError.electricPowerRequiresSkateboardMode
        }

        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.sportMode = sportMode
        self.powerType = powerType
        self.motionSamples = motionSamples
        self.trickEvents = trickEvents
        self.fallEvents = fallEvents
        self.summaryMetrics = summaryMetrics
        self.routeQualitySummary = routeQualitySummary
        self.equipmentID = equipmentID
        self.equipmentSnapshot = equipmentSnapshot
        self.spotID = spotID
        self.spotSnapshot = spotSnapshot
    }

    var durationSeconds: TimeInterval? {
        guard let endDate else { return nil }
        return endDate.timeIntervalSince(startDate)
    }

    var isPowerConfigurationValid: Bool {
        powerType.isValid(for: sportMode)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case startDate
        case endDate
        case sportMode
        case powerType
        case motionSamples
        case trickEvents
        case fallEvents
        case summaryMetrics
        case routeQualitySummary
        case equipmentID
        case equipmentSnapshot
        case spotID
        case spotSnapshot
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedSportMode = try container.decode(SportMode.self, forKey: .sportMode)
        let decodedPowerType = try container.decode(PowerType.self, forKey: .powerType)

        guard decodedPowerType.isValid(for: decodedSportMode) else {
            throw DecodingError.dataCorruptedError(
                forKey: .powerType,
                in: container,
                debugDescription: "Electric power type requires a skateboard sport mode."
            )
        }

        id = try container.decode(UUID.self, forKey: .id)
        startDate = try container.decode(Date.self, forKey: .startDate)
        endDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
        sportMode = decodedSportMode
        powerType = decodedPowerType
        motionSamples = try container.decode([MotionSample].self, forKey: .motionSamples)
        trickEvents = try container.decode([TrickEvent].self, forKey: .trickEvents)
        fallEvents = try container.decode([FallEvent].self, forKey: .fallEvents)
        summaryMetrics = try container.decodeIfPresent(SessionSummaryMetrics.self, forKey: .summaryMetrics)
        routeQualitySummary = try container.decodeIfPresent(RouteQualitySummary.self, forKey: .routeQualitySummary)
        equipmentID = try container.decodeIfPresent(UUID.self, forKey: .equipmentID)
        equipmentSnapshot = try container.decodeIfPresent(EquipmentSessionSnapshot.self, forKey: .equipmentSnapshot)
        spotID = try container.decodeIfPresent(UUID.self, forKey: .spotID)
        spotSnapshot = try container.decodeIfPresent(SpotSessionSnapshot.self, forKey: .spotSnapshot)
    }
}
