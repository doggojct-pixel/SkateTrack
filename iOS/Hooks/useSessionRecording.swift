// [協作區 — 邊界適配層] useSessionRecording.swift
// 用途：向 SwiftUI View 暴露 Session 狀態與操作，隱藏 SessionRecordingCoordinator 細節。
// 委派至：Task-012 Session Start Flow、Task-013 Live HUD、Task-014 Fall Alert UI。

import Combine
import SwiftUI

struct SessionRecordingState: Equatable {
    var status: SessionRecordingStatus
    var selectedSportMode: SportMode?
    var selectedPowerType: PowerType
    var selectedEquipmentID: UUID?
    var selectedSpotID: UUID?
    var currentSpeedKilometersPerHour: Double
    var maxSpeedKilometersPerHour: Double
    var averageSpeedKilometersPerHour: Double
    var distanceKilometers: Double
    var elapsedTime: TimeInterval
    var currentTiltDegrees: Double
    var latestMotionSample: MotionSample?
    var motionSampleCount: Int
    var gpsSampleCount: Int
    var recentRouteCoordinates: [GeoCoordinate]
    var activeFallEvent: FallEvent?
    var errorMessageKey: String?

    static let initial = SessionRecordingState(
        status: .idle,
        selectedSportMode: nil,
        selectedPowerType: .humanPowered,
        selectedEquipmentID: nil,
        selectedSpotID: nil,
        currentSpeedKilometersPerHour: 0,
        maxSpeedKilometersPerHour: 0,
        averageSpeedKilometersPerHour: 0,
        distanceKilometers: 0,
        elapsedTime: 0,
        currentTiltDegrees: 0,
        latestMotionSample: nil,
        motionSampleCount: 0,
        gpsSampleCount: 0,
        recentRouteCoordinates: [],
        activeFallEvent: nil,
        errorMessageKey: nil
    )
}

struct SessionRecordingActions {
    let startSession: (SportMode, PowerType, UUID?, EquipmentSessionSnapshot?, UUID?, SpotSessionSnapshot?) async -> Void
    let pauseSession: () async -> Void
    let resumeSession: () async -> Void
    let requestEndSession: () async -> Void
    let discardCurrentSession: () async -> Void
}

@MainActor
final class SessionRecordingViewModel: ObservableObject {
    @Published private(set) var state: SessionRecordingState = .initial
    @Published private(set) var lastCompletedSession: SessionData?
    #if DEBUG
    @Published private(set) var debugDemoSpeedSessionEnabled: Bool
    @Published var debugRecordingTestContext: DebugRecordingTestContextLabel = .unspecified
    #endif

    private let coordinator: SessionRecordingCoordinator
    private var cancellables = Set<AnyCancellable>()

    init(coordinator: SessionRecordingCoordinator = .shared) {
        self.coordinator = coordinator
        #if DEBUG
        self.debugDemoSpeedSessionEnabled = coordinator.debugDataSource == .mock
        self.debugRecordingTestContext = .unspecified
        #endif
        bindCoordinator()
    }

    var actions: SessionRecordingActions {
        SessionRecordingActions(
            startSession: { [weak self] mode, powerType, equipmentID, equipmentSnapshot, spotID, spotSnapshot in
                await self?.startSession(
                    mode: mode,
                    powerType: powerType,
                    equipmentID: equipmentID,
                    equipmentSnapshot: equipmentSnapshot,
                    spotID: spotID,
                    spotSnapshot: spotSnapshot
                )
            },
            pauseSession: { [weak self] in
                await self?.pauseSession()
            },
            resumeSession: { [weak self] in
                await self?.resumeSession()
            },
            requestEndSession: { [weak self] in
                await self?.requestEndSession()
            },
            discardCurrentSession: { [weak self] in
                await self?.discardCurrentSession()
            }
        )
    }

    private func bindCoordinator() {
        coordinator.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.updateState {
                    if status == .idle {
                        $0 = .initial
                    } else {
                        $0.status = status
                    }
                }
            }
            .store(in: &cancellables)

        coordinator.metricsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] metrics in
                self?.updateState {
                    $0.currentSpeedKilometersPerHour = metrics.currentSpeedKilometersPerHour
                    $0.maxSpeedKilometersPerHour = metrics.maxSpeedKilometersPerHour
                    $0.averageSpeedKilometersPerHour = metrics.averageSpeedKilometersPerHour
                    $0.distanceKilometers = metrics.distanceKilometers
                    $0.elapsedTime = metrics.elapsedTime
                    $0.currentTiltDegrees = metrics.currentTiltDegrees
                    $0.latestMotionSample = metrics.latestMotionSample
                    $0.motionSampleCount = metrics.motionSampleCount
                    $0.gpsSampleCount = metrics.gpsSampleCount
                    if let coordinate = metrics.latestMotionSample?.gpsCoordinate {
                        $0.recentRouteCoordinates.append(coordinate)
                        if $0.recentRouteCoordinates.count > 80 {
                            $0.recentRouteCoordinates.removeFirst($0.recentRouteCoordinates.count - 80)
                        }
                    }
                }
            }
            .store(in: &cancellables)

        coordinator.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorKey in
                self?.updateState { $0.errorMessageKey = errorKey }
            }
            .store(in: &cancellables)

        coordinator.activeFallEventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] fallEvent in
                self?.updateState { $0.activeFallEvent = fallEvent }
            }
            .store(in: &cancellables)

        coordinator.completedSessionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessionData in
                self?.lastCompletedSession = sessionData
            }
            .store(in: &cancellables)
    }

    private func startSession(
        mode: SportMode,
        powerType: PowerType,
        equipmentID: UUID?,
        equipmentSnapshot: EquipmentSessionSnapshot?,
        spotID: UUID?,
        spotSnapshot: SpotSessionSnapshot?
    ) async {
        updateState {
            $0.selectedSportMode = mode
            $0.selectedPowerType = powerType
            $0.selectedEquipmentID = equipmentID
            $0.selectedSpotID = spotID
            $0.recentRouteCoordinates = []
            $0.errorMessageKey = nil
        }

        do {
            #if DEBUG
            coordinator.setDebugRecordingTestContext(debugRecordingTestContext)
            #endif
            try await coordinator.startSession(
                mode: mode,
                powerType: powerType,
                equipmentID: equipmentID,
                equipmentSnapshot: equipmentSnapshot,
                spotID: spotID,
                spotSnapshot: spotSnapshot
            )
        } catch let error as SessionRecordingError {
            updateState { $0.errorMessageKey = error.localizationKey }
        } catch {
            updateState { $0.errorMessageKey = SessionRecordingError.sensorUnavailable.localizationKey }
        }
    }

    private func pauseSession() async {
        do {
            try await coordinator.pauseSession()
        } catch {
            updateState { $0.errorMessageKey = SessionRecordingError.invalidStateTransition.localizationKey }
        }
    }

    private func resumeSession() async {
        do {
            try await coordinator.resumeSession()
        } catch {
            updateState { $0.errorMessageKey = SessionRecordingError.invalidStateTransition.localizationKey }
        }
    }

    private func requestEndSession() async {
        do {
            let sessionData = try await coordinator.requestEndSession()
            lastCompletedSession = sessionData
        } catch let error as RepositoryError {
            updateState { $0.errorMessageKey = error.localizationKey }
        } catch {
            updateState { $0.errorMessageKey = SessionRecordingError.invalidStateTransition.localizationKey }
        }
    }

    private func discardCurrentSession() async {
        await coordinator.discardCurrentSession()
        updateState {
            $0 = .initial
        }
    }

    #if DEBUG
    func setDebugDemoSpeedSessionEnabled(_ isEnabled: Bool) {
        coordinator.setDataSource(isEnabled ? .mock : .live)
        debugDemoSpeedSessionEnabled = isEnabled
    }

    func setDebugRecordingTestContext(_ context: DebugRecordingTestContextLabel) {
        debugRecordingTestContext = context
        coordinator.setDebugRecordingTestContext(context)
    }
    #endif

    private func updateState(_ mutation: (inout SessionRecordingState) -> Void) {
        var nextState = state
        mutation(&nextState)
        state = nextState
    }
}

@MainActor
func useSessionRecording(coordinator: SessionRecordingCoordinator = .shared) -> SessionRecordingViewModel {
    SessionRecordingViewModel(coordinator: coordinator)
}

#if DEBUG
struct SessionRecordingPreviewPanel: View {
    @ObservedObject var sessionRecording: SessionRecordingViewModel

    private var state: SessionRecordingState { sessionRecording.state }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.18))
                        .frame(width: 42, height: 42)
                    Image(systemName: statusIconName)
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(statusColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("debug.status.title")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                        .textCase(.uppercase)
                    Text(LocalizedStringKey(state.status.localizationKey))
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }

                Spacer()

                Text(latestSampleSourceLabel)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(latestSampleSourceColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(latestSampleSourceColor.opacity(0.14))
                    .clipShape(Capsule())
                    .accessibilityIdentifier("session-recording-preview-source-chip")
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ],
                spacing: 10
            ) {
                metricTile(
                    titleKey: "debug.status.speed",
                    value: formattedSpeed,
                    systemImage: "speedometer",
                    accent: SkateTrackSessionStartColors.teal
                )
                metricTile(
                    titleKey: "debug.status.distance",
                    value: formattedDistance,
                    systemImage: "point.topleft.down.curvedto.point.bottomright.up",
                    accent: SkateTrackSessionStartColors.blueCold
                )
                metricTile(
                    titleKey: "debug.status.elapsed",
                    value: formattedElapsedTime,
                    systemImage: "timer",
                    accent: SkateTrackSessionStartColors.purple
                )
                metricTile(
                    titleKey: "debug.status.gps",
                    value: "\(state.gpsSampleCount)",
                    systemImage: "location.fill",
                    accent: SkateTrackSessionStartColors.amber
                )
            }

            VStack(spacing: 8) {
                diagnosticRow(
                    titleKey: "debug.status.samples",
                    value: "\(state.motionSampleCount)"
                )
                diagnosticRow(
                    titleKey: "debug.status.latestAccuracy",
                    value: latestAccuracyText
                )
                diagnosticRow(
                    titleKey: "debug.status.latestFreshness",
                    value: latestFreshnessLabel
                )
            }
            .padding(12)
            .background(Color.white.opacity(0.045))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            if let errorKey = state.errorMessageKey {
                Label(LocalizedStringKey(errorKey), systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(SkateTrackSessionStartColors.accent2)
                    .padding(.top, 2)
                    .accessibilityIdentifier("session-recording-preview-error")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    SkateTrackSessionStartColors.card.opacity(0.96),
                    SkateTrackSessionStartColors.navy3.opacity(0.82)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: SkateTrackSessionStartColors.teal.opacity(0.10), radius: 18, x: 0, y: 10)
        .accessibilityIdentifier("session-recording-preview-panel")
    }

    private var formattedSpeed: String {
        "\(state.currentSpeedKilometersPerHour.formatted(.number.precision(.fractionLength(1)))) km/h"
    }

    private var formattedDistance: String {
        "\(state.distanceKilometers.formatted(.number.precision(.fractionLength(2)))) km"
    }

    private var formattedElapsedTime: String {
        let totalSeconds = max(Int(state.elapsedTime.rounded()), 0)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return "\(minutes):\(seconds < 10 ? "0" : "")\(seconds)"
    }

    private var statusIconName: String {
        switch state.status {
        case .idle:
            return "circle.dashed"
        case .preparing:
            return "sensor.tag.radiowaves.forward.fill"
        case .recording:
            return "record.circle.fill"
        case .paused:
            return "pause.circle.fill"
        case .ending, .saving:
            return "tray.and.arrow.down.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }

    private var statusColor: Color {
        switch state.status {
        case .idle:
            return SkateTrackSessionStartColors.textSecondary
        case .preparing:
            return SkateTrackSessionStartColors.amber
        case .recording:
            return SkateTrackSessionStartColors.teal
        case .paused:
            return SkateTrackSessionStartColors.purple
        case .ending, .saving:
            return SkateTrackSessionStartColors.blueCold
        case .failed:
            return SkateTrackSessionStartColors.accent2
        }
    }

    private var latestSampleSourceLabel: LocalizedStringKey {
        switch state.latestMotionSample?.sampleSource {
        case .some(.locationFix):
            return "debug.status.source.locationFix"
        case .some(.timerFusion):
            return "debug.status.source.timerFusion"
        case .some(.debugSimulated):
            return "debug.status.source.debugSimulated"
        case .none:
            return "debug.status.source.none"
        }
    }

    private var latestSampleSourceColor: Color {
        switch state.latestMotionSample?.sampleSource {
        case .some(.locationFix):
            return SkateTrackSessionStartColors.teal
        case .some(.timerFusion):
            return SkateTrackSessionStartColors.blueCold
        case .some(.debugSimulated):
            return SkateTrackSessionStartColors.amber
        case .none:
            return SkateTrackSessionStartColors.textTertiary
        }
    }

    private var latestAccuracyText: String {
        guard let accuracy = state.latestMotionSample?.locationDiagnostics?.horizontalAccuracyMeters else {
            return "—"
        }
        return "\(accuracy.formatted(.number.precision(.fractionLength(1)))) m"
    }

    private var latestFreshnessLabel: LocalizedStringKey {
        guard let freshness = state.latestMotionSample?.locationDiagnostics?.freshnessState else {
            return "debug.status.freshness.none"
        }
        switch freshness {
        case .fresh:
            return "debug.status.freshness.fresh"
        case .recent:
            return "debug.status.freshness.recent"
        case .stale:
            return "debug.status.freshness.stale"
        case .unavailable:
            return "debug.status.freshness.unavailable"
        }
    }

    private func metricTile(
        titleKey: LocalizedStringKey,
        value: String,
        systemImage: String,
        accent: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(accent)
                Text(titleKey)
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                    .textCase(.uppercase)
            }
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
                .minimumScaleFactor(0.76)
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(accent.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func diagnosticRow(titleKey: LocalizedStringKey, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(titleKey)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
        }
    }

    private func diagnosticRow(titleKey: LocalizedStringKey, value: LocalizedStringKey) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(titleKey)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview("Session Recording Mock") {
    SessionRecordingPreviewPanel(
        sessionRecording: useSessionRecording(coordinator: .makeMockCoordinator())
    )
    .padding()
}
#endif
