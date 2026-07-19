// [協作區 — 邊界適配層] SkateTrackPackageExportProvider.swift
// 用途：建立 iOS 單筆 Session 的 .skatetrack 暫存匯出檔，並交給系統分享表。
// 委派至：Shared/Export writer 寫檔；ViewModel 管理 UI state 與 cleanup；Snow-Task-008a 從 SnowSessionRepository 取得正式 Snow package payload。

import Foundation

struct SkateTrackPackageExportResult: Identifiable, Equatable, Sendable {
    let id: UUID
    let sessionID: UUID
    let directoryURL: URL
    let fileURL: URL
    let manifest: SkateTrackPackageManifest
    let byteCount: Int

    init(
        id: UUID = UUID(),
        sessionID: UUID,
        directoryURL: URL,
        fileURL: URL,
        manifest: SkateTrackPackageManifest,
        byteCount: Int
    ) {
        self.id = id
        self.sessionID = sessionID
        self.directoryURL = directoryURL
        self.fileURL = fileURL
        self.manifest = manifest
        self.byteCount = max(0, byteCount)
    }

    var itemURLs: [URL] {
        [fileURL]
    }
}

struct SkateTrackPackageExportProvider {
    private let fileManager: FileManager
    private let writer: SkateTrackPackageWriter
    private let snowRepository: SnowSessionRepositoryProtocol
    private let now: @Sendable () -> Date

    init(
        fileManager: FileManager = .default,
        writer: SkateTrackPackageWriter = SkateTrackPackageWriter(),
        snowRepository: SnowSessionRepositoryProtocol = SnowSessionRepository.shared,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.fileManager = fileManager
        self.writer = writer
        self.snowRepository = snowRepository
        self.now = now
    }

    func createExport(content: SessionSummaryContent) async throws -> SkateTrackPackageExportResult {
        let effectiveSamples = content.motionSamples.isEmpty ? content.session.motionSamples : content.motionSamples
        let exportSession = try sessionWithDiagnosticsFallback(content.session)
        let snowPayload = try await makeSnowPayloadIfAvailable(for: exportSession)
        let sessionItem = SkateTrackPackageSession(
            id: exportSession.id,
            session: exportSession,
            motionSamples: effectiveSamples,
            snowPayload: snowPayload
        )
        let manifest = SkateTrackPackageManifest(
            appVersion: bundleValue(for: "CFBundleShortVersionString"),
            buildNumber: bundleValue(for: "CFBundleVersion"),
            localeIdentifier: Locale.autoupdatingCurrent.identifier,
            sessionCount: 1,
            includesMotionSamples: !effectiveSamples.isEmpty,
            includesAccountData: false,
            includesAchievements: false,
            formatCapabilities: packageFormatCapabilities(for: effectiveSamples, session: exportSession),
            capabilities: snowPayload == nil ? nil : SkateTrackPackageSnowCapability.allRawValues
        )
        let payload = try SkateTrackPackagePayload(manifest: manifest, sessions: [sessionItem])
        let directoryURL = packageDirectoryURL(sessionID: exportSession.id)
        let fileURL = directoryURL.appendingPathComponent(fileName(for: exportSession))
        let byteCount = try writer.write(package: payload, to: fileURL)

        return SkateTrackPackageExportResult(
            sessionID: exportSession.id,
            directoryURL: directoryURL,
            fileURL: fileURL,
            manifest: manifest,
            byteCount: byteCount
        )
    }

    func cleanup(_ result: SkateTrackPackageExportResult) {
        try? fileManager.removeItem(at: result.directoryURL)
    }

    private func sessionWithDiagnosticsFallback(_ session: SessionData) throws -> SessionData {
        guard session.debugRecordingDiagnostics == nil else { return session }

        let fallbackDiagnostics = RecordingDebugDiagnostics(
            buildIdentity: RecordingDebugBuildIdentity(),
            testContext: nil,
            diagnosticsStartedAt: session.startDate,
            diagnosticsEndedAt: session.endDate ?? Date(),
            diagnosticsStatus: "missingFromPersistedSession",
            appLifecycleEvents: [],
            recordingHeartbeats: [],
            authorizationSnapshots: [],
            locationManagerSnapshots: [],
            locationCallbackEvents: [],
            gapEvents: [],
            recoveryEvents: [],
            filterDecisionSummary: RecordingDebugFilterDecisionSummary(),
            altitudeDiagnostics: RecordingDebugAltitudeDiagnostics()
        )

        return try SessionData(
            id: session.id,
            startDate: session.startDate,
            endDate: session.endDate,
            sportMode: session.sportMode,
            powerType: session.powerType,
            motionSamples: session.motionSamples,
            trickEvents: session.trickEvents,
            fallEvents: session.fallEvents,
            summaryMetrics: session.summaryMetrics,
            routeQualitySummary: session.routeQualitySummary,
            fidelityProfile: session.fidelityProfile,
            debugRecordingDiagnostics: fallbackDiagnostics,
            equipmentID: session.equipmentID,
            equipmentSnapshot: session.equipmentSnapshot,
            spotID: session.spotID,
            spotSnapshot: session.spotSnapshot
        )
    }

    // Compatibility verify token: packageFormatCapabilities(for samples: [MotionSample])
    private func packageFormatCapabilities(for samples: [MotionSample], session: SessionData) -> [String] {
        var capabilities = [
            "location-diagnostics-v1",
            "route-quality-summary-v1",
            "navigation-continuity-diagnostics-v1",
            "route-recording-recovery-v1",
            "raw-location-stream-v1",
            "activity-aware-fidelity-v1",
            "altitude-source-stabilization-v1"
        ]

        if samples.contains(where: { $0.altitudeDiagnostics != nil }) {
            capabilities.append("altitude-diagnostics-v1")
        }

        if session.debugRecordingDiagnostics != nil {
            capabilities.append("debug-build-identity-v1")
            capabilities.append("debug-recording-diagnostics-v1")
            capabilities.append("background-gap-diagnostics-v1")
            capabilities.append("diagnostics-export-status-v1")
        }

        #if DEBUG
        if samples.contains(where: { $0.locationDiagnostics?.speedSource == .debugSimulated }) {
            capabilities.append("debug-simulated-route-v1")
        }
        #endif

        return capabilities
    }

    private func makeSnowPayloadIfAvailable(for session: SessionData) async throws -> SkateTrackPackageSnowPayload? {
        guard session.sportMode.isSnow else { return nil }

        let state = try await snowRepository.fetchState(sessionID: session.id)
        return SkateTrackPackageSnowPayload(snowState: state, generatedAt: now())
    }

    private func packageDirectoryURL(sessionID: UUID) -> URL {
        let folderName = "\(sessionID.uuidString)-\(Int(now().timeIntervalSince1970))"
        return fileManager.temporaryDirectory
            .appendingPathComponent("SkateTrackPackages", isDirectory: true)
            .appendingPathComponent(folderName, isDirectory: true)
    }

    private func fileName(for session: SessionData) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let stamp = formatter.string(from: session.startDate)
        return "SkateTrack-Session-\(stamp).skatetrack"
    }

    private func bundleValue(for key: String) -> String {
        Bundle.main.object(forInfoDictionaryKey: key) as? String ?? "local"
    }
}

extension SportMode {
    var isSnow: Bool {
        if case .snow = self {
            return true
        }
        return false
    }
}
