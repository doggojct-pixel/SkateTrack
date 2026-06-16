// [協作區 — 邊界適配層] iOS/Hooks/useSnowLiveSession.swift
// 用途：向 SwiftUI 暴露 Snow live HUD state；不直接開 sensor、不直接碰 watch data wiring。
// 委派至：SnowLiveSessionCoordinator。

import Combine
import Foundation

@MainActor
final class SnowLiveSessionViewModel: ObservableObject {
    @Published private(set) var state: SnowLiveSessionState = .empty
    @Published private(set) var hudState: SnowLiveHUDState = .waiting(
        SnowWaitingHUDModel(
            titleLocalizationKey: "snow.hud.waiting.title",
            currentSegmentType: .unknown,
            pendingEndElapsedSeconds: nil,
            lastRunVerticalDropMeters: nil,
            lastRunTopSpeedKmh: nil,
            lastRunDurationSeconds: nil
        )
    )

    private let coordinator: SnowLiveSessionCoordinating
    private let config: SnowLiveSessionConfig
    private var cancellables = Set<AnyCancellable>()

    init(
        coordinator: SnowLiveSessionCoordinating = SnowLiveSessionCoordinator(),
        config: SnowLiveSessionConfig = .productionV0
    ) {
        self.coordinator = coordinator
        self.config = config
        bindCoordinator()
    }

    func start(sessionID: UUID) {
        coordinator.start(sessionID: sessionID)
    }

    func pause() {
        coordinator.pause()
    }

    func resume() {
        coordinator.resume()
    }

    func manuallyEndCurrentRun() async {
        await coordinator.manuallyEndCurrentRun()
    }

    func finishSession() async {
        await coordinator.finishSession()
    }

    func reset() {
        coordinator.reset()
    }

    private func bindCoordinator() {
        coordinator.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                self.state = state
                self.hudState = SnowLiveHUDStateMapper.map(
                    snowState: state,
                    recordingState: .initial,
                    config: self.config
                )
            }
            .store(in: &cancellables)
    }
}

@MainActor
func useSnowLiveSession(
    coordinator: SnowLiveSessionCoordinating = SnowLiveSessionCoordinator(),
    config: SnowLiveSessionConfig = .productionV0
) -> SnowLiveSessionViewModel {
    SnowLiveSessionViewModel(coordinator: coordinator, config: config)
}
