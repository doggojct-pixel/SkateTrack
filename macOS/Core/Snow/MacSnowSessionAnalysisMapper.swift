// [協作區] MacSnowSessionAnalysisMapper.swift
// 用途：將 repository-backed SnowSessionState 或後續 package Snow payload 映射成 macOS presentation value。
// 委派至：MacSnowAnalysisViewModel；不得修改 package schema、reader、writer 或 persistence model。

import Foundation

enum MacSnowSessionAnalysisMapper {
    static func makeAvailability(
        session: SessionData,
        snowState: SnowSessionState,
        motionSamples: [MotionSample]? = nil,
        source: MacSnowAnalysisSource
    ) -> MacSnowAnalysisAvailability {
        guard isSnowSession(session) else {
            return .unavailable(reason: "noSnowSession")
        }

        let analysis = makeAnalysis(
            session: session,
            snowState: snowState,
            motionSamples: motionSamples,
            source: source
        )
        return .available(analysis)
    }

    static func makePackageSchemaPending() -> MacSnowAnalysisAvailability {
        .packageSchemaPending
    }

    static func makeAvailabilityFromPackage(
        packageSession: SkateTrackPackageSession,
        snowPayload: SkateTrackPackageSnowPayload?
    ) -> MacSnowAnalysisAvailability {
        guard isSnowSession(packageSession.session) else {
            return .unavailable(reason: "noSnowSession")
        }

        guard let snowPayload else {
            return .packageSchemaPending
        }

        guard snowPayload.sessionID == packageSession.session.id else {
            return .unavailable(reason: "snowPayloadSessionMismatch")
        }

        return makeAvailability(
            session: packageSession.session,
            snowState: snowPayload.makeSnowSessionState(),
            motionSamples: packageSession.motionSamples,
            source: .importedPackage
        )
    }

    static func makeAnalysis(
        session: SessionData,
        snowState: SnowSessionState,
        motionSamples: [MotionSample]? = nil,
        source: MacSnowAnalysisSource
    ) -> MacSnowSessionAnalysis {
        let samples = (motionSamples ?? session.motionSamples).sorted { $0.timestamp < $1.timestamp }
        let runs = snowState.runs.sorted { $0.runNumber < $1.runNumber }
        let segments = snowState.segments.sorted { $0.startDate < $1.startDate }
        let distanceBreakdown = snowState.distanceBreakdown
        let verticalMetrics = snowState.verticalMetrics
        let routePoints = MacSnowRouteFilter.routePoints(from: samples)
        let elevationPoints = MacSnowRouteFilter.elevationPoints(from: samples)

        return MacSnowSessionAnalysis(
            id: snowState.sessionID ?? session.id,
            title: title(for: session),
            subtitle: subtitle(for: session, source: source),
            startDate: session.startDate,
            endDate: session.endDate,
            sportMode: session.sportMode,
            discipline: discipline(from: session.sportMode),
            source: source,
            runs: runs,
            segments: segments,
            distanceBreakdown: distanceBreakdown,
            verticalMetrics: verticalMetrics,
            motionSamples: samples,
            topSpeedMetersPerSecond: topSpeedMetersPerSecond(runs: runs, samples: samples),
            averageRunDurationSeconds: averageRunDurationSeconds(runs: runs),
            routePoints: routePoints,
            elevationPoints: elevationPoints,
            hasLimitedAltitudeData: MacSnowRouteFilter.hasLimitedAltitudeData(
                segments: segments,
                samples: samples
            )
        )
    }

    private static func isSnowSession(_ session: SessionData) -> Bool {
        if case .snow = session.sportMode { return true }
        return false
    }

    private static func discipline(from sportMode: SportMode) -> SnowDiscipline? {
        guard case let .snow(discipline) = sportMode else { return nil }
        return discipline
    }

    private static func title(for session: SessionData) -> String {
        switch session.sportMode {
        case .snow:
            return "Snow Session"
        case .skateboard, .inline:
            return "Session"
        }
    }

    private static func subtitle(
        for session: SessionData,
        source: MacSnowAnalysisSource
    ) -> String {
        let sourceLabel: String
        switch source {
        case .debugMock:
            sourceLabel = "DEBUG mock"
        case .coreDataRepository:
            sourceLabel = "Core Data"
        case .importedPackage:
            sourceLabel = "Imported package"
        }
        return "\(sourceLabel) • \(Int(session.durationSeconds ?? 0))s"
    }

    private static func topSpeedMetersPerSecond(
        runs: [SnowRun],
        samples: [MotionSample]
    ) -> Double {
        let runTop = runs.map(\.topSpeedMetersPerSecond).max() ?? 0
        let sampleTop = (samples.map(\.speedKmh).max() ?? 0) / 3.6
        return max(runTop, sampleTop)
    }

    private static func averageRunDurationSeconds(runs: [SnowRun]) -> TimeInterval? {
        let durations = runs.compactMap(\.durationSeconds)
        guard !durations.isEmpty else { return nil }
        return durations.reduce(0, +) / Double(durations.count)
    }
}
