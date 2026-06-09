// [協作區] Shared/Models/FallEvent.swift
// 用途：定義跌倒偵測事件，包含衝擊 G 值、位置、恢復時間與使用者確認狀態。
// 委派至：fall detection、HealthKit integration、watchOS SOS 與 session timeline。

import Foundation

struct FallEvent: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    let timestamp: Date
    let peakImpactGForce: Double
    let locationCoordinate: GeoCoordinate?
    let recoveryDurationSeconds: Double?
    let sportMode: SportMode?
    let userConfirmed: Bool

    init(
        id: UUID = UUID(),
        timestamp: Date,
        peakImpactGForce: Double,
        locationCoordinate: GeoCoordinate? = nil,
        recoveryDurationSeconds: Double? = nil,
        sportMode: SportMode? = nil,
        userConfirmed: Bool = false
    ) {
        self.id = id
        self.timestamp = timestamp
        self.peakImpactGForce = peakImpactGForce
        self.locationCoordinate = locationCoordinate
        self.recoveryDurationSeconds = recoveryDurationSeconds
        self.sportMode = sportMode
        self.userConfirmed = userConfirmed
    }
}
