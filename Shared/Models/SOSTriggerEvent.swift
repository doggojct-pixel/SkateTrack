// [協作區] Shared/Models/SOSTriggerEvent.swift
// 用途：定義 SOS 觸發事件，記錄來源、跌倒資料、位置、聯絡人狀態與 Phase 1a 派送狀態。
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
    case contactSetupRequired
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
    let emergencyContacts: [EmergencyContact]
    let messageLocalizationKey: String
    let messagePreview: String
    let userActionHintLocalizationKey: String

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        source: SOSTriggerSource,
        dispatchStatus: SOSDispatchStatus = .recorded,
        relatedFallEvent: FallEvent? = nil,
        locationCoordinate: GeoCoordinate? = nil,
        sportMode: SportMode? = nil,
        emergencyContacts: [EmergencyContact] = [],
        messageLocalizationKey: String = "sos.message.template",
        messagePreview: String = "",
        userActionHintLocalizationKey: String = "sos.event.ready"
    ) {
        self.id = id
        self.timestamp = timestamp
        self.source = source
        self.dispatchStatus = dispatchStatus
        self.relatedFallEvent = relatedFallEvent
        self.locationCoordinate = locationCoordinate
        self.sportMode = sportMode
        self.emergencyContacts = emergencyContacts
        self.messageLocalizationKey = messageLocalizationKey
        self.messagePreview = messagePreview
        self.userActionHintLocalizationKey = userActionHintLocalizationKey
    }

    var hasEmergencyContacts: Bool {
        !emergencyContacts.isEmpty
    }

    var primaryEmergencyContact: EmergencyContact? {
        emergencyContacts.first(where: \.isPrimary) ?? emergencyContacts.first
    }
}
