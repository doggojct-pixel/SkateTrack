// [協作區] Shared/Models/SOSTriggerEvent.swift
// 用途：定義 SOS 觸發事件，記錄來源、跌倒資料、位置與 Phase 1a 派送狀態。
// 委派至：SOSEventDispatcher、Fall Alert UI、後續持久化與安全事件摘要。

import Foundation

enum SOSTriggerSource: String, Codable, Sendable, Equatable {
    case manualHUD
    case fallImmediate
    case fallCountdownExpired
}

enum SOSDispatchStatus: String, Codable, Sendable, Equatable {
    case recorded
    case readyForUserAction
    case unavailable
}

struct SOSTriggerEvent: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    let timestamp: Date
    let source: SOSTriggerSource
    let dispatchStatus: SOSDispatchStatus
    let relatedFallEvent: FallEvent?
    let locationCoordinate: GeoCoordinate?
    let sportMode: SportMode?
    let messageLocalizationKey: String

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        source: SOSTriggerSource,
        dispatchStatus: SOSDispatchStatus = .recorded,
        relatedFallEvent: FallEvent? = nil,
        locationCoordinate: GeoCoordinate? = nil,
        sportMode: SportMode? = nil,
        messageLocalizationKey: String = "sos.message.template"
    ) {
        self.id = id
        self.timestamp = timestamp
        self.source = source
        self.dispatchStatus = dispatchStatus
        self.relatedFallEvent = relatedFallEvent
        self.locationCoordinate = locationCoordinate
        self.sportMode = sportMode
        self.messageLocalizationKey = messageLocalizationKey
    }
}
