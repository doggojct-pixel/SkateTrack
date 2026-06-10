// [協作區 — 邊界適配層] useFallDetection.swift
// 用途：向 SwiftUI Fall Alert UI 暴露 active alert、countdown、取消與 SOS actions。
// 委派至：SessionRecordingCoordinator 與 SOSEventDispatcher。

import Combine
import Foundation

struct FallDetectionAlertState: Equatable {
    var activeFallEvent: FallEvent?
    var countdownSecondsRemaining: Int?
    var latestSOSTriggerEvent: SOSTriggerEvent?

    static let initial = FallDetectionAlertState(
        activeFallEvent: nil,
        countdownSecondsRemaining: nil,
        latestSOSTriggerEvent: nil
    )
}

struct FallDetectionActions {
    let cancelAlert: () -> Void
    let sendSOSNow: () -> Void
    let triggerManualSOS: () -> Void
    let clearLatestSOS: () -> Void
    #if DEBUG
    let simulateFallAlert: () -> Void
    #endif
}

final class FallDetectionViewModel: ObservableObject {
    @Published private(set) var state: FallDetectionAlertState = .initial

    private let coordinator: SessionRecordingCoordinator
    private var cancellables = Set<AnyCancellable>()

    init(coordinator: SessionRecordingCoordinator = .shared) {
        self.coordinator = coordinator
        bindCoordinator()
    }

    var actions: FallDetectionActions {
        #if DEBUG
        return FallDetectionActions(
            cancelAlert: { [weak self] in self?.coordinator.cancelActiveFallAlert() },
            sendSOSNow: { [weak self] in self?.coordinator.sendImmediateSOSForActiveFall() },
            triggerManualSOS: { [weak self] in self?.coordinator.triggerManualSOS() },
            clearLatestSOS: { [weak self] in self?.updateState { $0.latestSOSTriggerEvent = nil } },
            simulateFallAlert: { [weak self] in self?.coordinator.simulateFallAlertForDebug() }
        )
        #else
        return FallDetectionActions(
            cancelAlert: { [weak self] in self?.coordinator.cancelActiveFallAlert() },
            sendSOSNow: { [weak self] in self?.coordinator.sendImmediateSOSForActiveFall() },
            triggerManualSOS: { [weak self] in self?.coordinator.triggerManualSOS() },
            clearLatestSOS: { [weak self] in self?.updateState { $0.latestSOSTriggerEvent = nil } }
        )
        #endif
    }

    private func bindCoordinator() {
        coordinator.activeFallEventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] fallEvent in
                self?.updateState { $0.activeFallEvent = fallEvent }
            }
            .store(in: &cancellables)

        coordinator.fallCountdownPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] seconds in
                self?.updateState { $0.countdownSecondsRemaining = seconds }
            }
            .store(in: &cancellables)

        coordinator.sosTriggerEventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.updateState { $0.latestSOSTriggerEvent = event }
            }
            .store(in: &cancellables)
    }

    private func updateState(_ mutation: (inout FallDetectionAlertState) -> Void) {
        var nextState = state
        mutation(&nextState)
        state = nextState
    }
}

func useFallDetection(coordinator: SessionRecordingCoordinator = .shared) -> FallDetectionViewModel {
    FallDetectionViewModel(coordinator: coordinator)
}
