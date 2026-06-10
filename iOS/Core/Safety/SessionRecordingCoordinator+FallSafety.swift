// [自主區] iOS/Core/Safety/SessionRecordingCoordinator+FallSafety.swift
// 用途：提供 Fall Alert UI 所需的倒數 publisher、取消警示與 SOS 事件觸發動作。
// 委派至：useFallDetection 與 SOSEventDispatcher。

import Combine
import Foundation

extension SessionRecordingCoordinator {
    var fallCountdownPublisher: AnyPublisher<Int?, Never> {
        fallCountdownSubject.eraseToAnyPublisher()
    }

    var sosTriggerEventPublisher: AnyPublisher<SOSTriggerEvent?, Never> {
        sosTriggerEventSubject.eraseToAnyPublisher()
    }

    func cancelActiveFallAlert() {
        fallDetectionEngine.cancelFallAlert()
        activeFallEvent = nil
        fallEventSubject.send(nil)
        fallCountdownSubject.send(nil)
    }

    @discardableResult
    func sendImmediateSOSForActiveFall() -> SOSTriggerEvent {
        let event = dispatchSOS(source: activeFallEvent == nil ? .manualHUD : .fallImmediate, fallEvent: activeFallEvent)
        cancelActiveFallAlert()
        return event
    }

    @discardableResult
    func triggerManualSOS() -> SOSTriggerEvent {
        dispatchSOS(source: .manualHUD, fallEvent: activeFallEvent)
    }


    #if DEBUG
    func simulateFallAlertForDebug() {
        let event = FallEvent(
            timestamp: Date(),
            peakImpactGForce: 6.8,
            locationCoordinate: metricsAccumulator.latestMotionSample?.gpsCoordinate,
            sportMode: selectedSportMode ?? .skateboard(.streetPark)
        )

        activeFallEvent = event
        fallEventSubject.send(event)
        fallCountdownSubject.send(15)
        scheduleDebugFallCountdown(eventID: event.id, secondsRemaining: 14)
    }

    private func scheduleDebugFallCountdown(eventID: UUID, secondsRemaining: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self, self.activeFallEvent?.id == eventID else { return }

            if secondsRemaining <= 0 {
                guard let fallEvent = self.activeFallEvent else { return }
                self.activeFallEvent = nil
                self.fallEventSubject.send(nil)
                self.fallCountdownSubject.send(nil)
                _ = self.dispatchSOS(source: SOSTriggerSource.fallCountdownExpired, fallEvent: fallEvent)
                return
            }

            self.fallCountdownSubject.send(secondsRemaining)
            self.scheduleDebugFallCountdown(eventID: eventID, secondsRemaining: secondsRemaining - 1)
        }
    }
    #endif

    func dispatchSOS(source: SOSTriggerSource, fallEvent: FallEvent?) -> SOSTriggerEvent {
        let event = sosDispatcher.dispatch(
            source: source,
            fallEvent: fallEvent,
            locationCoordinate: metricsAccumulator.latestMotionSample?.gpsCoordinate ?? fallEvent?.locationCoordinate,
            sportMode: selectedSportMode ?? fallEvent?.sportMode
        )
        sosTriggerEventSubject.send(event)
        return event
    }
}
