// [自主區] iOS/Core/Safety/SOSEventDispatcher.swift
// 用途：封裝 Phase 1a SOS 事件建立與未來電話 / 訊息 / 推播通道替換點。
// 委派至：useFallDetection、EmergencyContactStore、Task-015 persistence。

import Combine
import Foundation

final class SOSEventDispatcher {
    static let shared = SOSEventDispatcher()

    private let eventSubject = PassthroughSubject<SOSTriggerEvent, Never>()
    private(set) var dispatchedEvents: [SOSTriggerEvent] = []

    var eventPublisher: AnyPublisher<SOSTriggerEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    @discardableResult
    func dispatch(
        source: SOSTriggerSource,
        fallEvent: FallEvent?,
        locationCoordinate: GeoCoordinate?,
        sportMode: SportMode?
    ) -> SOSTriggerEvent {
        let event = SOSTriggerEvent(
            source: source,
            dispatchStatus: .readyForUserAction,
            relatedFallEvent: fallEvent,
            locationCoordinate: locationCoordinate ?? fallEvent?.locationCoordinate,
            sportMode: sportMode ?? fallEvent?.sportMode
        )

        dispatchedEvents.append(event)
        eventSubject.send(event)
        return event
    }
}
