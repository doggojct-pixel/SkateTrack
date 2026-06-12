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
    var currentSpeedKilometersPerHour: Double
    var maxSpeedKilometersPerHour: Double
    var averageSpeedKilometersPerHour: Double
    var distanceKilometers: Double
    var elapsedTime: TimeInterval
    var currentTiltDegrees: Double
    var latestMotionSample: MotionSample?
    var recentRouteCoordinates: [GeoCoordinate]
    var activeFallEvent: FallEvent?
    var errorMessageKey: String?

    static let initial = SessionRecordingState(
        status: .idle,
        selectedSportMode: nil,
        selectedPowerType: .humanPowered,
        selectedEquipmentID: nil,
        currentSpeedKilometersPerHour: 0,
        maxSpeedKilometersPerHour: 0,
        averageSpeedKilometersPerHour: 0,
        distanceKilometers: 0,
        elapsedTime: 0,
        currentTiltDegrees: 0,
        latestMotionSample: nil,
        recentRouteCoordinates: [],
        activeFallEvent: nil,
        errorMessageKey: nil
    )
}

struct SessionRecordingActions {
    let startSession: (SportMode, PowerType, UUID?) async -> Void
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
    #endif

    private let coordinator: SessionRecordingCoordinator
    private var cancellables = Set<AnyCancellable>()

    init(coordinator: SessionRecordingCoordinator = .shared) {
        self.coordinator = coordinator
        #if DEBUG
        self.debugDemoSpeedSessionEnabled = coordinator.debugDataSource == .mock
        #endif
        bindCoordinator()
    }

    var actions: SessionRecordingActions {
        SessionRecordingActions(
            startSession: { [weak self] mode, powerType, equipmentID in
                await self?.startSession(
                    mode: mode,
                    powerType: powerType,
                    equipmentID: equipmentID
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
        equipmentID: UUID?
    ) async {
        updateState {
            $0.selectedSportMode = mode
            $0.selectedPowerType = powerType
            $0.selectedEquipmentID = equipmentID
            $0.recentRouteCoordinates = []
            $0.errorMessageKey = nil
        }

        do {
            try await coordinator.startSession(
                mode: mode,
                powerType: powerType,
                equipmentID: equipmentID
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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey(sessionRecording.state.status.localizationKey))
                .font(.caption.bold())

            Text("\(sessionRecording.state.currentSpeedKilometersPerHour, format: .number.precision(.fractionLength(1)))")
                .font(.caption2)
            Text("\(sessionRecording.state.distanceKilometers, format: .number.precision(.fractionLength(2)))")
                .font(.caption2)
            Text("\(sessionRecording.state.elapsedTime, format: .number.precision(.fractionLength(0)))")
                .font(.caption2)

            if let errorKey = sessionRecording.state.errorMessageKey {
                Text(LocalizedStringKey(errorKey))
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityIdentifier("session-recording-preview-panel")
    }
}

#Preview("Session Recording Mock") {
    SessionRecordingPreviewPanel(
        sessionRecording: useSessionRecording(coordinator: .makeMockCoordinator())
    )
    .padding()
}
#endif
