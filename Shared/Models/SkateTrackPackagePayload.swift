// [協作區] Shared/Models/SkateTrackPackagePayload.swift
// 用途：定義 Task-027 可攜式 .skatetrack 匯出 payload，只包含分享 / 檢視需要的 session 資料。
// 委派至：SkateTrackPackageWriter / Reader；不包含帳號、token、成就或 Google Drive 狀態。

import Foundation

struct SkateTrackPackagePayload: Codable, Sendable, Equatable {
    let manifest: SkateTrackPackageManifest
    let sessions: [SkateTrackPackageSession]

    init(manifest: SkateTrackPackageManifest, sessions: [SkateTrackPackageSession]) throws {
        guard !sessions.isEmpty else { throw SkateTrackPackageError.emptySessionExport }
        self.manifest = manifest
        self.sessions = sessions
        try SkateTrackPackageManifest.validate(manifest)
    }

    var primarySession: SkateTrackPackageSession? {
        sessions.first
    }
}

struct SkateTrackPackageSession: Codable, Sendable, Equatable, Identifiable {
    let id: UUID
    let session: SessionData
    let motionSamples: [MotionSample]
    let routeQualitySummary: RouteQualitySummary?
    let exportedAt: Date
    let privacyNotes: [String]
    let snowPayload: SkateTrackPackageSnowPayload?

    init(
        id: UUID = UUID(),
        session: SessionData,
        motionSamples: [MotionSample],
        routeQualitySummary: RouteQualitySummary? = nil,
        exportedAt: Date = Date(),
        privacyNotes: [String] = [
            "No account session, Google token, Drive state, achievements, or weekly challenge records are included."
        ],
        snowPayload: SkateTrackPackageSnowPayload? = nil
    ) {
        self.id = id
        self.session = session
        self.motionSamples = motionSamples
        self.routeQualitySummary = routeQualitySummary ?? session.routeQualitySummary ?? RouteQualitySummary.make(from: motionSamples)
        self.exportedAt = exportedAt
        self.privacyNotes = privacyNotes
        self.snowPayload = snowPayload
    }

    var sampleCount: Int {
        motionSamples.count
    }

    var hasRouteSamples: Bool {
        motionSamples.contains { $0.gpsCoordinate != nil }
    }

    var hasSnowPayload: Bool {
        snowPayload != nil
    }
}
